import 'dart:js_interop';

@JS('blBootReady')
external JSFunction? get _blBootReady;

/// HTML 부팅 스플래시를 걷으라고 알린다.
/// 폰트가 모두 등록된 뒤, 첫 프레임 바로 다음에 호출된다.
void signalBootReady() {
  try {
    _blBootReady?.callAsFunction();
  } catch (_) {
    // 신호 실패는 앱 동작에 영향 없음
  }
}
