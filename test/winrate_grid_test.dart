import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:battle_log/models/tournament_record.dart';
import 'package:battle_log/screens/winrate_screen.dart';

TournamentRecord _rec(List<int> opp, MatchResult res, int i) => TournamentRecord(
      id: 'id$i',
      date: DateTime(2025, 9, 1),
      tournamentName: '대회$i',
      myPokemonIds: const [25, 6, 9],
      rounds: [
        RoundRecord(
          opponentPokemonIds: opp,
          opponentDeckName: '상대가 직접 쓴 이름',
          games: [MatchGame(result: res)],
        ),
      ],
    );

void main() {
  testWidgets('상대 덱이 3열 그리드로 그려지고 이름은 스프라이트로만 분류된다',
      (tester) async {
    for (final size in [const Size(375, 812), const Size(430, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // 7종 상대 덱
      final records = <TournamentRecord>[];
      for (var i = 0; i < 7; i++) {
        records.add(_rec([10 + i, 20 + i, 30 + i], MatchResult.win, i));
      }
      // 같은 스프라이트를 이름만 다르게 2번 → 하나로 합쳐져야 함
      records.add(_rec([10, 20, 30], MatchResult.lose, 90));

      await tester.pumpWidget(MaterialApp(home: WinRateScreen(records: records)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull, reason: '$size 오버플로 없음');

      // 직접 쓴 상대 덱 이름은 화면에 나오지 않는다
      expect(find.text('상대가 직접 쓴 이름'), findsNothing);

      // 3열 그리드 확인
      final grid = tester.widget<GridView>(find.byType(GridView));
      final d = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(d.crossAxisCount, 3);
    }
  });
}
