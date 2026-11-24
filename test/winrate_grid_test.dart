import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:battle_log/models/tournament_record.dart';
import 'package:battle_log/screens/winrate_screen.dart';

TournamentRecord _rec(List<int> opp, MatchResult res, int i) =>
    TournamentRecord(
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
  testWidgets('상대 덱이 4열 그리드로 그려지고 이름은 스프라이트로만 분류된다', (tester) async {
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

      await tester
          .pumpWidget(MaterialApp(home: WinRateScreen(records: records)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull, reason: '$size 오버플로 없음');

      // 직접 쓴 상대 덱 이름은 화면에 나오지 않는다
      expect(find.text('상대가 직접 쓴 이름'), findsNothing);

      // 4열 그리드 확인
      final grid = tester.widget<GridView>(find.byType(GridView));
      final d = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(d.crossAxisCount, 4);
    }
  });

  test('스프라이트가 겹치는 덱끼리 서로 이웃하게 정렬된다', () {
    DeckStat deck(String key, List<int> ids, int wins) => DeckStat(
          signature: key,
          pokemonIds: ids,
          deckName: '',
        )..wins = wins;

    // 많이 만난 순: a(5) b(4) c(3) d(2) e(1)
    final a = deck('a', [10, 20, 30], 5);
    final b = deck('b', [10, 21, 31], 4);
    final c = deck('c', [50, 51, 52], 3);
    final d = deck('d', [10, 20, 33], 2);
    final e = deck('e', [60, 61, 62], 1);

    final out = clusterBySpriteOverlap([a, b, c, d, e]);

    expect(out.length, 5);
    expect(out.map((d) => d.signature).toSet(), {'a', 'b', 'c', 'd', 'e'});

    final where = {
      for (var i = 0; i < out.length; i++) out[i].signature: i,
    };

    // 같은 스프라이트를 공유하는 a, b, d 는 연속으로 붙어 있어야 한다
    final idx = [where['a']!, where['b']!, where['d']!]..sort();
    expect(idx[1] - idx[0], 1);
    expect(idx[2] - idx[1], 1);

    // 순위가 가장 높은 덱이 그룹의 머리, 겹치는 개수가 가장 많은 d 가 바로 뒤
    expect(out.first.signature, 'a');
    expect(out[1].signature, 'd');
  });

  test('실제 기록에서도 겹치는 상대 덱이 이웃으로 온다', () {
    final records = <TournamentRecord>[
      // [10,20,30] 을 3번, [10,20,31] 을 2번, [10,20,32] 를 1번, [70,71,72] 를 2번
      for (var i = 0; i < 3; i++) _rec([10, 20, 30], MatchResult.win, i),
      for (var i = 0; i < 2; i++) _rec([10, 20, 31], MatchResult.lose, 10 + i),
      _rec([10, 20, 32], MatchResult.win, 20),
      for (var i = 0; i < 2; i++) _rec([70, 71, 72], MatchResult.win, 30 + i),
    ];

    final list = WinRateReport.from(records).allOpponentList;
    // [10,20,30] 계열 3종이 앞에서 연속으로 붙어 있고, 무관한 [70,71,72] 는 뒤
    expect(list.length, 4);
    final firstThree = list.take(3).map((d) => d.pokemonIds.toSet()).toList();
    for (final s in firstThree) {
      expect(s.contains(10), isTrue);
      expect(s.contains(20), isTrue);
    }
    expect(list.last.pokemonIds.toSet().contains(70), isTrue);
  });
}
