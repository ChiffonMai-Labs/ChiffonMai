import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:simai_flutter/simai_flutter.dart';

/// 谱面自定义正解音效与自定义 NOTE 纹理的沙箱存储与导入服务。
///
/// 所有导入的文件均拷贝到应用私有文档目录 `chart_play/custom_assets/` 下持久化保存，
/// 避免临时缓存或系统文件选择器 URI 权限过期导致播放、视频导出或重启后失效。
class ChartPlayCustomAssetsService {
  ChartPlayCustomAssetsService._();

  static const int maxAudioFileBytes = 10 * 1024 * 1024;
  static const int maxImageFileBytes = 8 * 1024 * 1024;
  static const int maxZipFileBytes = 32 * 1024 * 1024;

  static const List<String> allowedAudioExtensions = <String>[
    'wav',
    'mp3',
    'ogg',
    'm4a',
    'flac',
    'aac',
  ];

  static const Set<String> _imageExtensions = <String>{
    '.png',
    '.webp',
    '.jpg',
    '.jpeg',
  };

  static Future<Directory> _rootDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(docs.path, 'chart_play', 'custom_assets'));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  static Future<Directory> _sfxDir() async {
    final dir = Directory(p.join((await _rootDir()).path, 'sfx'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<Directory> _notesDir() async {
    final dir = Directory(p.join((await _rootDir()).path, 'notes'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String displayNameForPath(String? filePath) {
    final trimmed = filePath?.trim();
    if (trimmed == null || trimmed.isEmpty) return '';
    return p.basename(trimmed);
  }

  /// 仅当 [filePath] 位于本服务管理的私有目录内时删除，避免误删外部路径。
  static Future<void> deleteManagedFileIfOwned(String? filePath) async {
    final trimmed = filePath?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    try {
      final root = await _rootDir();
      final canonicalRoot = p.normalize(root.absolute.path);
      final canonicalTarget = p.normalize(File(trimmed).absolute.path);
      if (!p.isWithin(canonicalRoot, canonicalTarget)) return;
      final file = File(canonicalTarget);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  static Future<Uint8List?> _readPickedBytes(PlatformFile file) async {
    if (file.path != null && file.path!.trim().isNotEmpty) {
      final f = File(file.path!);
      if (await f.exists()) {
        return f.readAsBytes();
      }
    }
    return file.bytes;
  }

  static Future<String?> _pickAndImportAudio({
    required String filePrefix,
    required String sizeLimitLabel,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedAudioExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.single;
    final ext = p.extension(picked.name).toLowerCase();
    final safeExt = ext.isNotEmpty ? ext : '.wav';
    final bytes = await _readPickedBytes(picked);
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('无法读取所选音频文件内容');
    }
    if (bytes.length > maxAudioFileBytes) {
      throw FormatException('$sizeLimitLabel文件不能超过 10 MB');
    }
    final dir = await _sfxDir();
    final baseStem = p
        .basenameWithoutExtension(picked.name)
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final stem = baseStem.isEmpty ? filePrefix : baseStem;
    final target = File(
      p.join(
        dir.path,
        '${filePrefix}_${stem}_${DateTime.now().millisecondsSinceEpoch}$safeExt',
      ),
    );
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  /// 选择并导入自定义正解音音频，返回持久化本地路径；用户取消返回 null，异常抛出 [FormatException]。
  static Future<String?> pickAndImportHitSound() => _pickAndImportAudio(
        filePrefix: 'hit',
        sizeLimitLabel: '正解音',
      );

  /// 选择并导入指定判定音色的自定义音频，返回持久化本地路径；用户取消返回 null，异常抛出 [FormatException]。
  static Future<String?> pickAndImportJudgementSound(
    SimaiJudgementSoundKind kind,
  ) =>
      _pickAndImportAudio(
        filePrefix: 'judge_${kind.name}',
        sizeLimitLabel: '判定音效',
      );

  /// 为单个 NOTE 槽位选择并导入图片纹理，返回持久化路径；取消返回 null。
  static Future<String?> pickAndImportNoteSlot(String slotKey) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.single;
    final ext = p.extension(picked.name).toLowerCase();
    final safeExt = _imageExtensions.contains(ext) ? ext : '.png';
    final bytes = await _readPickedBytes(picked);
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('无法读取所选图片文件');
    }
    if (bytes.length > maxImageFileBytes) {
      throw const FormatException('单张 NOTE 贴图不能超过 8 MB');
    }
    final dir = await _notesDir();
    final target = File(
      p.join(dir.path, '${slotKey}_${DateTime.now().millisecondsSinceEpoch}$safeExt'),
    );
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  /// 导入 `.zip` 皮肤包并合并到 [current]，支持 `skin.json` 显式映射与标准文件名自动匹配。
  static Future<({SimaiCustomNoteSkin skin, int importedCount})?>
      pickAndImportNoteSkinZip(SimaiCustomNoteSkin current) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['zip'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.single;
    final bytes = await _readPickedBytes(picked);
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('无法读取所选皮肤包文件');
    }
    if (bytes.length > maxZipFileBytes) {
      throw const FormatException('皮肤包体积不能超过 32 MB');
    }

    final archive = ZipDecoder().decodeBytes(bytes);
    final Map<String, String> explicitByFile = <String, String>{};
    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      if (p.basename(entry.name).toLowerCase() == 'skin.json') {
        try {
          final raw = json.decode(utf8.decode(entry.content as List<int>));
          if (raw is Map) {
            raw.forEach((k, v) {
              if (k is String && v is String) {
                final cleanKey = SimaiCustomNoteSkin.matchSlotKeyFromFileName(k);
                final fileName = p.basename(v).toLowerCase();
                if (cleanKey != null && fileName.isNotEmpty) {
                  explicitByFile[fileName] = cleanKey;
                }
              }
            });
          }
        } catch (_) {}
        break;
      }
    }

    final dir = await _notesDir();
    final now = DateTime.now().millisecondsSinceEpoch;
    final Map<String, String> additions = <String, String>{};
    var idx = 0;

    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      final baseName = p.basename(entry.name);
      if (baseName.startsWith('.') || baseName.startsWith('__MACOSX')) continue;
      final ext = p.extension(baseName).toLowerCase();
      if (!_imageExtensions.contains(ext)) continue;

      final slotKey = explicitByFile[baseName.toLowerCase()] ??
          SimaiCustomNoteSkin.matchSlotKeyFromFileName(baseName);
      if (slotKey == null) continue;

      final content = entry.content as List<int>;
      if (content.isEmpty || content.length > maxImageFileBytes) continue;

      final dest = File(p.join(dir.path, '${slotKey}_${now}_${idx++}$ext'));
      await dest.writeAsBytes(content, flush: true);
      additions[slotKey] = dest.path;
    }

    if (additions.isEmpty) {
      throw const FormatException(
        '压缩包内未找到可识别的 NOTE 贴图（如 tap.png / tap_each.png / star.png / slide.png / touch.png）',
      );
    }

    for (final slotKey in additions.keys) {
      final oldPath = current.pathFor(slotKey);
      if (oldPath != null && oldPath != additions[slotKey]) {
        await deleteManagedFileIfOwned(oldPath);
      }
    }
    return (
      skin: current.merge(additions),
      importedCount: additions.length,
    );
  }
}
