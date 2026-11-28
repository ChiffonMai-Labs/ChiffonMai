import 'dart:io';
import 'dart:ui' as ui;

Future<ui.Image?> decodeCustomNoteImageFileImpl(String path) async {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return null;
  final file = File(trimmed);
  if (!await file.exists()) return null;
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) return null;
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}
