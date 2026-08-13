import 'dart:convert';

enum MatchResult { win, lose, draw, none }

class MatchGame {
  // 단판/다판 내 개별 게임 결과
  MatchResult result;
  MatchGame({this.result = MatchResult.none});

  Map<String, dynamic> toJson() => {'result': result.index};
  factory MatchGame.fromJson(Map<String, dynamic> json) {
    final idx = json['result'] as int? ?? 0;
    // 안전하게 인덱스 범위 체크
    final result = idx < MatchResult.values.length
        ? MatchResult.values[idx]
        : MatchResult.none;
    return MatchGame(result: result);
  }
}

class RoundRecord {
  String opponentDeckName;
  List<int> opponentPokemonIds; // 최대 3마리
  List<MatchGame> games; // 게임들 (최소 1, 최대 3)

  RoundRecord({
    this.opponentDeckName = '',
    List<int>? opponentPokemonIds,
    List<MatchGame>? games,
  })  : opponentPokemonIds = opponentPokemonIds ?? [],
        games = games ?? [MatchGame()];

  // 라운드 최종 결과
  MatchResult get roundResult {
    int wins = games.where((g) => g.result == MatchResult.win).length;
    int loses = games.where((g) => g.result == MatchResult.lose).length;
    int draws = games.where((g) => g.result == MatchResult.draw).length;
    if (wins > loses && wins > draws) return MatchResult.win;
    if (loses > wins && loses > draws) return MatchResult.lose;
    // 승=패 이거나 무승부가 지배적인 경우
    if (draws > 0 && wins == loses) return MatchResult.draw;
    if (wins == loses && wins > 0) return MatchResult.draw;
    return MatchResult.none;
  }

  Map<String, dynamic> toJson() => {
        'opponentDeckName': opponentDeckName,
        'opponentPokemonIds': opponentPokemonIds,
        'games': games.map((g) => g.toJson()).toList(),
      };

  factory RoundRecord.fromJson(Map<String, dynamic> json) => RoundRecord(
        opponentDeckName: json['opponentDeckName'] ?? '',
        opponentPokemonIds: List<int>.from(json['opponentPokemonIds'] ?? []),
        games: (json['games'] as List<dynamic>? ?? [MatchGame().toJson()])
            .map((g) => MatchGame.fromJson(g))
            .toList(),
      );
}

class TournamentRecord {
  String id;
  String tournamentName;
  DateTime date;
  String myDeckName;
  List<int> myPokemonIds; // 최대 3마리
  List<RoundRecord> rounds;
  DateTime createdAt;

  TournamentRecord({
    required this.id,
    this.tournamentName = '',
    required this.date,
    this.myDeckName = '',
    List<int>? myPokemonIds,
    List<RoundRecord>? rounds,
    DateTime? createdAt,
  })  : myPokemonIds = myPokemonIds ?? [],
        rounds = rounds ?? [],
        createdAt = createdAt ?? DateTime.now();

  int get totalWins =>
      rounds.where((r) => r.roundResult == MatchResult.win).length;
  int get totalLoses =>
      rounds.where((r) => r.roundResult == MatchResult.lose).length;
  int get totalDraws =>
      rounds.where((r) => r.roundResult == MatchResult.draw).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tournamentName': tournamentName,
        'date': date.toIso8601String(),
        'myDeckName': myDeckName,
        'myPokemonIds': myPokemonIds,
        'rounds': rounds.map((r) => r.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory TournamentRecord.fromJson(Map<String, dynamic> json) =>
      TournamentRecord(
        id: json['id'] ?? '',
        tournamentName: json['tournamentName'] ?? '',
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        myDeckName: json['myDeckName'] ?? '',
        myPokemonIds: List<int>.from(json['myPokemonIds'] ?? []),
        rounds: (json['rounds'] as List<dynamic>? ?? [])
            .map((r) => RoundRecord.fromJson(r))
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );

  String toJsonString() => jsonEncode(toJson());
  factory TournamentRecord.fromJsonString(String jsonStr) =>
      TournamentRecord.fromJson(jsonDecode(jsonStr));
}
