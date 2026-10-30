import 'dart:typed_data';

/// 웹이 아닌 환경에서는 지원하지 않음 (false 반환)
Future<bool> savePngImage(Uint8List bytes, String fileName) async => false;
