// platform_utils.dart
export 'platform_utils_stub.dart'
    if (dart.library.io) 'platform_utils_io.dart'
    if (dart.library.js_interop) 'platform_utils_web.dart';
