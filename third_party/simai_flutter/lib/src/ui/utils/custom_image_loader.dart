import 'dart:ui' as ui;

import 'custom_image_loader_io.dart'
    if (dart.library.html) 'custom_image_loader_stub.dart';

Future<ui.Image?> decodeCustomNoteImageFile(String path) =>
    decodeCustomNoteImageFileImpl(path);
