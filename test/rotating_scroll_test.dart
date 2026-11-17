import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:battle_log/widgets/rotating_scroll.dart';

void main() {
  testWidgets('회전 스크롤이 항목을 그리고 스크롤해도 예외가 없다', (tester) async {
    tester.view.physicalSize = const Size(400, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RotatingScroll(
          itemCount: 10,
          padding: const EdgeInsets.all(12),
          itemBuilder: (c, i) => SizedBox(
            height: 130,
            child: Center(child: Text('카드 $i')),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('카드 0'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(find.text('카드 2'), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.drag(find.text('카드 0'), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
