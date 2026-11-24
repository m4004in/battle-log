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
  testWidgets('상대 덱이 4열 그리드로 그려지고 이름은 스프라이트로만 분류된다', (tester) async {
    for (final size in [const Size(375, 812), const Size(430, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // 첫 스프라이트가 모두 다른 상대 덱 6종
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

      // 4열 그리드 확인
      final grid = tester.widget<GridView>(find.byType(GridView));
      final d = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(d.crossAxisCount, 4);

      // 첫 줄 4개는 같은 높이에서 시작, 5번째는 다음 줄
      final tops = _cardTops(tester);
      expect(tops.length, 6);
      expect(tops[0].dy, tops[1].dy);
      expect(tops[1].dy, tops[2].dy);
      expect(tops[2].dy, tops[3].dy);
      expect(tops[4].dy, greaterThan(tops[0].dy));
    }
  });

  testWidgets('묶음 박스 UI 없이 카드만 4열로 나열된다', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final records = <TournamentRecord>[
      _rec([10, 20, 30], MatchResult.win, 1),
      _rec([10, 21, 31], MatchResult.win, 2),
      _rec([70, 71, 72], MatchResult.win, 3),
    ];

    await tester.pumpWidget(MaterialApp(home: WinRateScreen(records: records)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('opp-cluster-0')), findsNothing);
    final grid = tester.widget<GridView>(find.byType(GridView));
    final d = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(d.crossAxisCount, 4);
  });

  test('첫 번째 스프라이트가 같으면 묶여서 연속으로 나온다', () {
    // 판수: a(10) c(5) b(1) 순이지만, a 와 b 는 첫 스프라이트가 10 으로 같다
    final a = _deck('a', [10, 20, 30], wins: 10);
    final c = _deck('c', [40, 41, 42], wins: 5);
    final b = _deck('b', [10, 55, 56], wins: 1);

    final ordered = [a, c, b]..sort(compareDeckStat);
    expect(ordered.map((d) => d.signature).toList(), ['a', 'c', 'b']);

    final out = sortByFirstSprite(ordered);
    final ia = out.indexWhere((d) => d.signature == 'a');
    final ib = out.indexWhere((d) => d.signature == 'b');
    expect((ia - ib).abs(), 1, reason: 'a 와 b 는 첫 스프라이트가 같아 이웃');
  });

  test('판수 순서보다 첫 스프라이트 묶기가 우선한다', () {
    // 판수순: a(5) b(4) c(1) 이지만 a, c 첫 스프라이트가 같아서 a, c 가 붙는다
    final a = _deck('a', [10, 20, 30], wins: 5);
    final b = _deck('b', [30, 20, 40], wins: 4);
    final c = _deck('c', [10, 50, 51], wins: 1);

    final ordered = [a, b, c]..sort(compareDeckStat);
    expect(ordered.map((d) => d.signature).toList(), ['a', 'b', 'c']);

    final out = sortByFirstSprite(ordered);
    expect(out.map((d) => d.signature).toList(), ['a', 'c', 'b']);
  });

  test('첫 스프라이트 없는 덱은 맨 뒤로 간다', () {
    final a = _deck('a', [10, 20, 30], wins: 3);
    final none = _deck('none', const [], wins: 9);
    final b = _deck('b', [10, 40, 41], wins: 1);

    final out = sortByFirstSprite([none, a, b]);
    expect(out.last.signature, 'none');
    expect(out.take(2).map((d) => d.signature), ['a', 'b']);
  });

  test('실제 기록에서도 첫 스프라이트가 같은 상대 덱이 옆에 온다', () {
    final records = <TournamentRecord>[
      for (var i = 0; i < 3; i++) _rec([10, 20, 30], MatchResult.win, i),
      for (var i = 0; i < 4; i++) _rec([70, 71, 72], MatchResult.win, 10 + i),
      _rec([10, 21, 31], MatchResult.lose, 20),
    ];

    final list = WinRateReport.from(records).allOpponentList;
    expect(list.length, 3);
    // 첫 스프라이트 10 인 두 덱이 연속
    final tens = [
      for (var i = 0; i < list.length; i++)
        if (list[i].pokemonIds.first == 10) i
    ];
    expect(tens.length, 2);
    expect((tens[0] - tens[1]).abs(), 1);
  });
}
