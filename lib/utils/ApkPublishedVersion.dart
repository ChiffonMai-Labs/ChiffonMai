import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// 只读取 APK 的 ZIP 目录和 AndroidManifest.xml，检查更新时无需下载整个 APK。
class ApkPublishedVersion {
  final String packageName;
  final String version;
  final int build;
  const ApkPublishedVersion(this.packageName, this.version, this.build);

  static Future<ApkPublishedVersion> read(int size,
      Future<Uint8List> Function(int offset, int length) range) async {
    Future<Uint8List> readRange(int offset, int length) async {
      if (offset < 0 ||
          length <= 0 ||
          length > 4 * 1024 * 1024 ||
          offset + length > size) {
        throw  FormatException(appL10n.flowInvalidAPKDirectoryRange);
      }
      final bytes = await range(offset, length);
      if (bytes.length != length) throw  FormatException(appL10n.flowIncompleteAPKDirectoryData);
      return bytes;
    }

    final tail = await readRange(size - min(size, 65557), min(size, 65557));
    final data = ByteData.sublistView(tail);
    var end = tail.length - 22;
    while (end >= 0) {
      if (data.getUint32(end, Endian.little) == 0x06054b50 &&
          end + 22 + data.getUint16(end + 20, Endian.little) == tail.length)
        break;
      end--;
    }
    if (end < 0 ||
        data.getUint16(end + 4, Endian.little) != 0 ||
        data.getUint16(end + 6, Endian.little) != 0) {
      throw  FormatException(appL10n.flowCouldNotReadAPKZIPDirectory);
    }
    final directory = await readRange(data.getUint32(end + 16, Endian.little),
        data.getUint32(end + 12, Endian.little));
    final entries = ByteData.sublistView(directory);
    var offset = 0;
    while (offset + 46 <= directory.length) {
      if (entries.getUint32(offset, Endian.little) != 0x02014b50) break;
      final nameLength = entries.getUint16(offset + 28, Endian.little);
      final extraLength = entries.getUint16(offset + 30, Endian.little);
      final commentLength = entries.getUint16(offset + 32, Endian.little);
      final next = offset + 46 + nameLength + extraLength + commentLength;
      if (next > directory.length) break;
      final name = utf8.decode(
          directory.sublist(offset + 46, offset + 46 + nameLength),
          allowMalformed: true);
      if (name == 'AndroidManifest.xml') {
        final compressedSize = entries.getUint32(offset + 20, Endian.little);
        final uncompressedSize = entries.getUint32(offset + 24, Endian.little);
        if (uncompressedSize <= 0 || uncompressedSize > 4 * 1024 * 1024) {
          throw  FormatException(appL10n.flowInvalidAPKManifestSize);
        }
        final headerOffset = entries.getUint32(offset + 42, Endian.little);
        final header = ByteData.sublistView(await readRange(headerOffset, 30));
        if (header.getUint32(0, Endian.little) != 0x04034b50) {
          throw  FormatException(appL10n.flowInvalidAPKManifestDirectory);
        }
        final content = await readRange(
            headerOffset +
                30 +
                header.getUint16(26, Endian.little) +
                header.getUint16(28, Endian.little),
            compressedSize);
        final method = entries.getUint16(offset + 10, Endian.little);
        Uint8List xml;
        if (method == 0) {
          xml = content;
        } else if (method == 8) {
          final builder = BytesBuilder(copy: false);
          await for (final chunk
              in ZLibDecoder(raw: true).bind(Stream.value(content))) {
            if (builder.length + chunk.length > uncompressedSize) {
              throw  FormatException(appL10n.flowAPKManifestDecompressedSizeMismatch);
            }
            builder.add(chunk);
          }
          xml = builder.takeBytes();
        } else {
          throw  FormatException(appL10n.flowUnsupportedAPKManifestCompression);
        }
        if (xml.length != uncompressedSize)
          throw  FormatException(appL10n.flowIncompleteAPKManifestData);
        return fromManifest(xml);
      }
      offset = next;
    }
    throw  FormatException(appL10n.flowAPKHasNoVersionManifest);
  }

  static ApkPublishedVersion fromManifest(Uint8List bytes) {
    try {
      final data = ByteData.sublistView(bytes);
      int u16(int offset) => data.getUint16(offset, Endian.little);
      int u32(int offset) => data.getUint32(offset, Endian.little);
      if (bytes.length < 8 || u16(0) != 3 || u32(4) != bytes.length) {
        throw  FormatException(appL10n.flowInvalidBinaryAPKManifest);
      }
      final strings = <String>[];
      String stringAt(int index) {
        if (index < 0 || index >= strings.length)
          throw  FormatException(appL10n.flowInvalidAPKManifestStringIndex);
        return strings[index];
      }

      var offset = u16(2);
      while (offset + 8 <= bytes.length) {
        final kind = u16(offset),
            header = u16(offset + 2),
            size = u32(offset + 4);
        if (header < 8 || size < header || offset + size > bytes.length) {
          throw  FormatException(appL10n.flowInvalidAPKManifestChunk);
        }
        if (kind == 1) {
          final count = u32(offset + 8),
              utf8Strings = u32(offset + 16) & 0x100 != 0;
          final start = offset + u32(offset + 20);
          if (count > 100000 || offset + header + count * 4 > offset + size) {
            throw  FormatException(appL10n.flowInvalidAPKManifestStringTable);
          }
          for (var i = 0; i < count; i++) {
            var p = start + u32(offset + header + i * 4);
            int length8() {
              final first = bytes[p++];
              return first & 0x80 != 0
                  ? ((first & 0x7f) << 8) | bytes[p++]
                  : first;
            }

            int length16() {
              final first = u16(p);
              p += 2;
              if (first & 0x8000 == 0) return first;
              final second = u16(p);
              p += 2;
              return ((first & 0x7fff) << 16) | second;
            }

            if (utf8Strings) {
              length8();
              final length = length8();
              strings.add(utf8.decode(bytes.sublist(p, p + length)));
            } else {
              final length = length16();
              strings.add(String.fromCharCodes(
                  [for (var j = 0; j < length; j++) u16(p + j * 2)]));
            }
          }
        } else if (kind == 0x102 && stringAt(u32(offset + 20)) == 'manifest') {
          final values = <String, Object>{};
          final attributeSize = u16(offset + 26), count = u16(offset + 28);
          if (attributeSize < 20) throw  FormatException(appL10n.flowInvalidAPKManifestAttribute);
          for (var i = 0; i < count; i++) {
            final p = offset + 16 + u16(offset + 24) + i * attributeSize;
            if (p + 20 > offset + size)
              throw  FormatException(appL10n.flowAPKManifestAttributeOutOfBounds);
            final name = stringAt(u32(p + 4)),
                raw = u32(p + 8),
                value = u32(p + 16);
            values[name] = raw != 0xffffffff
                ? stringAt(raw)
                : bytes[p + 15] == 3
                    ? stringAt(value)
                    : value;
          }
          final version = values['versionName']?.toString() ?? '';
          final packageName = values['package']?.toString() ?? '';
          final code = int.tryParse('${values['versionCode']}') ?? 0;
          final major = int.tryParse('${values['versionCodeMajor']}') ?? 0;
          final build = (major << 32) | code;
          if (version.isEmpty || packageName.isEmpty || build <= 0) {
            throw  FormatException(appL10n.flowAPKLacksValidVersionInformation);
          }
          return ApkPublishedVersion(packageName, version, build);
        }
        offset += size;
      }
      throw  FormatException(appL10n.flowAPKHasNoAppVersionInformation);
    } on RangeError {
      throw  FormatException(appL10n.flowAPKManifestDataOutOfBounds);
    }
  }
}
