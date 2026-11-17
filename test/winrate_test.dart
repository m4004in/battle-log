import 'package:flutter_test/flutter_test.dart';
import 'package:battle_log/models/tournament_record.dart';
import 'package:battle_log/screens/winrate_screen.dart';

TournamentRecord rec({
  required List<int> myIds,
  String myName = '',
  required List<List<int>> oppIds,
  required List<MatchResult> results,
}) {
  return TournamentRecord(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    date: DateTime(2025, 1, 1),
    myDeckName: myName,
    myPokemonIds: myIds,
    rounds: [
      for (var i = 0; i < oppIds.length; i++)
        RoundRecord(
          opponentPokemonIds: oppIds[i],
          games: [MatchGame(result: results[i])],
        ),
    ],
  );
}

void main() {
  test('내 덱별 상대 승률 집계', () {
    final records = [
      // 덱 A(스프라이트 [25,6,9]) vs 상대 [1,2,3] 2승, 상대 [4,5,6] 1패
      rec(myIds: [25, 6, 9], oppIds: [[1, 2, 3], [1, 2, 3], [4, 5, 6]], results: [MatchResult.win, MatchResult.win, MatchResult.lose]),
      // 같은 덱 A인데 포켓몬 순서만 다름 → 같은 덱으로 묶여야 함
      rec(myIds: [9, 25, 6], oppIds: [[1, 2, 3]], results: [MatchResult.lose]),
      // 덱 B
      rec(myIds: [150, 151], oppIds: [[1, 2, 3]], results: [MatchResult.win]),
      // 결과 없는 라운드는 집계 제외
      rec(myIds: [150, 151], oppIds: [[7]], results: [MatchResult.none]),
    ];
    final r = WinRateReport.from(records);
    expect(r.total, 5);
    expect(r.wins, 3);
    expect(r.myDecks.length, 2, reason: '내 덱 2종으로 묶여야 함');

    final deckA = r.myDecks.firstWhere((d) => d.pokemonIds.contains(25));
    expect(deckA.opponents.length, 2);
    final opp123 = deckA.opponents.values.firstWhere((o) => o.pokemonIds.contains(1));
    expect(opp123.wins, 2);
    expect(opp123.loses, 1);
    expect(deckA.wins, 2);
    expect(deckA.loses, 2);

    final deckB = r.myDecks.firstWhere((d) => d.pokemonIds.contains(150));
    expect(deckB.wins, 1);

    // 전체 상대 합산
    final all1 = r.allOpponents.values.firstWhere((o) => o.pokemonIds.contains(1));
    expect(all1.total, 4);
  });

  test('덱 이름만 있고 포켓몬 없으면 이름으로 구분', () {
    final r = WinRateReport.from([
      rec(myIds: [], myName: '리자몽덱', oppIds: [[1]], results: [MatchResult.win]),
      rec(myIds: [], myName: '리자몽덱', oppIds: [[1]], results: [MatchResult.lose]),
      rec(myIds: [], myName: '피카츄덱', oppIds: [[1]], results: [MatchResult.win]),
    ]);
    expect(r.myDecks.length, 2);
    expect(deckTitle('리자몽덱', []), '리자몽덱');
  });

  test('이름 없고 포켓몬만 있으면 포켓몬 이름으로 표시', () {
    expect(deckTitle('', [25, 6]), '피카츄 · 리자몽');
  });
}
