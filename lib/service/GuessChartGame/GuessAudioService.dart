import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../../api/ApiUrls.dart';
import '../../utils/ApiClient.dart';

enum GuessAudioMode { normal, reverseAudio, pitchAudio }

extension GuessAudioModeLabel on GuessAudioMode {
  String get title => switch (this) {
        GuessAudioMode.normal => '歌曲片段猜歌',
        GuessAudioMode.reverseAudio => '倒放音频猜歌',
        GuessAudioMode.pitchAudio => '变速变调猜歌',
      };
}

class GuessAudioService {
  static final Map<String, Future<File>> _pending = {};

  /// 服务端输出固定的 PCM WAV；直接读取文件头，避免等待播放器的时长事件。
  static Future<Duration> readExcerptDuration(File file) async {
    final input = await file.open();
    try {
      final header = await input.read(44);
      if (header.length != 44 ||
          ascii.decode(header.sublist(0, 4)) != 'RIFF' ||
          ascii.decode(header.sublist(8, 16)) != 'WAVEfmt ' ||
          ascii.decode(header.sublist(36, 40)) != 'data') {
        throw StateError('无法读取片段时长');
      }
      final data = ByteData.sublistView(header);
      final byteRate = data.getUint32(28, Endian.little);
      final size = data.getUint32(40, Endian.little);
      if (byteRate == 0 || size == 0 || await input.length() < size + 44) {
        throw StateError('音频片段不完整');
      }
      return Duration(
          microseconds: size * Duration.microsecondsPerSecond ~/ byteRate);
    } finally {
      await input.close();
    }
  }

  /// 回合就绪时提前准备；播放按钮沿用同一个请求和本地缓存，失败时点击播放可重试。
  static void prefetch({
    required String musicId,
    required GuessAudioMode mode,
    required int duration,
    required double rate,
    required String seed,
    bool singlePlayer = false,
  }) {
    final watch = Stopwatch()..start();
    debugPrint('[GuessAudio][${mode.name} #$musicId] 预加载开始');
    unawaited(excerpt(
            musicId: musicId,
            mode: mode,
            start: 0,
            duration: duration,
            rate: rate,
            seed: seed,
            singlePlayer: singlePlayer,
            trigger: '预加载')
        .then<void>((_) {
      debugPrint(
          '[GuessAudio][${mode.name} #$musicId] 预加载就绪 ${watch.elapsedMilliseconds}ms');
    }, onError: (Object error) {
      debugPrint(
          '[GuessAudio][${mode.name} #$musicId] 预加载失败 ${watch.elapsedMilliseconds}ms：$error，点击播放时可重试');
    }));
  }

  static Future<File> excerpt(
      {required String musicId,
      required GuessAudioMode mode,
      required int start,
      required int duration,
      double rate = 1.25,
      String? seed,
      bool singlePlayer = false,
      bool original = false,
      String trigger = '播放'}) {
    final key = sha256
        .convert(utf8.encode(
            '${original ? 'original-v1-' : ''}${singlePlayer ? 'single-range-v2-' : ''}$musicId-${mode.name}-$start-$duration-${rate.toStringAsFixed(2)}-${seed ?? ''}'))
        .toString();
    final existing = _pending[key];
    if (existing != null) {
      debugPrint(
          '[GuessAudio][${mode.name} #$musicId ${key.substring(0, 8)}] $trigger复用进行中的准备');
      return existing;
    }
    final future = _download(key, musicId, mode, start, duration, rate, seed,
            singlePlayer, original, trigger)
        .whenComplete(() {
      // remove 返回的正是当前 Future，不能把它交还给 whenComplete，避免自等待。
      _pending.remove(key);
    });
    _pending[key] = future;
    return future;
  }

  static Future<File> _download(
      String key,
      String id,
      GuessAudioMode mode,
      int start,
      int duration,
      double rate,
      String? seed,
      bool singlePlayer,
      bool original,
      String trigger) async {
    final watch = Stopwatch()..start();
    void log(String message) => debugPrint(
        '[GuessAudio][${mode.name} #$id ${key.substring(0, 8)}] $message');
    log('$trigger开始 single=$singlePlayer original=$original duration=${duration}s rate=$rate');
    Timer? heartbeat;
    try {
      final root =
          Directory('${(await getTemporaryDirectory()).path}/guess_audio');
      await root.create(recursive: true);
      final output = File('${root.path}/$key.wav');
      if (await output.exists()) {
        log('命中本地片段缓存 ${watch.elapsedMilliseconds}ms');
        return output;
      }
      final uri = Uri.parse('${ApiUrls.BackendBaseUrl}/api/guess-audio/$id')
          .replace(queryParameters: {
        'mode': mode.name,
        'start': '$start',
        'duration': '$duration',
        'rate': '$rate',
        if (seed != null) 'seed': seed,
        if (singlePlayer) 'single': '1',
        if (original) 'original': '1',
      });
      log('请求 ${uri.host}${uri.path}，等待服务端响应');
      heartbeat = Timer.periodic(const Duration(seconds: 2), (_) {
        log('等待服务端响应，已用时 ${watch.elapsedMilliseconds}ms');
      });
      final response =
          await ApiClient.getStream(uri, timeout: const Duration(seconds: 35));
      heartbeat.cancel();
      log('响应头 ${watch.elapsedMilliseconds}ms status=${response.statusCode} '
          'cache=${response.headers['x-guess-audio-cache'] ?? '-'} '
          'source=${response.headers['x-guess-audio-source'] ?? '-'} '
          'server-timing=${response.headers['server-timing'] ?? '-'}');
      final bytes = BytesBuilder(copy: false);
      var lastProgress = watch.elapsedMilliseconds;
      await for (final chunk
          in response.stream.timeout(const Duration(seconds: 10))) {
        bytes.add(chunk);
        // 5× 题面的原声最长为 150 秒，仍限制在固定 PCM 输出的体积上界内。
        if (bytes.length > (original ? 7 : 2) * 1024 * 1024) {
          throw StateError('音频响应过大');
        }
        if (watch.elapsedMilliseconds > 45000) throw TimeoutException('音频传输超时');
        if (watch.elapsedMilliseconds - lastProgress >= 1000) {
          log('下载片段 ${bytes.length}/${response.contentLength ?? '?'} 字节，已用时 ${watch.elapsedMilliseconds}ms');
          lastProgress = watch.elapsedMilliseconds;
        }
      }
      final data = bytes.takeBytes();
      if (response.statusCode != 200) {
        String? code;
        try {
          code = (jsonDecode(utf8.decode(data)) as Map)['code']?.toString();
        } catch (_) {}
        throw StateError(
            '音源请求失败 HTTP ${response.statusCode}${code == null ? '' : ' ($code)'}');
      }
      if (data.length < 44 || String.fromCharCodes(data.take(4)) != 'RIFF') {
        throw StateError('音频响应不是有效的 WAV 文件');
      }
      log('片段下载完成 ${watch.elapsedMilliseconds}ms bytes=${data.length}');
      final temporary = File('${output.path}.tmp');
      await temporary.writeAsBytes(data);
      final file = await temporary.rename(output.path);
      log('文件就绪 ${watch.elapsedMilliseconds}ms');
      return file;
    } catch (error) {
      log('准备失败 ${watch.elapsedMilliseconds}ms：$error');
      rethrow;
    } finally {
      heartbeat?.cancel();
    }
  }
}
