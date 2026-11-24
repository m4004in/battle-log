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

DeckStat _deck(String key, List<int> ids, {int wins = 1}) =>
    DeckStat(signature: key, pokemonIds: ids, deckName: '')..wins = wins;

const _cardKeyPrefix = 'opp-card-';

List<Offset> _cardTops(WidgetTester tester) {
  final cards = find.byWidgetPredicate((w) =>
      w.key is ValueKey<String> &&
      (w.key as ValueKey<String>).value.startsWith(_cardKeyPrefix));
  return [
    for (var i = 0; i < tester.widgetList(cards).length; i++)
      tester.getTopLeft(cards.at(i)),
  ];
}

void main() {
  testWidgets('상대 덱이 4열로 그려지고 이름은 스프라이트로만 분류된다', (tester) async {
    for (final size in [const Size(375, 812), const Size(430, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // 서로 겹치지 않는 상대 덱 6종 → 모두 낱개 카드
      final records = <TournamentRecord>[];
      for (var i = 0; i < 6; i++) {
        records.add(_rec([10 + i, 20 + i, 30 + i], MatchResult.win, i));
      }

      await tester
          .pumpWidget(MaterialApp(home: WinRateScreen(records: records)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull, reason: '$size 오버플로 없음');
      expect(find.text('상대가 직접 쓴 이름'), findsNothing);

      final tops = _cardTops(tester);
      expect(tops.length, 6);
      // 첫 줄 4개는 같은 높이에서 시작
      expect(tops[0].dy, tops[1].dy);
      expect(tops[1].dy, tops[2].dy);
      expect(tops[2].dy, tops[3].dy);
      // 5번째는 다음 줄
      expect(tops[4].dy, greaterThan(tops[0].dy));
    }
  });

  testWidgets('겹치는 덱은 한 묶음 박스로 표기된다', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final records = <TournamentRecord>[
      // [10,20,30] 계열 2종 (겹침) + 무관한 덱 1종
      _rec([10, 20, 30], MatchResult.win, 1),
      _rec([10, 20, 31], MatchResult.win, 2),
      _rec([70, 71, 72], MatchResult.win, 3),
    ];

    await tester.pumpWidget(MaterialApp(home: WinRateScreen(records: records)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('opp-cluster-0')), findsOneWidget);
    expect(find.byKey(const Key('opp-cluster-1')), findsOneWidget);
  });

  testWidgets('한 묶음이 4개를 넘어도 좁은 화면에서 넘치지 않는다', (tester) async {
    for (final size in [const Size(375, 812), const Size(360, 740)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // 모두 10번 스프라이트를 공유하는 6종 → 한 묶음이 2줄
      final records = <TournamentRecord>[
        for (var i = 0; i < 6; i++) _rec([10, 40 + i, 60 + i], MatchResult.win, i),
        _rec([90, 91, 92], MatchResult.win, 50),
      ];

      await tester
          .pumpWidget(MaterialApp(home: WinRateScreen(records: records)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull, reason: '$size 넘침 없음');
      expect(find.byKey(const Key('opp-cluster-0')), findsOneWidget);
    }
  });

  test('승률/판수와 무관하게 스프라이트가 1개라도 겹치면 같은 묶음이 된다', () {
    // a: 10승(가장 많이 만남) / b: 1승만, a와 스프라이트 1개 겹침
    final a = _deck('a', [10, 20, 30], wins: 10);
    final b = _deck('b', [10, 55, 56], wins: 1);
    // c: 5승, 완전히 무관
    final c = _deck('c', [40, 41, 42], wins: 5);

    final ordered = [a, c, b]..sort(compareDeckStat);
    final clusters = clusterOpponents(ordered);

    // a 와 b 는 같은 묶음 (판수 차이와 무관)
    final groupWithA =
        clusters.firstWhere((cl) => cl.decks.any((d) => d.signature == 'a'));
    expect(groupWithA.decks.map((d) => d.signature).toSet(), {'a', 'b'});
    expect(groupWithA.isGrouped, isTrue);
    expect(groupWithA.sharedIds, contains(10));

    // c 는 혼자
    final groupWithC =
        clusters.firstWhere((cl) => cl.decks.any((d) => d.signature == 'c'));
    expect(groupWithC.decks.length, 1);
    expect(groupWithC.isGrouped, isFalse);

    // 납작하게 편 목록에서도 a, b 가 이웃
    final flat = clusterBySpriteOverlap(ordered);
    final ia = flat.indexWhere((d) => d.signature == 'a');
    final ib = flat.indexWhere((d) => d.signature == 'b');
    expect((ia - ib).abs(), 1);
  });

  test('실제 기록에서도 겹치는 상대 덱이 한 묶음으로 모인다', () {
    final records = <TournamentRecord>[
      for (var i = 0; i < 3; i++) _rec([10, 20, 30], MatchResult.win, i),
      for (var i = 0; i < 2; i++) _rec([10, 20, 31], MatchResult.lose, 10 + i),
      _rec([10, 20, 32], MatchResult.win, 20),
      for (var i = 0; i < 2; i++) _rec([70, 71, 72], MatchResult.win, 30 + i),
    ];

    final clusters = WinRateReport.from(records).allOpponentClusters;
    expect(clusters.length, 2);

    final grouped = clusters.firstWhere((c) => c.isGrouped);
    expect(grouped.decks.length, 3);
    for (final d in grouped.decks) {
      expect(d.pokemonIds.contains(10), isTrue);
      expect(d.pokemonIds.contains(20), isTrue);
    }
    expect(clusters.last.decks.single.pokemonIds.contains(70), isTrue);
  });
}
