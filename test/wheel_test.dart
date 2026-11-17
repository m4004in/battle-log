import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:battle_log/widgets/wheel_list.dart';

void main() {
  testWidgets('물레방아 리스트가 스크롤되고 항목이 변형된다', (tester) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WheelList(
          itemCount: 12,
          padding: const EdgeInsets.all(12),
          itemBuilder: (c, i) => SizedBox(
            height: 120,
            child: Center(child: Text('항목 $i')),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('항목 0'), findsOneWidget);

    await tester.drag(find.text('항목 3'), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('항목 0'), findsWidgets);
  });
}
