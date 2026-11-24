import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:battle_log/models/tournament_record.dart';
import 'package:battle_log/screens/winrate_screen.dart';

TournamentRecord _rec({
  required String myName,
  required List<int> myIds,
  required List<(String, List<int>, MatchResult)> rounds,
  required DateTime date,
}) {
  return TournamentRecord(
    id: 'r${date.month}${date.day}$myName${myIds.join()}${rounds.length}',
    date: date,
    myDeckName: myName,
    myPokemonIds: myIds,
    rounds: [
      for (final r in rounds)
        RoundRecord(
          opponentDeckName: r.$1,
          opponentPokemonIds: r.$2,
          games: [MatchGame(result: r.$3)],
        ),
    ],
  );
}

void main() {
  testWidgets('승률 화면이 요약/덱칩/상대카드를 렌더링한다', (tester) async {
    final records = [
      _rec(myName: '', myIds: [25, 6, 9], date: DateTime(2025, 9, 15), rounds: [
        ('', [1, 2, 3], MatchResult.win),
        ('', [1, 2, 3], MatchResult.lose),
        ('물덱', [7, 8, 4], MatchResult.win),
      ]),
      _rec(myName: '', myIds: [6, 9, 25], date: DateTime(2025, 8, 15), rounds: [
        ('', [1, 2, 3], MatchResult.win),
        ('', [4, 7, 8], MatchResult.draw),
      ]),
    ];

    await tester.pumpWidget(MaterialApp(home: WinRateScreen(records: records)));
    await tester.pump();

    expect(find.text('상대 덱별 승률'), findsOneWidget);
    // 3승 1패 1무 → 60.0%
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('판'), findsOneWidget);
    // 내 덱이 1종이면 덱 선택 칩은 숨긴다
    expect(find.text('전체'), findsNothing);
    expect(find.text('내 덱 1'), findsNothing);
    // 상대 덱 카드 (이름 없음 → 스프라이트 포켓몬 이름 3판)
    expect(find.text('이상해씨 · 이상해풀 · 이상해꽃'), findsOneWidget);
    expect(find.text('물덱'), findsNothing);
    // 상대 덱 2종: [1,2,3] / [4,7,8]==[7,8,4] (이름 '물덱'은 분류에 쓰지 않음)
  });

  testWidgets('내 덱 칩을 탭하면 그 덱의 상대 승률로 바뀐다', (tester) async {
    final records = [
      _rec(myName: 'A덱', myIds: [25, 6, 9], date: DateTime(2025, 9, 15), rounds: [
        ('', [1, 2, 3], MatchResult.win),
      ]),
      _rec(myName: 'B덱', myIds: [4, 7, 8], date: DateTime(2025, 8, 15), rounds: [
        ('', [10, 11, 12], MatchResult.lose),
      ]),
    ];

    await tester.pumpWidget(MaterialApp(home: WinRateScreen(records: records)));
    await tester.pump();
    expect(find.text('50%'), findsWidgets); // 요약 + 전체 칩 = 1승 1패

    await tester.tap(find.text('A덱'));
    await tester.pump();

    expect(find.text('100%'), findsWidgets);
    expect(find.text('이상해씨 · 이상해풀 · 이상해꽃'), findsOneWidget);
    expect(find.text('캐터피 · 단데기 · 버터플'), findsNothing);
  });

  testWidgets('기록이 없으면 빈 상태를 보여준다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WinRateScreen(records: [])));
    await tester.pump();
    expect(find.text('승률을 낼 기록이 아직 없어요'), findsOneWidget);
  });
}
