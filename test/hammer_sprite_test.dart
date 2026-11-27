
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:battle_log/widgets/pokemon_picker_dialog.dart';

void main() {
  testWidgets('스프라이트 영역 스크롤/렌더 오류 없음', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PokemonPickerDialog(selectedIds: [], maxSelect: 3)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // 첫 화면에 보이는 카드들
    final texts = find.byType(Text);
    expect(texts.evaluate().isNotEmpty, isTrue);

    // 0번 카드(해머) 라벨 존재
    expect(find.text('해머'), findsOneWidget);

    // 로딩 중 예외 없음
    expect(tester.takeException(), isNull);

    // 아래로 스크롤해도 예외 없음
    await tester.drag(find.byType(GridView).first, const Offset(0, -600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    // 검색도 정상
    await tester.enterText(find.byType(TextField).first, '피카');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('피카츄'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
