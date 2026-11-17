import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:battle_log/models/tournament_record.dart';
import 'package:battle_log/widgets/coverflow_logs.dart';

TournamentRecord _rec(int i) => TournamentRecord(
      id: 'id$i',
      date: DateTime(2025, 9, 1).add(Duration(days: i)),
      tournamentName: '대회 $i',
      myPokemonIds: const [25, 6, 9],
      rounds: [
        RoundRecord(opponentPokemonIds: const [1, 2, 3], games: [
          MatchGame(result: MatchResult.win),
        ]),
      ],
    );

void main() {
  testWidgets('커버플로우가 카드와 캡션을 그리고 탭하면 확대 오버레이가 열린다', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final records = [for (var i = 0; i < 4; i++) _rec(i)];
    TournamentRecord? opened;
    Rect? openedRect;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CoverflowLogs(
          records: records,
          cardBuilder: (c, r) => SizedBox(
            height: 400,
            child: Center(child: Text('카드 ${r.tournamentName}')),
          ),
          onOpen: (r, rect, card) {
            opened = r;
            openedRect = rect;
          },
        ),
      ),
    ));
    await tester.pump();

    // 캡션(대회 이름) 표시
    expect(find.text('대회 0'), findsOneWidget);

    // 중앙 카드 탭 → onOpen 호출
    await tester.tap(find.text('카드 대회 0').first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(opened?.id, 'id0');
    expect(openedRect, isNotNull);
    expect(openedRect!.width, greaterThan(0));
  });

  testWidgets('확대 오버레이에 뒤로가기 버튼이 있고 누르면 닫힌다', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    late BuildContext homeCtx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (ctx) {
        homeCtx = ctx;
        return const Scaffold(body: Text('홈'));
      }),
    ));

    showExpandedLog(
      homeCtx,
      card: const SizedBox(height: 400, child: Text('확대 카드')),
      from: const Rect.fromLTWH(20, 100, 200, 400),
      onEdit: (_) {},
    );
    await tester.pumpAndSettle();

    expect(find.text('확대 카드'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('확대 카드'), findsNothing);
    expect(find.text('홈'), findsOneWidget);
  });
}
