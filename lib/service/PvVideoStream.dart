import 'dart:io';

/// 转发播放器的 Range 请求，并统计该 PV 从网络收到的字节数。
class PvVideoStream {
  PvVideoStream(this._source, this._headers);

  final Uri _source;
  final Map<String, String> _headers;
  final _client = HttpClient()..autoUncompress = false;
  HttpServer? _server;
  bool _closed = false;
  int receivedBytes = 0;

  Future<Uri> open() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    if (_closed) {
      await server.close(force: true);
      throw StateError('PV 流已关闭');
    }
    _server = server;
    server.listen(_forward);
    return Uri.http('127.0.0.1:${server.port}', '/pv.mp4');
  }

  Future<void> _forward(HttpRequest request) async {
    final response = request.response;
    if (request.uri.path != '/pv.mp4' ||
        (request.method != 'GET' && request.method != 'HEAD')) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }

    HttpClientRequest? upstream;
    try {
      upstream = await _client.openUrl(request.method, _source);
      _headers.forEach(upstream.headers.set);
      upstream.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      for (final name in [HttpHeaders.rangeHeader, 'if-range']) {
        final value = request.headers.value(name);
        if (value != null) upstream.headers.set(name, value);
      }
      final input = await upstream.close();
      response.statusCode = input.statusCode;
      for (final name in [
        HttpHeaders.contentTypeHeader,
        HttpHeaders.contentRangeHeader,
        HttpHeaders.acceptRangesHeader,
        HttpHeaders.etagHeader,
        HttpHeaders.lastModifiedHeader,
      ]) {
        final value = input.headers.value(name);
        if (value != null) response.headers.set(name, value);
      }
      response.contentLength = input.contentLength;
      await response.addStream(input.map((chunk) {
        receivedBytes += chunk.length;
        return chunk;
      }));
      await response.close();
    } catch (_) {
      upstream?.abort();
      try {
        response.statusCode = HttpStatus.badGateway;
        await response.close();
      } catch (_) {
        // 响应体已开始时断开连接，让播放器决定是否重试请求。
        try {
          (await response.detachSocket(writeHeaders: false)).destroy();
        } catch (_) {}
      }
    }
  }

  void close() {
    _closed = true;
    _client.close(force: true);
    _server?.close(force: true);
  }
}
