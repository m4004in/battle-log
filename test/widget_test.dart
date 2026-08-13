import 'package:flutter_test/flutter_test.dart';
import 'package:battle_log/main.dart';

void main() {
  testWidgets('BattleLog app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BattleLogApp());
    expect(find.text('Battle Log'), findsOneWidget);
  });
}
