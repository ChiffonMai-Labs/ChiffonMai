import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';
import 'History/ChartHistoryStore.dart';

/// 只备份明确归属用户的文件，不遍历音源、PV、网络缓存或安全存储目录。
class UserFileBackupService {
  static Future<Map<String, Directory>> _roots() async {
    final support = await getApplicationSupportDirectory();
    final docs = await getApplicationDocumentsDirectory();
    return {
      'history': Directory('${support.path}/${ChartHistoryStore.dirName}'),
      'archives': Directory('${docs.path}/custom_chart_play/archives'),
      'background': Directory('${docs.path}/backup_background'),
    };
  }

  static Future<Map<String, dynamic>> collect(SharedPreferences prefs) async {
    await ChartHistoryStore.instance.flush();
    final roots = await _roots();
    final files = <String, dynamic>{};
    var bytes = 0;
    Future<void> add(String key, File file) async {
      if (await FileSystemEntity.type(file.path, followLinks: false) !=
          FileSystemEntityType.file) return;
      bytes += await file.length();
      if (bytes > 35 * 1024 * 1024)
        throw StateError('用户文件超过备份容量上限，请先精简自定义谱面归档后重试');
      files[key] = {
        'content': base64Encode(await file.readAsBytes()),
        'originalPath': file.path
      };
    }

    for (final category in ['history', 'archives']) {
      final dir = roots[category]!;
      if (!await dir.exists()) continue;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File ||
            category == 'history' && !entity.path.endsWith('.json')) continue;
        await add('$category/${entity.uri.pathSegments.last}', entity);
      }
    }
    final background = prefs.getString(CacheKeyConstant.customBackgroundPath);
    if (background != null && background.isNotEmpty) {
      final file = File(background);
      await add('background/${file.uri.pathSegments.last}', file);
    }
    return files;
  }

  /// 所有路径与内容都在落盘前校验，备份不能指定任意绝对目标路径。
  static Future<UserFileRestore> prepare(Object? raw,
      {required bool clearFirst}) async {
    if (raw is! Map) throw const FormatException('备份的用户文件格式无效');
    final roots = await _roots();
    final targets = <File, List<int>>{};
    final replacements = <String, String>{};
    var bytes = 0;
    for (final entry in raw.entries) {
      if (entry.key is! String || entry.value is! Map)
        throw const FormatException('用户文件条目无效');
      final parts = (entry.key as String).split('/');
      if (parts.length != 2 ||
          !roots.containsKey(parts[0]) ||
          parts[1].isEmpty ||
          parts[1].contains('..') ||
          parts[1].contains('\\') ||
          parts[1].contains(':') ||
          parts[0] == 'history' && !parts[1].endsWith('.json')) {
        throw const FormatException('用户文件路径无效');
      }
      final value = entry.value as Map;
      if (value['content'] is! String || value['originalPath'] is! String)
        throw const FormatException('用户文件内容无效');
      final content = base64Decode(value['content'] as String);
      bytes += content.length;
      if (bytes > 35 * 1024 * 1024) throw const FormatException('用户文件超过备份容量上限');
      if (parts[0] == 'history') jsonDecode(utf8.decode(content));
      final root = roots[parts[0]]!;
      if (await FileSystemEntity.type(root.path, followLinks: false) ==
          FileSystemEntityType.link)
        throw const FormatException('用户文件目录不能是符号链接');
      final file = File('${root.path}/${parts[1]}');
      if (await FileSystemEntity.type(file.path, followLinks: false) ==
          FileSystemEntityType.link) throw const FormatException('用户文件不能是符号链接');
      targets[file] = content;
      replacements[value['originalPath'] as String] = file.path;
    }
    final removed = <File>[];
    if (clearFirst && await roots['history']!.exists()) {
      final targetPaths = targets.keys.map((file) => file.path).toSet();
      await for (final entity in roots['history']!.list(followLinks: false)) {
        if (entity is File &&
            entity.path.endsWith('.json') &&
            !targetPaths.contains(entity.path)) removed.add(entity);
      }
    }
    return UserFileRestore(targets, removed, replacements);
  }
}

class UserFileRestore {
  UserFileRestore(this._targets, this._removed, this.replacements);
  final Map<File, List<int>> _targets;
  final List<File> _removed;
  final Map<String, String> replacements;
  final Map<File, List<int>?> _previous = {};

  Future<void> apply() async {
    await ChartHistoryStore.instance.invalidateCache();
    for (final file in [..._targets.keys, ..._removed]) {
      _previous[file] = await file.exists() ? await file.readAsBytes() : null;
    }
    for (final entry in _targets.entries) {
      await entry.key.parent.create(recursive: true);
      await entry.key.writeAsBytes(entry.value, flush: true);
    }
    for (final file in _removed) {
      await file.delete();
    }
  }

  Future<void> rollback() async {
    for (final entry in _previous.entries) {
      if (entry.value == null) {
        if (await entry.key.exists()) await entry.key.delete();
      } else {
        await entry.key.writeAsBytes(entry.value!, flush: true);
      }
    }
    await ChartHistoryStore.instance.invalidateCache();
  }

  Map<String, dynamic> rewritePaths(Map<String, dynamic> data) => {
        for (final entry in data.entries)
          entry.key: entry.value is Map &&
                  entry.value['type'] == 'String' &&
                  entry.value['value'] is String
              ? <String, dynamic>{
                  ...Map<String, dynamic>.from(entry.value as Map),
                  'value': _rewrite(entry.value['value'] as String)
                }
              : entry.value,
      };

  String _rewrite(String value) {
    for (final entry in replacements.entries) {
      if (value == entry.key) return entry.value;
      value = value.replaceAll(jsonEncode(entry.key), jsonEncode(entry.value));
    }
    return value;
  }
}
