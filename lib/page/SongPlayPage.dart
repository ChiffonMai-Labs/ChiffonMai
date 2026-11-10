import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
/*
 * 歌曲详情页的「播放音乐」页 —— **已经接管到随身听**。
 *
 * 历史：这里原本自己 new 一个 `audioplayers` 的 `AudioPlayer`，在 `dispose()` 里
 * `stop + dispose`，所以「退出这个页面 = 音乐停」，也不会有通知栏控制。
 *
 * 现在这一页只做三件事：
 *   1. 把 songId 解析成随身听条目（[PortableSongLibrary.resolveForPlayback]，含落雪基础、
 *      AWMC 追加，以及目录未及时收录时的原始 songId 兜底）；
 *   2. 交给全局的 [PortablePlayerController] 播放（不持有播放器所有权）；
 *   3. 渲染随身听的全屏播放界面。
 *
 * 因此退出这一页**不会**中断音乐，悬浮球和通知栏也照常工作。
 *
 * 保留原来的构造签名（songId / songTitle / songType），这样 `SongInfoPage`
 * 等调用点的改动最小。
 */
import 'dart:async';

import 'package:flutter/material.dart';

import '../entity/Portable/PortableSong.dart';
import '../service/Portable/PortablePlayerController.dart';
import '../service/Portable/PortableSongLibrary.dart';
import '../utils/PortablePlayerScope.dart';
import 'Portable/PortableNowPlayingPage.dart';

class SongPlayPage extends StatefulWidget {
  final String songId;
  final String songTitle;
  final String songType;
  final String? songArtist;

  const SongPlayPage({
    super.key,
    required this.songId,
    required this.songTitle,
    required this.songType,
    this.songArtist,
  });

  @override
  State<SongPlayPage> createState() => _SongPlayPageState();
}

class _SongPlayPageState extends State<SongPlayPage> {
  final PortableSongLibrary _library = PortableSongLibrary();
  final PortablePlayerController _player = PortablePlayerController();

  /// 是否已经把播放权交给全局播放器。
  ///
  /// 这一页可能在音乐已经在放的时候被打开（比如从随身听列表再点进来），
  /// 那种情况下不该打断当前播放去重播这首歌 —— 只有当这首**不是**当前曲目时
  /// 才真的切过去。
  bool _handedOff = false;
  String? _message;
  late PortableSong _resolved;
  Animation<double>? _entrance;
  int _request = 0;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    // 详情页已提供显示所需信息，不等整份曲库加载就先呈现完整播放器。
    _resolved = _resolveSong() ??
        PortableSong(
          lxnsId: 0,
          divingFishId: widget.songId,
          audioId: 0,
          title: widget.songTitle,
          artist: widget.songArtist ?? '',
          genre: '',
          bpm: 0,
        );
    // 从 SongInfoPage 点「播放音乐」进来的：把随身听悬浮球压住，避免它突然冒出来。
    // 不影响播放、不影响通知栏、不影响切歌；页面一 pop 这层就撤掉，球回来。
    PortablePlayerScope.isSongInfoPlayback.value = true;
    // 退出时要按设置决定是否唤起悬浮球，没进过随身听时这里也要读到用户的设置。
    unawaited(PortablePlayerScope.loadPreferences());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isLeaving) return;
      final entrance = ModalRoute.of(context)?.animation;
      if (entrance == null || entrance.isCompleted) {
        unawaited(_resolveAndPlay());
      } else {
        _entrance = entrance;
        entrance.addStatusListener(_onEntranceStatus);
      }
    });
  }

  PortableSong? _resolveSong() => _library.resolveForPlayback(
        songId: widget.songId,
        title: widget.songTitle,
        type: widget.songType,
        artist: widget.songArtist,
      );

  void _onEntranceStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _entrance?.removeStatusListener(_onEntranceStatus);
    _entrance = null;
    // 让入场动画的最后一帧也先完成，再开始曲库准备。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isLeaving) unawaited(_resolveAndPlay());
    });
  }

  @override
  void dispose() {
    _request++;
    _entrance?.removeStatusListener(_onEntranceStatus);
    // 撤掉悬浮球抑制：球按 `_player.currentSong != null` 自然显示（如果还在放）
    PortablePlayerScope.isSongInfoPlayback.value = false;
    // 用户上次手动隐藏过悬浮球时，主动打开过播放页就算重新唤起，否则退出后球一直不回来。
    if (PortablePlayerScope.showBallOnLibraryExit.value) {
      PortablePlayerScope.wakeBall();
    }
    super.dispose();
  }

  Future<void> _resolveAndPlay() async {
    if (!mounted || _isLeaving) return;
    final request = ++_request;
    setState(() => _message = null);
    try {
      final current = _player.currentSong;
      if (_resolved.audioId > 0 && current?.lxnsId == _resolved.lxnsId) {
        setState(() => _handedOff = true);
        return;
      }
      // 曲库可能还没构建过（用户没进过随身听页），先确保加载
      await _library.load();
      if (!mounted || _isLeaving || request != _request) return;
      final song = _resolveSong();

      if (song == null) {
        setState(() {
          _message = appL10n.flowNoAudioIsAvailableForThisSong;
        });
        return;
      }
      setState(() => _resolved = song);

      if (_player.currentSong?.lxnsId == song.lxnsId) {
        // 已经就是当前曲目：不动播放状态，只把界面换过来
        setState(() => _handedOff = true);
        return;
      }

      // 播放器还要下载或读取音频，等它发布当前曲目后才退出准备态。
      await _player.playSong(song);
      if (!mounted || _isLeaving || request != _request) return;
      if (_player.currentSong?.lxnsId != song.lxnsId) {
        setState(() => _message = appL10n.flowCouldNotLoadAudioTryAgainLater);
        return;
      }
      setState(() => _handedOff = true);
    } catch (e) {
      debugPrint('[SongPlay] 音源准备失败: $e');
      if (!mounted || _isLeaving || request != _request) return;
      setState(() => _message = appL10n.flowCouldNotLoadAudioTryAgainLater);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 第一帧就进入全屏播放页，音源准备期间也保留曲绘、歌名和控制区。
    // 同一个页面从准备态过渡到播放态，曲绘和取色背景不会重新入场。
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        _isLeaving = true;
        _request++;
      },
      child: PortableNowPlayingPage(
        preparingSong: _handedOff ? null : _resolved,
        preparationError: _message,
        onRetryPreparation: () => unawaited(_resolveAndPlay()),
        // 试听页只会从歌曲详情打开：仍在播这首歌时「查看歌曲详情」直接返回
        sourceSongId: widget.songId,
      ),
    );
  }
}
