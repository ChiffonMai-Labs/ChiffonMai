import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:my_first_flutter_app/widgets/NoRipple.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constant/CacheKeyConstant.dart';
import '../entity/DivingFish/Song.dart';
import '../entity/MaimaiHubOcrResult.dart';
import '../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../manager/DivingFishProbeManager.dart';
import '../manager/LuoXue/LuoXueOAuthManager.dart';
import '../service/Best50/DiffBest50Service.dart';
import '../service/SongSearchService.dart';
import '../service/DivingFishScoreUploadService.dart';
import '../service/LuoXueScoreUploadService.dart';
import '../service/MaimaiHubOcrService.dart';
import '../utils/AppTheme.dart';
import '../utils/CoverUtil.dart';
import '../utils/OcrImageCropUtil.dart';
import '../utils/SongFilterUtil.dart';
import '../utils/StringUtil.dart';
import '../utils/SecureCredentialStore.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../widgets/AppToast.dart';
import '../widgets/QrQuickFillButtons.dart';

/// 结算画面识别页（拍摄机台结算画面 → 裁剪 → 识别 → 显示结构化成绩）
///
/// 输入不是手机截图，而是**对着机台结算页面拍的照片**，所以文案一律用「拍摄」
/// 而不是「截图」。
///
/// 流程：
///   1. 拍照 / 从相册选图
///   2. 手动框选裁剪
///   3. 调 maimai Score Hub `POST /api/v1/me/ocr/recognize`（**需先登录 maimai Score Hub**）
///   4. 渲染识别出的曲名候选 / 达成率 / DX分 / 难度 / FC / FS
///
/// 识别由 maimai Score Hub 的专用模型完成（曲绘 ArcFace + 标题分类双路匹配），
/// 直接产出结构化成绩，不需要再自己解析文本。
///
/// 注：自家后端 `/api/ocr/score`（百度/腾讯通用 OCR）**已废弃**，本页不再走那条路。
class ScoreOcrPage extends StatefulWidget {
  const ScoreOcrPage({super.key});

  @override
  State<ScoreOcrPage> createState() => _ScoreOcrPageState();
}

/// 玩家对某一条识别结果的修正。
///
/// 识别不可能 100% 准确，与其让错的数字留在界面上，不如每项都允许改。
/// 只存「被改过」的字段，null 表示沿用 OCR 的原始值。
class _OcrItemEdit {
  /// 玩家从曲库里选的歌（覆盖 OCR 的曲名匹配）
  Song? song;

  /// 玩家手填的曲名（曲库里没有这首歌时用）
  String? manualTitle;

  String? difficulty;
  String? fc;
  String? fs;

  double? achievement;
  int? dxScore;

  /// 展示用曲名：优先级 手填曲名 > 玩家选的歌 > OCR 结果
  String? titleOf(String? ocrTitle) =>
      manualTitle ?? song?.basicInfo.title ?? ocrTitle;
}

/// 选歌结果：要么是曲库里的一首歌，要么是一个手填曲名（曲库里没有）
class _SongChoice {
  final Song? song;
  final String? manualTitle;

  const _SongChoice({this.song, this.manualTitle});
}

/// 带实时上限校验的数字输入框。
///
/// 自己持有 controller 才能在「输入非法」时给出持续的红字提示，
/// 并且**不把非法值写回**——否则用户输到一半（比如想打 1005）就会把
/// 中间态当成最终值传给上层。
class _ValidatedNumberField extends StatefulWidget {
  final String label;
  final String hint;
  final String? initial;
  final double? max;
  final String? maxHint;
  final void Function(double? value) onSubmit;

  const _ValidatedNumberField({
    required this.label,
    required this.hint,
    required this.initial,
    required this.onSubmit,
    this.max,
    this.maxHint,
  });

  @override
  State<_ValidatedNumberField> createState() => _ValidatedNumberFieldState();
}

class _ValidatedNumberFieldState extends State<_ValidatedNumberField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial ?? '');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      setState(() => _error = null);
      widget.onSubmit(null); // 空 = 恢复为识别值
      return;
    }

    final v = double.tryParse(t);
    if (v == null) {
      setState(() => _error = '请输入数字');
      return; // 不写回，保留上一次的合法值
    }
    if (v < 0) {
      setState(() => _error = '不能为负数');
      return;
    }
    final max = widget.max;
    if (max != null && v > max) {
      setState(() => _error = '不得超过 ${_f(max)}');
      return;
    }

    setState(() => _error = null);
    widget.onSubmit(v);
  }

  static String _f(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        // 有错就只显示错误；没错时显示上限提示。两个都给会被系统覆盖成红框
        helperText: widget.maxHint,
        helperStyle: TextStyle(
          fontSize: 11,
          color: scheme.onSurfaceVariant,
        ),
        errorText: _error,
        errorStyle: const TextStyle(fontSize: 11),
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: _handleChanged,
    );
  }
}

class _ScoreOcrPageState extends State<ScoreOcrPage> {
  final ImagePicker _picker = ImagePicker();
  final MaimaiHubOcrService _service = MaimaiHubOcrService.instance;

  String? _photoPath;
  bool _isRecognizing = false;
  MaimaiHubOcrBatch? _result;
  String? _error;

  /// maimai Score Hub 登录态；null 表示还没查完
  bool? _loggedIn;

  /// 识别结果里每张图匹配到的本地曲库数据，key 是 [MaimaiHubOcrItem.index]。
  /// 匹配不到就是没有这一项（曲库未刷新 / OCR 出的曲名跟曲库对不上）。
  final Map<int, Song> _matchedSongs = {};

  /// 本地曲库是不是空的。
  ///
  /// 之前 [_resolveMatchedSongs] 在曲库为空时直接 return，结果是**所有**卡片
  /// 都定位不到歌、两个同步按钮全部变灰，而界面上一句解释都没有；用户只会
  /// 以为是登录出了问题。
  /// 记下这个状态，是为了能明确区分「曲库没下载」和「这一首没匹配上」。
  bool _songLibraryEmpty = false;

  /// 玩家对每一条识别结果的修正，key 同上。没有条目 = 没改过。
  final Map<int, _OcrItemEdit> _edits = {};

  /// 正在同步到水鱼的那一条（避免重复点击）
  int? _uploadingIndex;

  /// 正在同步到落雪的那一条（与水鱼的 loading 分开跟踪，
  /// 这样一条在同步水鱼时，另一条仍可显示落雪的进度）
  int? _uploadingLuoXueIndex;

  /// 该项最终生效的歌曲：玩家改过就用玩家的，否则用 OCR 匹配结果
  Song? _songOf(MaimaiHubOcrItem item) =>
      _edits[item.index]?.song ?? _matchedSongs[item.index];

  /// 玩家是否可以改这一条的难度。
  /// 只有定位到具体歌曲、并且知道它有哪些难度时，才能给出合法索引。
  bool _canPickDifficulty(MaimaiHubOcrItem item) {
    final n = _chartCountOf(item);
    return n != null && n > 0;
  }

  /// 该歌曲实际有几个难度谱面（cids 长度就是权威来源）。
  /// 返回 null 表示当前定位不到歌曲，此时无法约束难度索引。
  int? _chartCountOf(MaimaiHubOcrItem item) {
    final song = _songOf(item);
    if (song == null) return null;
    final n = song.cids.length;
    return n == 0 ? null : n;
  }

  /// 难度名 → 索引
  static int? _difficultyIndexOf(String? difficulty) {
    return ChartDifficulty.standardIndexOf(difficulty);
  }

  /// 索引 → 玩家看到的难度名
  static String _difficultyNameOf(int index) => ChartDifficulty.labelOf(index, fallback: '难度 $index');

  /// 该歌曲在 [index] 这个难度上的等级（没有则为 null）
  static String? _levelAtIndex(Song song, int index) {
    if (index < 0 || index >= song.level.length) return null;
    final lv = song.level[index].trim();
    return lv.isEmpty ? null : lv;
  }

  /// 该歌曲在 [index] 这个难度上的定数（没有或为 0 则为 null）
  static double? _dsAtIndex(Song song, int index) {
    if (index < 0 || index >= song.ds.length) return null;
    final ds = song.ds[index];
    return ds <= 0 ? null : ds;
  }

  /// 当前生效的难度索引；定位不到难度时返回 null
  int? _difficultyIndexEffective(MaimaiHubOcrItem item) =>
      _difficultyIndexOf(_difficultyOf(item));

  /// 换了歌曲之后，把难度约束到新歌真实存在的范围内。
  ///
  /// 必须做这一步：水鱼的更新接口按 `cids[level_index]` 取谱面，
  /// 传一个该歌曲不存在的索引会被服务端丢进 `continue` —— 请求返回成功，
  /// 但成绩没写进去。与其静默失败，不如在选歌时就纠正。
  void _applySongChange(MaimaiHubOcrItem item, _SongChoice picked) {
    final edit = _edits.putIfAbsent(item.index, () => _OcrItemEdit());
    edit.song = picked.song;
    edit.manualTitle = picked.manualTitle;

    final song = picked.song;
    if (song == null) {
      edit.difficulty = null;
      return;
    }
    final count = song.cids.length;
    if (count <= 0) {
      edit.difficulty = null;
      return;
    }
    final current = _difficultyIndexOf(edit.difficulty);
    if (current == null || current >= count) {
      // 原难度在新歌上没有 → 取最高难度（第 count-1 个）作为兜底
      edit.difficulty = _difficultyNameOf(count - 1).toLowerCase();
    }
  }

  String? _difficultyOf(MaimaiHubOcrItem item) =>
      _edits[item.index]?.difficulty ?? item.difficulty;

  String? _fcOf(MaimaiHubOcrItem item) => _edits[item.index]?.fc ?? item.fc;

  /// 同步标记统一转成**水鱼的值域**（fs / fsp / fsd / fsdp / sync）。
  ///
  /// OCR 走的是 maimai Score Hub，它的 `fs` 取值是 fdx / fdxp；水鱼的更新接口
  /// 只认 fsd / fsdp（见 prober 源码 `std_fs`，它内部也做了 fdx→fsd 的映射）。
  /// 这里统一成水鱼的写法，显示交给 [StringUtil.formatFS]（fsd→FDX、fsdp→FDX+）。
  String? _fsOf(MaimaiHubOcrItem item) {
    final raw = _edits[item.index]?.fs ?? item.fs;
    switch (raw) {
      case 'fdx':
        return 'fsd';
      case 'fdxp':
        return 'fsdp';
      default:
        return raw;
    }
  }

  double? _achievementOf(MaimaiHubOcrItem item) =>
      _edits[item.index]?.achievement ?? item.achievement;

  int? _dxScoreOf(MaimaiHubOcrItem item) =>
      _edits[item.index]?.dxScore ?? item.dxScore;

  // ========== 取值上限（用于输入实时校验）==========

  /// 达成率上限。
  ///
  /// 普通曲上限 101%（100.5% 之后按 0.5% 进位，理论最高到 101）；
  /// 宴会场（song_id ≥ 100000）在服务端是 `101 * 难度数`——宴谱内部有多张子谱，
  /// 达成率是它们相加的结果，所以上限随难度数放大。
  /// 依据水鱼查分器源码 `max_achievements()`。
  double? _maxAchievementOf(MaimaiHubOcrItem item) {
    final song = _songOf(item);
    if (song == null) return null;
    final id = int.tryParse(song.id);
    if (id == null) return 101;
    if (id < 100000) return 101;
    final count = song.cids.length;
    return count == 0 ? 101 : 101.0 * count;
  }

  /// DX 分数上限 = 该谱面音符总数 × 3。
  /// 与全项目其余页面（Best50 / 歌曲详情 / 排行榜）的算法保持一致。
  int? _maxDxScoreOf(MaimaiHubOcrItem item) {
    final song = _songOf(item);
    final idx = _difficultyIndexEffective(item);
    if (song == null || idx == null) return null;
    if (idx < 0 || idx >= song.charts.length) return null;
    final notes = song.charts[idx].notes;
    if (notes.isEmpty) return null;
    final total = notes.fold<int>(0, (sum, n) => sum + n);
    return total == 0 ? null : total * 3;
  }

  // ========== 同步到水鱼 ==========

  /// 该条是否具备同步条件：定位到歌曲、有合法难度、有达成率
  bool _canSync(MaimaiHubOcrItem item) => _syncBlockReason(item) == null;

  /// 这一条**为什么**不能同步；能同步时返回 null。
  ///
  /// 存在的意义是「别让按钮无缘无故变灰」。之前这两个按钮的可用性只体现在
  /// 变灰上，用户点不动按钮，
  /// 完全不知道卡在哪一步 —— 实际原因在 OCR 数据这一侧，与登录状态无关。
  /// 现在把原因直接写在按钮下面。
  ///
  /// 注意：这些原因**全部**与登录状态无关，账号问题在点下去之后才由
  /// [_syncToDivingFish] / [_syncToLuoXue] 提示。
  String? _syncBlockReason(MaimaiHubOcrItem item) {
    if (_songOf(item) == null) {
      // 曲库为空时这条是通杀所有卡片的，单独给一句能直接照做的提示
      return _songLibraryEmpty
          ? '本地曲库为空，无法定位曲目。请先到首页刷新曲库'
          : '没匹配到曲目，点「编辑此项」手动指定';
    }
    final idx = _difficultyIndexEffective(item);
    if (idx == null) {
      return '难度识别不出来（宴会场谱面不支持同步）';
    }
    final count = _chartCountOf(item);
    if (count == null) {
      return '曲库里这首歌没有谱面信息';
    }
    if (idx >= count) {
      return '这首歌没有第 ${idx + 1} 个难度（只有 $count 个谱面）';
    }
    if (_achievementOf(item) == null) {
      return '缺少达成率，点「编辑此项」补上';
    }
    return null;
  }

  Future<void> _syncToDivingFish(MaimaiHubOcrItem item) async {
    if (_uploadingIndex != null) return;

    final song = _songOf(item);
    final idx = _difficultyIndexEffective(item);
    final achievement = _achievementOf(item);
    if (song == null || idx == null || achievement == null) return;

    final token =
        await DivingFishProbeManager().getCachedDivingFishImportToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      AppToast.show('还没有水鱼 Import-Token，请先到「登录水鱼」完成登录');
      return;
    }

    setState(() => _uploadingIndex = item.index);
    try {
      final result = await DivingFishScoreUploadService().uploadRecord(
        importToken: token,
        title: song.basicInfo.title,
        type: song.type,
        levelIndex: idx,
        achievement: achievement,
        fc: _fcOf(item),
        fs: _fsOf(item),
        dxScore: _dxScoreOf(item),
      );
      if (!mounted) return;
      AppToast.show(result.isNew
            ? '已新增到水鱼：${song.basicInfo.title}'
            : '已更新水鱼成绩：${song.basicInfo.title}');
    } on ScoreUploadException catch (e) {
      if (mounted) AppToast.show(e.message);
    } catch (e) {
      if (mounted) AppToast.show('同步失败：$e');
    } finally {
      if (mounted) setState(() => _uploadingIndex = null);
    }
  }

  /// 同步到落雪咖啡屋。
  ///
  /// 与水鱼那条路最大的不同：落雪要**数字曲目 id**，而水鱼的 id 体系跟落雪
  /// 不一致（见 [LuoXueScoreUploadService.toLxnsSongId]）。这里从本地曲库
  /// 的 `Song.id` 解析出 int 再交给 service 转换；解析不出来就说明这条
  /// 定位不到具体曲目，直接拒绝而不是硬传。
  ///
  /// 认证由 service 内部决定：OAuth Bearer 优先，个人 API 密钥回退。本页面
  /// 只在「两条都拿不到」时提示去账号管理填写。
  Future<void> _syncToLuoXue(MaimaiHubOcrItem item) async {
    if (_uploadingLuoXueIndex != null) return;

    final song = _songOf(item);
    final idx = _difficultyIndexEffective(item);
    final achievement = _achievementOf(item);
    if (song == null || idx == null || achievement == null) return;

    final songId = int.tryParse(song.id);
    if (songId == null) {
      AppToast.show('无法解析曲目 ID，不能同步到落雪');
      return;
    }

    // OAuth 和本地密钥都没有时传不上去，点同步时才检查。
    final hasOAuth = await LuoXueOAuthManager().getAccessToken() != null;
    final localKey = await SecureCredentialStore.read(
        CacheKeyConstant.probeLxnsImportToken);
    if (!mounted) return;
    if (!hasOAuth && (localKey == null || localKey.isEmpty)) {
      AppToast.show('还没有落雪个人 API 密钥，请先到「账号管理」填写');
      return;
    }

    setState(() => _uploadingLuoXueIndex = item.index);
    try {
      final result = await LuoXueScoreUploadService().uploadRecord(
        divingFishSongId: songId,
        divingFishType: song.type,
        levelIndex: idx,
        achievement: achievement,
        fc: _fcOf(item),
        fs: _fsOf(item),
        dxScore: _dxScoreOf(item),
      );
      if (!mounted) return;
      AppToast.show(_composeLuoXueToast(song.basicInfo.title, result));
    } on LuoXueUploadException catch (e) {
      if (mounted) AppToast.show(e.message);
    } catch (e) {
      if (mounted) AppToast.show('同步失败：$e');
    } finally {
      if (mounted) setState(() => _uploadingLuoXueIndex = null);
    }
  }

  /// 把落雪的 `old → new` 对比拼成一条人话的 Toast。
  ///
  /// 服务端的约定：每个字段值是 `{old?, new?}`，**有变化才出现**。所以
  /// - `oldAch != null && newAch != null && oldAch != newAch` → 改了
  /// - `oldAch == null && newAch != null` → 新增（之前没成绩）
  /// - 两个都 null → 服务端没回这个字段（异常路径，已在 service 拦下）
  String _composeLuoXueToast(String title, LuoXueUploadResult r) {
    final lines = <String>[];
    if (r.changed) {
      lines.add('已更新到落雪：$title');
    } else {
      lines.add('已同步到落雪（无变化）：$title');
    }
    if (r.oldAchievement != null && r.newAchievement != null) {
      lines.add(
          '达成率 ${_formatAchievement(r.oldAchievement!)}% → ${_formatAchievement(r.newAchievement!)}%');
    } else if (r.newAchievement != null) {
      lines.add('达成率 ${_formatAchievement(r.newAchievement!)}%');
    }
    if (r.oldDxScore != null && r.newDxScore != null) {
      lines.add('DX分数 ${r.oldDxScore} → ${r.newDxScore}');
    } else if (r.newDxScore != null) {
      lines.add('DX分数 ${r.newDxScore}');
    }
    return lines.join('\n');
  }

  /// 达成率显示精度。落雪那边是 4 位小数（`100.7506`），项目其它处一般取
  /// 3 位，跟着一致就行；100.0 这种整数没小数尾巴看着也别扭。
  static String _formatAchievement(double v) {
    final s = v.toStringAsFixed(3);
    return s.endsWith('.000') ? v.toStringAsFixed(0) : s;
  }

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final ok = await _service.isAvailable();
    if (mounted) setState(() => _loggedIn = ok);
  }

  // ========== 选图 ==========

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择图片来源',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, size: 28),
              title: const Text('拍照'),
              subtitle: const Text('对着机台结算页面拍一张'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, size: 28),
              title: const Text('从相册选择'),
              subtitle: const Text('选取已经拍好的结算画面'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          AppToast.show('需要相机权限');
          await openAppSettings();
        }
        return;
      }
    }
    try {
      final photo = await _picker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 2560,
        maxHeight: 2560,
      );
      if (photo != null && mounted) {
        final cropped = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => _OcrImageCropPage(imagePath: photo.path),
          ),
        );
        if (!mounted) return;
        if (cropped != null) {
          setState(() {
            _photoPath = cropped;
            _result = null;
            _error = null;
          });
        } else {
          // 用户取消裁剪，回退到原图
          setState(() {
            _photoPath = photo.path;
            _result = null;
            _error = null;
          });
        }
      }
    } catch (e) {
      if (mounted) AppToast.show('选取图片失败: $e');
    }
  }

  // ========== OCR ==========

  Future<void> _recognize() async {
    final p = _photoPath;
    if (p == null) return;
    setState(() {
      _isRecognizing = true;
      _error = null;
      _result = null;
      _matchedSongs.clear();
      _edits.clear();
    });
    try {
      final result = await _service.recognize([File(p)]);
      if (!mounted) return;
      setState(() {
        _result = result;
        _isRecognizing = false;
        _loggedIn = true;
      });
      // 用本地曲库补全曲绘 / 版本 / 流派 / 定数。识别本身不依赖它，
      // 所以单独 await，失败也不影响成绩展示。
      await _resolveMatchedSongs(result);
      if (!mounted) return;
      if (!result.hasAnySuccess) {
        AppToast.show('没有识别出成绩，可裁剪得更贴近结算区域后重试');
      }
    } on MaimaiHubOcrException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isRecognizing = false;
        // 401 会被翻译成「登录状态已失效」，顺手刷新登录态提示
        if (e.message.contains('登录')) _loggedIn = false;
      });
      AppToast.show(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isRecognizing = false;
      });
      AppToast.show('识别出错: $e');
    }
  }

  /// 把识别出的曲名映射到本地曲库的 [Song]，用于补全曲绘 / 版本 / 流派 / 定数。
  ///
  /// 匹配规则（与全项目其他地方「按歌名找歌」的做法一致，不另造一套）：
  ///   1. 严格同名（含 DX / 标准区分）
  ///   2. 大小写无关的同名
  ///   3. 曲名完全相同但有多个版本时，优先取 DX 版（结算画面里 DX 谱更常见）
  ///
  /// 曲库没有的一律跳过——OCR 出来的曲名可能是活动新曲或拼写差异，
  /// 这时宁可不显示，也不要硬塞一个错的曲绘。
  Future<void> _resolveMatchedSongs(MaimaiHubOcrBatch batch) async {
    final songs = await MaimaiMusicDataManager().getCachedSongs();
    if (!mounted) return;

    // 曲库拿不到就**记下来并告诉用户**，不要静默返回 —— 静默的话所有卡片的
    // 同步按钮会一起变灰，看起来像是登录失效。
    if (songs == null || songs.isEmpty) {
      setState(() {
        _songLibraryEmpty = true;
        _matchedSongs.clear();
      });
      return;
    }

    final matched = <int, Song>{};
    for (final item in batch.results) {
      final best = item.bestCandidate;
      if (best == null) continue;
      final song = _findSong(songs, best.title, item.isDx);
      if (song != null) matched[item.index] = song;
    }

    // 曲绘可能走网络兜底，提前预热，避免滚动时闪一下
    for (final song in matched.values) {
      unawaited(CoverUtil.resolveCoverProvider(song.id)
          .then((_) {}, onError: (_) {}));
    }

    if (!mounted) return;
    setState(() {
      _songLibraryEmpty = false;
      _matchedSongs
        ..clear()
        ..addAll(matched);
    });
  }

  static Song? _findSong(List<Song> songs, String title, bool? isDx) {
    final target = title.trim();
    if (target.isEmpty) return null;

    final exact = <Song>[];
    final loose = <Song>[];
    final lowerTarget = target.toLowerCase();
    for (final s in songs) {
      if (s.basicInfo.title == target) {
        exact.add(s);
      } else if (s.basicInfo.title.toLowerCase() == lowerTarget) {
        loose.add(s);
      }
    }
    final pool = exact.isNotEmpty ? exact : loose;
    if (pool.isEmpty) return null;
    if (pool.length == 1) return pool.first;

    // 同名多版本：按 OCR 给的 DX 标识挑，没有标识就优先 DX
    if (isDx != null) {
      for (final s in pool) {
        if ((s.type.toUpperCase() == 'DX') == isDx) return s;
      }
    }
    for (final s in pool) {
      if (s.type.toUpperCase() == 'DX') return s;
    }
    return pool.first;
  }

  void _reset() => setState(() {
        _photoPath = null;
        _result = null;
        _error = null;
        _songLibraryEmpty = false;
        _matchedSongs.clear();
        _edits.clear();
      });

  // ========== 结果修正 ==========

  static const List<String> _fcOptions = ['fc', 'fcp', 'ap', 'app'];

  /// 同步标记的**水鱼值域**（见 prober 源码 `std_fs`）：
  /// fs / fsp / fsd / fsdp / sync，外加空字符串表示无。
  /// 显示交给 StringUtil.formatFS（fsd→FDX、fsdp→FDX+、sync→SC）。
  static const List<String> _fsOptions = ['fs', 'fsp', 'fsd', 'fsdp', 'sync'];

  /// 空选项：选中表示「清空这一项」
  static const String _emptyOption = '';

  Future<void> _showEditSheet(MaimaiHubOcrItem item) async {
    final scheme = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          void apply(void Function(_OcrItemEdit e) change) {
            setSheetState(() =>
                change(_edits.putIfAbsent(item.index, () => _OcrItemEdit())));
            if (mounted) setState(() {});
          }

          /// 选歌要顺带纠正难度，统一走 _applySongChange
          void applySong(_SongChoice picked) =>
              apply((e) => _applySongChange(item, picked));

          final edit = _edits[item.index];
          final best = item.bestCandidate;
          final diffIndex = _difficultyIndexEffective(item);
          final chartCount = _chartCountOf(item);
          final effectiveTitle =
              edit?.titleOf(best?.title) ?? best?.title ?? '未识别出曲名';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('修正识别结果',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface)),
                  const SizedBox(height: 4),
                  Text('识别不可能百分百准确，这里改过的值会直接替换卡片上的显示',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 16),

                  // ── 歌曲：与自定义 Best50 一致的带曲绘输入框 ──
                  _sheetSongField(
                    cover: _buildSongCover(item),
                    value: effectiveTitle,
                    onTap: () async {
                      final picked = await _showSongPicker(item);
                      if (picked == null) return;
                      applySong(picked);
                    },
                    onClear: edit?.song != null || edit?.manualTitle != null
                        ? () => apply((e) {
                              e.song = null;
                              e.manualTitle = null;
                            })
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // ── 难度：与自定义 Best50 一致，默认展开并直接列出真实难度 ──
                  Text('难度',
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  if (!_canPickDifficulty(item))
                    Text(
                      '先选定一首歌曲，才能列出它实际有的难度',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warningOrange(
                              Theme.of(context).brightness)),
                    )
                  else
                    Builder(builder: (context) {
                      // 绑定成非空局部变量，Dart 才能把它提升为非空类型
                      final song = _songOf(item)!;
                      final count = chartCount!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              for (var i = 0; i < count; i++)
                                NoRipple(
                                  child: ChoiceChip(
                                    label: Text(_difficultyNameOf(i)),
                                    selected: diffIndex == i,
                                    // 带出等级/定数，方便确认选对了没
                                    tooltip: [
                                      _levelAtIndex(song, i),
                                      _dsAtIndex(song, i) == null
                                          ? null
                                          : '定数 ${_dsAtIndex(song, i)!.toStringAsFixed(1)}',
                                    ].whereType<String>().join(' · '),
                                    onSelected: (_) => apply((e) => e.difficulty =
                                        _difficultyNameOf(i).toLowerCase()),
                                  ),
                                ),
                            ],
                          ),
                          // 当前选中难度的标级 / 定数
                          if (diffIndex != null &&
                              diffIndex >= 0 &&
                              diffIndex < count)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${_difficultyNameOf(diffIndex)}'
                                '${_levelAtIndex(song, diffIndex) == null ? '' : ' · ${_levelAtIndex(song, diffIndex)}'}'
                                '${_dsAtIndex(song, diffIndex) == null ? '' : ' · 定数 ${_dsAtIndex(song, diffIndex)!.toStringAsFixed(1)}'}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant),
                              ),
                            ),
                        ],
                      );
                    }),
                  const SizedBox(height: 4),

                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _sheetNumberField(
                            label: '达成率 (%)',
                            hint: item.achievement?.toStringAsFixed(4) ?? '—',
                            initial: edit?.achievement?.toString(),
                            max: _maxAchievementOf(item),
                            maxHint: _maxAchievementOf(item) == null
                                ? null
                                : '上限 ${_formatNumber(_maxAchievementOf(item)!)}%',
                            onSubmit: (v) => apply((e) => e.achievement = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _sheetNumberField(
                            label: 'DX 分数',
                            hint: item.dxScore?.toString() ?? '—',
                            initial: edit?.dxScore?.toString(),
                            max: _maxDxScoreOf(item)?.toDouble(),
                            maxHint: _maxDxScoreOf(item) == null
                                ? null
                                : '上限 ${_maxDxScoreOf(item)}',
                            onSubmit: (v) =>
                                apply((e) => e.dxScore = v?.round()),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // RA 实时预览（定位到歌曲+难度、且已填达成率时显示）
                  Builder(builder: (context) {
                    final song = _songOf(item);
                    final idx = _difficultyIndexEffective(item);
                    final ach = _achievementOf(item);
                    final ds = (song != null && idx != null)
                        ? _dsAtIndex(song, idx)
                        : null;
                    if (ds == null || ach == null) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'RA：${DiffBest50Service().calculateSingleRating(ds, ach)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 12),
                  _sheetChoiceRow(
                    label: '连击',
                    options: _fcOptions,
                    current: _fcOf(item),
                    labelOf: (v) => StringUtil.formatFC(v),
                    onPick: (v) => apply((e) => e.fc = v),
                    onClear: edit?.fc != null
                        ? () => apply((e) => e.fc = null)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _sheetChoiceRow(
                    label: '同步',
                    options: _fsOptions,
                    current: _fsOf(item),
                    // 仅此处把 sync 显示成 SYNC（formatFS 的通用显示仍是 SC）
                    labelOf: (v) =>
                        v == 'sync' ? 'SYNC' : StringUtil.formatFS(v),
                    onPick: (v) => apply((e) => e.fs = v),
                    onClear: edit?.fs != null
                        ? () => apply((e) => e.fs = null)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '「空」表示不设置该标记。同步标记会按水鱼的值域提交（FS / FS+ / FDX / FDX+ / SYNC）。',
                    style:
                        TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.restart_alt, size: 18),
                      label: const Text('恢复为识别结果'),
                      onPressed: (edit == null)
                          ? null
                          : () {
                              setSheetState(() => _edits.remove(item.index));
                              if (mounted) setState(() {});
                            },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('完成'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 歌曲字段左侧的曲绘；未定位到歌曲时显示占位图标。
  Widget _buildSongCover(MaimaiHubOcrItem item) {
    final scheme = Theme.of(context).colorScheme;
    final song = _songOf(item);
    if (song == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Icon(Icons.music_note, size: 22, color: scheme.onSurfaceVariant),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: CoverUtil.buildCoverWidget(song.id, 40),
    );
  }

  /// 歌曲输入框：与自定义 Best50 一致——左侧曲绘 + 「歌曲」小标签 + 曲名 + 右侧箭头。
  Widget _sheetSongField({
    required Widget cover,
    required String value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(4.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            cover,
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('歌曲',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, color: scheme.onSurface),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                icon:
                    Icon(Icons.close, size: 16, color: scheme.onSurfaceVariant),
                tooltip: '恢复为识别结果',
                onPressed: onClear,
                visualDensity: VisualDensity.compact,
              ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  /// 数字输入字段：实时校验上限，超限时红字报错并且**不写入**。
  ///
  /// 留空表示「恢复为识别值」。上限为 null 时不做校验（定位不到歌曲/难度）。
  Widget _sheetNumberField({
    required String label,
    required String hint,
    required String? initial,
    required void Function(double? value) onSubmit,
    double? max,
    String? maxHint,
  }) {
    return _ValidatedNumberField(
      label: label,
      hint: hint,
      initial: initial,
      max: max,
      maxHint: maxHint,
      onSubmit: onSubmit,
    );
  }

  /// 把上限数字格式化得干净些：整数不带小数点，否则保留 1 位
  static String _formatNumber(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  /// 一组互斥的标记按钮（FC / FS）
  Widget _sheetChoiceRow({
    required String label,
    required List<String> options,
    required String? current,
    required String Function(String) labelOf,
    required void Function(String) onPick,
    VoidCallback? onClear,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: TextStyle(fontSize: 14, color: scheme.onSurface)),
            const Spacer(),
            if (onClear != null)
              TextButton(
                onPressed: onClear,
                child: const Text('清除', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            // 空选项：选中表示这一项为空（不设置连击/同步标记）
            NoRipple(
              child: ChoiceChip(
                label: const Text('空'),
                selected: current == null || current == _emptyOption,
                onSelected: (_) => onPick(_emptyOption),
              ),
            ),
            for (final o in options)
              NoRipple(
                child: ChoiceChip(
                  label: Text(labelOf(o)),
                  selected: current == o,
                  onSelected: (_) => onPick(o),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// 选歌：先给 OCR 的候选，再给本地曲库全量（带搜索）。
  ///
  /// 搜索框逻辑与自定义 Best50 选曲器一致：`SongSearchService.searchSongs`
  /// （歌名/ID/曲师/谱师/流派/版本/别名/BPM），500ms 防抖 + 搜索中指示。
  Future<_SongChoice?> _showSongPicker(MaimaiHubOcrItem item) async {
    final songs = await MaimaiMusicDataManager().getCachedSongs() ?? [];
    if (!mounted) return null;

    final candidates = item.candidates
        .map((c) => c.title)
        .where((t) => t.trim().isNotEmpty)
        .toList();

    var query = '';
    var results = <Song>[];
    var searching = false;
    Timer? debounce;

    try {
      return await showModalBottomSheet<_SongChoice>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            final brightness = Theme.of(ctx).brightness;
            final scheme = Theme.of(ctx).colorScheme;
            final q = query.trim();
            final filtered = q.isEmpty ? songs : results;

            Future<void> runSearch(String value) async {
              final r = await SongSearchService.searchSongs(value);
              if (!ctx.mounted || value != query) return;
              setSheetState(() {
                results = r;
                searching = false;
              });
            }

            return SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.82,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: TextField(
                      autofocus: false,
                      decoration: const InputDecoration(
                        hintText: '歌名/BPM/谱师/曲师/别名/歌曲ID/...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        debounce?.cancel();
                        setSheetState(() {
                          query = v;
                          searching = v.trim().isNotEmpty;
                          if (v.trim().isEmpty) results = [];
                        });
                        if (v.trim().isEmpty) return;
                        debounce = Timer(
                          const Duration(milliseconds: 500),
                          () => runSearch(v),
                        );
                      },
                    ),
                  ),
                  if (candidates.isNotEmpty)
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final t in candidates)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(t),
                                avatar:
                                    const Icon(Icons.auto_awesome, size: 16),
                                onPressed: () {
                                  final m = _findSong(songs, t, item.isDx);
                                  Navigator.pop(
                                    ctx,
                                    _SongChoice(
                                      song: m,
                                      // 曲库里没有这个曲名时退化成手填曲名
                                      manualTitle: m == null ? t : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  const Divider(height: 1),
                  Expanded(
                    child: searching
                        ? const Center(child: CircularProgressIndicator())
                        : filtered.isEmpty
                            ? Center(
                                child: Text(
                                  q.isEmpty ? '暂无歌曲数据' : '未找到匹配的歌曲',
                                  style:
                                      TextStyle(color: scheme.onSurfaceVariant),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (_, i) => _buildPickerRow(
                                    ctx, filtered[i], brightness),
                              ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } finally {
      debounce?.cancel();
    }
  }

  /// 选曲结果行：曲目类型（ST/DX/UTAGE）放在歌名前，颜色/字号与其它页面一致。
  Widget _buildPickerRow(BuildContext ctx, Song song, Brightness brightness) {
    final bool isUtage = song.id.length == 6;
    final String typeLabel =
        isUtage ? ChartDifficulty.utageLabel : (song.type == 'SD' ? 'ST' : 'DX');
    final Color typeColor = isUtage
        ? const Color(0xFFFF6B8B)
        : (song.type == 'SD'
            ? AppColors.linkBlue(brightness)
            : AppColors.warningOrange(brightness));
    const double nameFontSize = 16.0;

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CoverUtil.buildCoverWidget(song.id, 44),
      ),
      title: Row(
        children: [
          Text(
            typeLabel,
            style: TextStyle(
              fontSize: nameFontSize,
              fontWeight: FontWeight.bold,
              color: typeColor,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              song.basicInfo.title,
              style: const TextStyle(fontSize: nameFontSize),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text(
        // extra 曲目（宴会场 / maidata 追加 / union 独有）没有国服世代年号
        '${song.basicInfo.artist} · '
        '${StringUtil.formatVersion2WithFlag(song.basicInfo.from, SongFilterUtil.isExtra(song))}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () =>
          Navigator.pop(ctx, _SongChoice(song: song, manualTitle: null)),
    );
  }

  // ========== UI 框架 ==========

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final c = Theme.of(context).colorScheme.onSurface;
    return BackgroundPageScaffold(
      title: '结算画面识别',
      resizeToAvoidBottomInset: false,
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 10,
      ),
      child: SizedBox.expand(child: _buildContent(sw, c)),
    );
  }

  Widget _buildContent(double sw, Color c) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(sw * 0.04, 8, sw * 0.04,
          sw * 0.04 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_loggedIn == false) ...[
            _OcrHubLoginPanel(
              onLoggedIn: () {
                setState(() {
                  _loggedIn = true;
                  _error = null;
                });
                AppToast.show('maimai Score Hub 登录成功');
              },
            ),
            const SizedBox(height: 16),
          ],
          if (_isRecognizing) ...[
            _buildRecognizing(sw, c),
          ] else if (_result != null) ...[
            _buildResultList(sw, c),
            const SizedBox(height: 16),
            _buildActionButtons(sw, c),
          ] else if (_photoPath != null) ...[
            _buildPhotoPreview(sw, c),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _buildErrorBanner(sw, c),
            ],
            const SizedBox(height: 16),
            _buildActionButtons(sw, c),
          ] else ...[
            _buildGuide(sw, c),
            const SizedBox(height: 16),
            _buildActionButtons(sw, c),
          ],
        ],
      ),
    );
  }

  Widget _buildRecognizing(double sw, Color c) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('正在识别成绩',
                style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('曲绘 + 标题双路匹配，通常需要几秒',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildGuide(double sw, Color c) => const RecognitionGuideCard(
        icon: Icons.document_scanner,
        title: '对着机台结算页面拍一张照片',
        description: '自动识别曲名、达成率、DX 分数、难度与 FC/FS',
        steps: ['拍照或从相册选择结算画面', '尽量拍正、拍清，识别更准', '核对结果后可同步到水鱼或落雪'],
      );

  Widget _buildPhotoPreview(double sw, Color c) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: sw),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
              child: Image.file(
                File(_photoPath!),
                fit: BoxFit.contain,
                cacheWidth: 1080,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text('图片已就绪，点击下方「开始识别」',
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 错误 / 未登录这类提示条：浅色底 + 图标 + 说明。
  Widget _buildNoticeBanner(IconData icon, Color color, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(double sw, Color c) => _buildNoticeBanner(
        Icons.error_outline,
        AppColors.errorRed(Theme.of(context).brightness),
        _error ?? '',
      );

  /// 未登录 maimai Score Hub 时的提示横幅。
  ///
  /// 识别接口必须带用户 token，未登录必然 401，所以提前说清楚，
  /// 免得用户截好图才在最后一步失败。
  // ========== 结构化识别结果 ==========

  Widget _buildResultList(double sw, Color c) {
    final batch = _result!;
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Icon(
                batch.hasAnySuccess ? Icons.check_circle : Icons.error_outline,
                size: 20,
                color: batch.hasAnySuccess
                    ? AppColors.successGreen(brightness)
                    : AppColors.errorRed(brightness),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  batch.hasAnySuccess
                      ? '识别完成 · ${batch.okCount}/${batch.results.length} 张成功'
                      : '未能识别出成绩',
                  style: TextStyle(
                      color: c, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        ...batch.results.map((item) => _buildResultCard(item, sw, c)),
      ],
    );
  }

  Widget _buildResultCard(MaimaiHubOcrItem item, double sw, Color c) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final best = item.bestCandidate;
    // 生效的歌曲 / 难度 / 成绩：玩家改过就用改后的，否则用 OCR 的原始结果
    final song = _songOf(item);
    final difficulty = _difficultyOf(item);
    final diffIndex = _difficultyIndexOf(difficulty);
    final achievement = _achievementOf(item);
    final dxScore = _dxScoreOf(item);
    final fcBadge = _fcBadge(_fcOf(item));
    final fsBadge = _fsBadge(_fsOf(item));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignTokens.cardGap),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 曲名（左侧带曲绘 + 难度 / 谱面类型）────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 曲绘：只在能定位到歌曲时才有（否则宁可不显示）
                if (song != null) ...[
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusSmall),
                    child: CoverUtil.buildCoverWidget(song.id, 76),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildDifficultyBadge(item, brightness),
                          if (item.isDx != null)
                            _buildChip(item.isDx! ? 'DX' : '标准', scheme.primary),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (best != null)
                        Text(
                          _edits[item.index]?.titleOf(best.title) ?? best.title,
                          style: TextStyle(
                              color: scheme.onSurface,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              height: 1.25),
                        )
                      else
                        Text('未识别出曲名',
                            style: TextStyle(
                                color: AppColors.errorRed(brightness),
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      // 曲师：曲库匹配到才有
                      if (song != null &&
                          song.basicInfo.artist.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          song.basicInfo.artist,
                          style: TextStyle(
                              color: scheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // ── 核心数字：达成率 + DX 分数（改了就用改后的值）──────────
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: AppSurfaces.inset(context),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusMedium),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildHeroStat(
                      label: '达成率',
                      value: achievement == null
                          ? '—'
                          : '${achievement.toStringAsFixed(4)}%',
                      grade: _achievementGrade(achievement),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: AppSurfaces.hairline(context),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildHeroStat(
                      label: 'DX 分数',
                      value: dxScore?.toString() ?? '—',
                    ),
                  ),
                ],
              ),
            ),

            // ── 成就徽章：只在确实有数据时出现（改了就用改后的值）──────
            if (fcBadge != null || fsBadge != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (fcBadge != null) ComboLabelBadge(raw: fcBadge),
                  if (fcBadge != null && fsBadge != null)
                    const SizedBox(width: 6),
                  if (fsBadge != null) ComboLabelBadge(raw: fsBadge),
                ],
              ),
            ],

            // ── 曲库信息 / 置信度 / 命中来源 ──────────────────────────
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (song != null && song.basicInfo.from.trim().isNotEmpty)
                  _buildChip(
                      // extra 曲目走不带年号的口径（宴会场 / 追加曲）
                      StringUtil.formatVersion2WithFlag(
                          song.basicInfo.from, SongFilterUtil.isExtra(song)),
                      scheme.primary),
                if (song != null && song.basicInfo.genre.trim().isNotEmpty)
                  _buildChip(song.basicInfo.genre, scheme.tertiary),
                if (song != null &&
                    diffIndex != null &&
                    _levelAtIndex(song, diffIndex) != null)
                  _buildChip(
                      '等级 ${_levelAtIndex(song, diffIndex)}', scheme.secondary),
                if (song != null &&
                    diffIndex != null &&
                    _dsAtIndex(song, diffIndex) != null)
                  _buildChip(
                      '定数 ${_dsAtIndex(song, diffIndex)!.toStringAsFixed(1)}',
                      scheme.secondary),
                if (best != null)
                  _buildChip(
                    best.confidence == null
                        ? '置信度 —'
                        : '置信度 ${(best.confidence! * 100).toStringAsFixed(1)}%',
                    _confidenceColor(best.confidence, brightness),
                  ),
              ],
            ),
            // 命中来源（曲绘 / 标题）
            if (best != null && best.sources.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '命中来源：${best.sources.map(_sourceLabel).join(' + ')}',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
              ),
            ],

            // ── 操作区 ────────────────────────────────────────────
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showEditSheet(item),
              icon: const Icon(Icons.edit_note, size: 18),
              label: const Text('编辑此项'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _canSync(item) && _uploadingIndex != item.index
                        ? () => _syncToDivingFish(item)
                        : null,
                    icon: _uploadingIndex == item.index
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                          _uploadingIndex == item.index ? '同步中...' : '同步到水鱼'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    // 落雪要数字曲目 id，且 id 体系与水鱼不同（服务层负责转换）。
                    // 与「同步到水鱼」共用 _canSync 的前置条件。
                    onPressed:
                        _canSync(item) && _uploadingLuoXueIndex != item.index
                            ? () => _syncToLuoXue(item)
                            : null,
                    icon: _uploadingLuoXueIndex == item.index
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_sync_outlined, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_uploadingLuoXueIndex == item.index
                          ? '同步中...'
                          : '同步到落雪'),
                    ),
                  ),
                ),
              ],
            ),

            // ── 同步不可用的原因 ──────────────────────────────────
            //
            // 就贴在按钮下面：这两个按钮为什么会变灰，答案必须紧挨着它们，
            // 否则用户只会去怀疑账号状态。
            if (item.isOk && _syncBlockReason(item) != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: AppColors.warningOrange(brightness)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '暂不能同步：${_syncBlockReason(item)}',
                        style: TextStyle(
                          color: AppColors.warningOrange(brightness),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── 其它候选 ──────────────────────────────────────────
            if (item.candidates.length > 1) ...[
              const SizedBox(height: 10),
              Text(
                '其它候选：${item.candidates.skip(1).map((x) => x.title).join(' · ')}',
                style: TextStyle(
                    color: scheme.onSurfaceVariant, fontSize: 11, height: 1.4),
              ),
            ],

            // ── 失败原因 ──────────────────────────────────────────
            if (!item.isOk && item.error != null) ...[
              const SizedBox(height: 8),
              Text(item.error!,
                  style: TextStyle(
                      color: AppColors.errorRed(brightness), fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  /// 核心数字（达成率 / DX 分数）：大号数值 + 小号标签，放不下时等比缩小。
  Widget _buildHeroStat({
    required String label,
    required String value,
    String? grade,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    maxLines: 1,
                    style: AppTheme.number(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface)),
                if (grade != null) ...[
                  const SizedBox(width: 6),
                  RankBadge(rank: grade),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
      ],
    );
  }

  /// 难度徽章（带难度配色，复用项目里 difficulty*ByIndex 的色板）
  Widget _buildDifficultyBadge(MaimaiHubOcrItem item, Brightness brightness) {
    // 用修正后的难度：玩家改了难度，徽章要跟着变
    final effective = _difficultyOf(item);
    final label = _difficultyLabel(effective);
    if (label == null) return const SizedBox.shrink();
    final index = _difficultyIndex(effective);
    // utage 不在 0-4 索引里，用中性色兜底
    final fg = index == null
        ? AppColors.greyHint(brightness)
        : AppColors.difficultyForegroundByIndex(index, brightness: brightness);
    final bg = index == null
        ? AppColors.greyHint(brightness).withValues(alpha: 0.15)
        : AppColors.difficultyBackgroundByIndex(index, brightness: brightness);
    // 等级优先取曲库里该难度的真实值（玩家换歌/换难度后 OCR 的 level 就不可信了）
    final idx = _difficultyIndexOf(effective);
    final song = _songOf(item);
    final level = (idx != null && song != null)
        ? (_levelAtIndex(song, idx) ?? item.level)
        : item.level;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        level == null ? label : '$label $level',
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildChip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  String _sourceLabel(String source) {
    switch (source) {
      case 'cover':
        return '曲绘';
      case 'title':
        return '标题';
      default:
        return source;
    }
  }

  Color _confidenceColor(double? confidence, Brightness brightness) {
    if (confidence == null) return AppColors.greyHint(brightness);
    if (confidence >= 0.9) return AppColors.successGreen(brightness);
    if (confidence >= 0.7) return AppColors.warningOrange(brightness);
    return AppColors.errorRed(brightness);
  }

  /// 服务端 difficulty → 展示文案；未知值返回 null（不渲染徽章）
  String? _difficultyLabel(String? difficulty) {
    final index = ChartDifficulty.indexOf(difficulty);
    return index == null ? null : ChartDifficulty.labelOf(index);
  }

  /// 服务端 difficulty → 难度色索引（0-4）。
  /// 宴会场不在这个体系里，返回 null 由调用方兜底。
  int? _difficultyIndex(String? difficulty) {
    return ChartDifficulty.standardIndexOf(difficulty);
  }

  /// 达成率 → 评级文案（阈值沿用项目里 UserScoreSearchPage 的口径）。
  /// 传入 null 时返回 null。
  String? _achievementGrade(double? achievement) {
    if (achievement == null) return null;
    if (achievement >= 100.5) return 'SSS+';
    if (achievement >= 100.0) return 'SSS';
    if (achievement >= 99.5) return 'SS+';
    if (achievement >= 99.0) return 'SS';
    if (achievement >= 98.0) return 'S+';
    if (achievement >= 97.0) return 'S';
    if (achievement >= 94.0) return 'AAA';
    if (achievement >= 90.0) return 'AA';
    if (achievement >= 80.0) return 'A';
    if (achievement >= 75.0) return 'BBB';
    if (achievement >= 70.0) return 'BB';
    if (achievement >= 60.0) return 'B';
    if (achievement >= 50.0) return 'C';
    return 'D';
  }

  /// 连击标记徽章文案；无数据返回 null（不渲染徽章）
  String? _fcBadge(String? fc) {
    switch (fc) {
      case 'fc':
        return 'FC';
      case 'fcp':
        return 'FC+';
      case 'ap':
        return 'AP';
      case 'app':
        return 'AP+';
      default:
        return null;
    }
  }

  /// 同步标记徽章文案；无数据返回 null（不渲染徽章）。
  ///
  /// 值域统一成水鱼的写法（fs/fsp/fsd/fsdp/sync），显示直接用
  /// [StringUtil.formatFS]：fsd→FDX、fsdp→FDX+、sync→SC。
  String? _fsBadge(String? fs) {
    if (fs == null || fs.isEmpty) return null;
    const known = {'fs', 'fsp', 'fsd', 'fsdp', 'sync'};
    if (!known.contains(fs)) return null;
    return StringUtil.formatFS(fs);
  }

  Widget _buildActionButtons(double sw, Color c) {
    final hasPhoto = _photoPath != null;
    final hasResult = _result != null;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!hasPhoto)
            FilledButton.icon(
              onPressed: _showSourcePicker,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('选择图片'),
            )
          else ...[
            FilledButton.icon(
              onPressed: _isRecognizing ? null : _recognize,
              icon: Icon(hasResult ? Icons.refresh : Icons.document_scanner),
              label: Text(hasResult ? '再次识别' : '开始识别'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _showSourcePicker,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('换一张'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('清除重选'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// 落雪密钥粘贴对话框
//
// 为什么单独抽出来做一个 StatefulWidget：TextEditingController 必须在
// TextField 卸载**之后**才能 dispose，否则退出动画跑的时候 TextField 还在
// 监听，强行 dispose 会触发 framework.dart 的 `_dependents.isEmpty` 断言。
// 把 controller 放进自己的 State、让它在 dispose() 里自释放，时机就由
// 框架兜底，不用手动 `addPostFrameCallback` 赌一帧。
// ────────────────────────────────────────────────────────

/// 「粘贴落雪密钥」对话框。
/// 没登录 maimai Score Hub 时就地用二维码登录：只认证，不抓取也不同步成绩。
/// 控制器由这里的 State 持有，页面重建不会清掉输入。
class _OcrHubLoginPanel extends StatefulWidget {
  final VoidCallback onLoggedIn;

  const _OcrHubLoginPanel({required this.onLoggedIn});

  @override
  State<_OcrHubLoginPanel> createState() => _OcrHubLoginPanelState();
}

class _OcrHubLoginPanelState extends State<_OcrHubLoginPanel> {
  final _controller = TextEditingController();
  bool _loggingIn = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loggingIn) return;
    final qrCode = _controller.text.trim();
    if (qrCode.isEmpty) {
      setState(() => _error = '请粘贴或扫描登入二维码');
      return;
    }
    if (!qrCode.startsWith('SGWCMAID')) {
      setState(() => _error = '请使用舞萌|中二公众号生成的登入二维码');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _loggingIn = true;
      _error = null;
    });
    try {
      final result = await DivingFishProbeManager().loginByQr(qrCode);
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _loggingIn = false;
          _error = '登录失败，二维码可能已过期，请重新生成';
        });
        return;
      }
      widget.onLoggedIn();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loggingIn = false;
        _error = '登录失败：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '先登录 maimai Score Hub',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            '识别结算画面需要登录。在舞萌 | 中二公众号请求并打开登入二维码，扫描后把字符串填到下面。'
            '只用来认证，不会抓取或同步成绩；登录状态保存在本机，之后不用重复登录。',
            style: TextStyle(
                fontSize: 12.5, height: 1.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          QrQuickFillButtons(controller: _controller, enabled: !_loggingIn),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            enabled: !_loggingIn,
            maxLines: 3,
            minLines: 1,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: '机台登入二维码',
              hintText: 'SGWCMAID...',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              errorText: _error,
              errorMaxLines: 3,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _loggingIn ? null : _login,
            icon: _loggingIn
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login, size: 18),
            label: Text(_loggingIn ? '登录中…' : '登录'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// 内嵌的精简版裁剪页（与 CoverRecognitionPage 的 _ImageCropPage 同等行为，
// 但保持本页独立，不改动 CoverRecognitionPage）
// ────────────────────────────────────────────────────────

enum _OcrCropHandle { none, body, topLeft, topRight, bottomLeft, bottomRight }

class _OcrImageCropPage extends StatefulWidget {
  final String imagePath;
  const _OcrImageCropPage({required this.imagePath});

  @override
  State<_OcrImageCropPage> createState() => _OcrImageCropPageState();
}

class _OcrImageCropPageState extends State<_OcrImageCropPage> {
  ui.Image? _image;
  bool _loading = true;
  bool _cropping = false;
  Rect _imageRect = Rect.zero;
  Rect _cropRect = Rect.zero;
  _OcrCropHandle _activeHandle = _OcrCropHandle.none;
  Offset? _dragStart;
  Rect? _cropRectStart;

  final double _handleSize = 24;
  final double _minCropSize = 50;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      // 裁剪使用已经限制到 2048px 的预览图，避免再次把相机原图全尺寸解码。
      final data = await _image!.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        AppToast.show('裁剪失败，将使用原图继续');
        return;
      }
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 2048);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _image?.dispose();
        _image = frame.image;
        _loading = false;
      });
    } catch (e) {
      debugPrint('OCR 裁剪页加载图片失败: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.show('图片无法读取，请换一张图片重试');
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Rect _calcImageRect(Size container) {
    if (_image == null) return Rect.zero;
    final iw = _image!.width.toDouble();
    final ih = _image!.height.toDouble();
    final scale = (container.width / iw) < (container.height / ih)
        ? container.width / iw
        : container.height / ih;
    final dw = iw * scale;
    final dh = ih * scale;
    final dx = (container.width - dw) / 2;
    final dy = (container.height - dh) / 2;
    return Rect.fromLTWH(dx, dy, dw, dh);
  }

  void _initCropRect() {
    final size = math.min(_imageRect.width, _imageRect.height) * 0.7;
    setState(() {
      _cropRect = Rect.fromLTWH(
        _imageRect.left + (_imageRect.width - size) / 2,
        _imageRect.top + (_imageRect.height - size) / 2,
        size,
        size,
      );
    });
  }

  Rect _clampCropRect(Rect rect, Rect imageRect) {
    final maxSize = math.min(imageRect.width, imageRect.height);
    if (maxSize <= 0) return Rect.zero;
    final minSize = math.min(_minCropSize, maxSize);
    final size = rect.width.clamp(minSize, maxSize).toDouble();
    final maxLeft = math.max(imageRect.left, imageRect.right - size);
    final maxTop = math.max(imageRect.top, imageRect.bottom - size);
    final left = rect.left.clamp(imageRect.left, maxLeft).toDouble();
    final top = rect.top.clamp(imageRect.top, maxTop).toDouble();
    return Rect.fromLTWH(left, top, size, size);
  }

  MouseCursor _cursorForHandle(_OcrCropHandle h) => switch (h) {
        _OcrCropHandle.topLeft ||
        _OcrCropHandle.bottomRight =>
          SystemMouseCursors.resizeUpLeftDownRight,
        _OcrCropHandle.topRight ||
        _OcrCropHandle.bottomLeft =>
          SystemMouseCursors.resizeUpRightDownLeft,
        _OcrCropHandle.body => SystemMouseCursors.move,
        _ => SystemMouseCursors.basic,
      };

  _OcrCropHandle _hitTest(Offset p) {
    const r = 20.0;
    if ((p - _cropRect.topLeft).distance < r) return _OcrCropHandle.topLeft;
    if ((p - _cropRect.topRight).distance < r) return _OcrCropHandle.topRight;
    if ((p - _cropRect.bottomLeft).distance < r) {
      return _OcrCropHandle.bottomLeft;
    }
    if ((p - _cropRect.bottomRight).distance < r) {
      return _OcrCropHandle.bottomRight;
    }
    if (_cropRect.contains(p)) return _OcrCropHandle.body;
    return _OcrCropHandle.none;
  }

  void _onPanStart(DragStartDetails d) {
    _activeHandle = _hitTest(d.localPosition);
    _dragStart = d.localPosition;
    _cropRectStart = _cropRect;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_activeHandle == _OcrCropHandle.none ||
        _cropRectStart == null ||
        _dragStart == null) {
      return;
    }
    final delta = d.localPosition - _dragStart!;
    final r = _cropRectStart!;
    final minSize = math.min(
      _minCropSize,
      math.min(_imageRect.width, _imageRect.height),
    );
    if (minSize <= 0) return;
    Rect newRect;
    switch (_activeHandle) {
      case _OcrCropHandle.body:
        var dx = r.left + delta.dx;
        var dy = r.top + delta.dy;
        if (dx < _imageRect.left) dx = _imageRect.left;
        if (dy < _imageRect.top) dy = _imageRect.top;
        if (dx + r.width > _imageRect.right) dx = _imageRect.right - r.width;
        if (dy + r.height > _imageRect.bottom) {
          dy = _imageRect.bottom - r.height;
        }
        newRect = Rect.fromLTWH(dx, dy, r.width, r.height);
      case _OcrCropHandle.topLeft:
        final maxDelta =
            math.max(r.width - delta.dx, r.height - delta.dy).toDouble();
        final maxSize = math.max(
            minSize,
            math.min(
              r.right - _imageRect.left,
              r.bottom - _imageRect.top,
            ));
        final size = maxDelta.clamp(minSize, maxSize).toDouble();
        newRect = Rect.fromLTWH(
          (r.right - size).clamp(_imageRect.left, _imageRect.right - minSize),
          (r.bottom - size).clamp(_imageRect.top, _imageRect.bottom - minSize),
          size,
          size,
        );
      case _OcrCropHandle.topRight:
        final maxDelta =
            math.max(r.width + delta.dx, r.height - delta.dy).toDouble();
        final maxSize = math.max(
            minSize,
            math.min(
              _imageRect.right - r.left,
              r.bottom - _imageRect.top,
            ));
        final size = maxDelta.clamp(minSize, maxSize).toDouble();
        newRect = Rect.fromLTWH(
          r.left.clamp(_imageRect.left, _imageRect.right - minSize),
          (r.bottom - size).clamp(_imageRect.top, _imageRect.bottom - minSize),
          size,
          size,
        );
      case _OcrCropHandle.bottomLeft:
        final maxDelta =
            math.max(r.width - delta.dx, r.height + delta.dy).toDouble();
        final maxSize = math.max(
            minSize,
            math.min(
              r.right - _imageRect.left,
              _imageRect.bottom - r.top,
            ));
        final size = maxDelta.clamp(minSize, maxSize).toDouble();
        newRect = Rect.fromLTWH(
          (r.right - size).clamp(_imageRect.left, _imageRect.right - minSize),
          r.top.clamp(_imageRect.top, _imageRect.bottom - minSize),
          size,
          size,
        );
      case _OcrCropHandle.bottomRight:
        final maxDelta =
            math.max(r.width + delta.dx, r.height + delta.dy).toDouble();
        final maxSize = math.max(
            minSize,
            math.min(
              _imageRect.right - r.left,
              _imageRect.bottom - r.top,
            ));
        final size = maxDelta.clamp(minSize, maxSize).toDouble();
        newRect = Rect.fromLTWH(
          r.left.clamp(_imageRect.left, _imageRect.right - minSize),
          r.top.clamp(_imageRect.top, _imageRect.bottom - minSize),
          size,
          size,
        );
      case _OcrCropHandle.none:
        return;
    }
    setState(() => _cropRect = newRect);
  }

  void _onPanEnd(DragEndDetails d) {
    _activeHandle = _OcrCropHandle.none;
    _dragStart = null;
    _cropRectStart = null;
  }

  Future<String?> _doCrop() async {
    if (_image == null || _imageRect.isEmpty || _cropRect.isEmpty) {
      return widget.imagePath;
    }
    try {
      final crop = _cropRect.intersect(_imageRect);
      if (crop.isEmpty || crop.width <= 0 || crop.height <= 0) {
        return widget.imagePath;
      }
      final bytes = await File(widget.imagePath).readAsBytes();
      final encoded = await OcrImageCropUtil.cropAndEncodeAsync(
        bytes: bytes,
        left: (crop.left - _imageRect.left) / _imageRect.width,
        top: (crop.top - _imageRect.top) / _imageRect.height,
        width: crop.width / _imageRect.width,
        height: crop.height / _imageRect.height,
      );
      if (encoded == null) {
        AppToast.show('裁剪失败，将使用原图继续');
        return widget.imagePath;
      }
      final outPath =
          '${Directory.systemTemp.path}/ocr_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outPath).writeAsBytes(encoded, flush: true);
      return outPath;
    } catch (e) {
      debugPrint('OCR 裁剪出错: $e');
      AppToast.show('裁剪失败，将使用原图继续');
      return widget.imagePath;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _image == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: kToolbarHeight,
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 20),
                    label:
                        const Text('取消', style: TextStyle(color: Colors.white)),
                  ),
                  const Spacer(),
                  const Text('拖动角点框选成绩区域',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      if (_cropping) return;
                      setState(() => _cropping = true);
                      final navigator = Navigator.of(context);
                      try {
                        final out = await _doCrop();
                        if (mounted) navigator.pop(out);
                      } finally {
                        if (mounted) setState(() => _cropping = false);
                      }
                    },
                    icon:
                        const Icon(Icons.check, color: Colors.green, size: 20),
                    label: Text(_cropping ? '处理中...' : '确认',
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(builder: (ctx, c) {
                final actualSize = Size(c.maxWidth, c.maxHeight);
                _imageRect = _calcImageRect(actualSize);
                if (_imageRect.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                if (_cropRect.isEmpty || _cropRect == Rect.zero) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _initCropRect());
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                _cropRect = _clampCropRect(_cropRect, _imageRect);
                return GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: MouseRegion(
                    cursor: _activeHandle != _OcrCropHandle.none
                        ? _cursorForHandle(_activeHandle)
                        : SystemMouseCursors.basic,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: RawImage(image: _image, fit: BoxFit.contain),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _OcrCropOverlayPainter(
                              imageRect: _imageRect,
                              cropRect: _cropRect,
                              handleSize: _handleSize,
                              handleBorderColor:
                                  Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            Container(
              height: 48,
              color: Colors.black87,
              alignment: Alignment.center,
              child: Text(
                '拖拽四角调整范围  |  拖拽框内移动位置',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OcrCropOverlayPainter extends CustomPainter {
  final Rect imageRect;
  final Rect cropRect;
  final double handleSize;
  final Color handleBorderColor;
  _OcrCropOverlayPainter({
    required this.imageRect,
    required this.cropRect,
    required this.handleSize,
    required this.handleBorderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mask = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawRect(
        Rect.fromLTRB(
            imageRect.left, imageRect.top, imageRect.right, cropRect.top),
        mask);
    canvas.drawRect(
        Rect.fromLTRB(
            imageRect.left, cropRect.bottom, imageRect.right, imageRect.bottom),
        mask);
    canvas.drawRect(
        Rect.fromLTRB(
            imageRect.left, cropRect.top, cropRect.left, cropRect.bottom),
        mask);
    canvas.drawRect(
        Rect.fromLTRB(
            cropRect.right, cropRect.top, imageRect.right, cropRect.bottom),
        mask);

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(cropRect, border);

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final thirdW = cropRect.width / 3;
    final thirdH = cropRect.height / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(cropRect.left + thirdW * i, cropRect.top),
          Offset(cropRect.left + thirdW * i, cropRect.bottom), grid);
      canvas.drawLine(Offset(cropRect.left, cropRect.top + thirdH * i),
          Offset(cropRect.right, cropRect.top + thirdH * i), grid);
    }

    final handle = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final handleBorder = Paint()
      ..color = handleBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final corner in [
      cropRect.topLeft,
      cropRect.topRight,
      cropRect.bottomLeft,
      cropRect.bottomRight,
    ]) {
      final r = Rect.fromCenter(
          center: corner, width: handleSize, height: handleSize);
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)), handle);
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)), handleBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _OcrCropOverlayPainter old) =>
      cropRect != old.cropRect || imageRect != old.imageRect;
}
