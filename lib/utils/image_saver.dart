export 'image_saver_stub.dart'
    if (dart.library.js_interop) 'image_saver_web.dart'
    if (dart.library.io) 'image_saver_io.dart';
