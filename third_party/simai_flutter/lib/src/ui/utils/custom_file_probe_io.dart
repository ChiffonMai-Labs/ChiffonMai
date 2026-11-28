import 'dart:io';

bool customFileExistsSync(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return false;
  return File(trimmed).existsSync();
}
