import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// PNG 바이트를 브라우저 다운로드로 실제 저장한다.
Future<bool> savePngImage(Uint8List bytes, String fileName) async {
  try {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'image/png'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    Future.delayed(const Duration(seconds: 10), () {
      web.URL.revokeObjectURL(url);
    });
    return true;
  } catch (_) {
    return false;
  }
}
