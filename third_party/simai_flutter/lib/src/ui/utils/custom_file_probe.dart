import 'custom_file_probe_io.dart'
    if (dart.library.html) 'custom_file_probe_stub.dart';

bool customFileExists(String path) => customFileExistsSync(path);
