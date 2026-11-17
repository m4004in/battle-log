import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battle_log/providers/tournament_provider.dart';
import 'package:battle_log/screens/home_screen.dart';
import 'package:battle_log/screens/winrate_screen.dart';
import 'package:battle_log/theme/app_theme.dart';

void main() {
  testWidgets('상단 승률 버튼을 누르면 승률 화면이 열린다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final provider = TournamentProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<TournamentProvider>.value(
        value: provider,
        child: ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(),
          child: const MaterialApp(home: HomeScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('승률'), findsWidgets);
    await tester.tap(find.text('승률').first);
    await tester.pumpAndSettle();

    expect(find.byType(WinRateScreen), findsOneWidget);
    expect(find.text('승률을 낼 기록이 아직 없어요'), findsOneWidget);
  });
}
