import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('battlelog/image_saver');

/// 네이티브(Android/iOS) 환경에서 PNG 바이트를 갤러리에 실제 저장한다.
Future<bool> savePngImage(Uint8List bytes, String fileName) async {
  try {
    final ok = await _channel.invokeMethod<bool>('savePng', <String, Object>{
      'bytes': bytes,
      'fileName': fileName,
    });
    return ok ?? false;
  } catch (_) {
    return false;
  }
}
