import 'dart:convert';
import 'package:archive/archive.dart';
import '../models/record_folder.dart';
import '../models/tournament_record.dart';

/// 백업 코드 인코딩/디코딩.
/// BLOG2: 항목 이름을 빼고 배열로 압축한 뒤 deflate 압축 (짧음)
/// BLOG1: 예전 방식(압축 없는 JSON) - 복원만 지원
class BackupCodec {
  static const String prefix2 = 'BLOG2.';
  static const String prefix1 = 'BLOG1.';

  static String encode(
      List<TournamentRecord> records, List<RecordFolder> folders) {
    final fIdx = {for (var i = 0; i < folders.length; i++) folders[i].id: i};
    final data = [
      folders.map((f) => f.name).toList(),
      records.map((r) {
        return [
          r.id,
          r.tournamentName,
          r.date.millisecondsSinceEpoch ~/ 60000,
          r.myDeckName,
          r.myPokemonIds,
          r.rounds
              .map((o) => [
                    o.opponentDeckName,
                    o.opponentPokemonIds,
                    o.games.map((g) => g.result.index).join(),
                  ])
              .toList(),
          r.createdAt.millisecondsSinceEpoch ~/ 60000,
          fIdx[r.folderId] ?? -1,
        ];
      }).toList(),
    ];
    final bytes = utf8.encode(jsonEncode(data));
    final packed = const ZLibEncoder().encode(bytes, level: 9);
    return prefix2 + base64Url.encode(packed).replaceAll('=', '');
  }

  /// 실패하면 예외를 던진다.
  static ({List<TournamentRecord> records, List<RecordFolder> folders}) decode(
      String raw) {
    final code = raw.replaceAll(RegExp(r'\s+'), '');
    if (code.startsWith(prefix2)) {
      final body = code.substring(prefix2.length);
      final packed = base64Url.decode(base64Url.normalize(body));
      final text = utf8.decode(const ZLibDecoder().decodeBytes(packed));
      final data = jsonDecode(text) as List<dynamic>;
      final folders = <RecordFolder>[
        for (var i = 0; i < (data[0] as List).length; i++)
          RecordFolder(
              id: 'f${i + 1}_${DateTime.now().microsecondsSinceEpoch}',
              name: data[0][i] as String),
      ];
      final records = (data[1] as List<dynamic>).map((e) {
        final r = e as List<dynamic>;
        final fi = r[7] as int;
        return TournamentRecord(
          id: r[0] as String,
          tournamentName: r[1] as String,
          date: DateTime.fromMillisecondsSinceEpoch((r[2] as int) * 60000),
          myDeckName: r[3] as String,
          myPokemonIds: List<int>.from(r[4] as List),
          rounds: (r[5] as List<dynamic>).map((o) {
            final ro = o as List<dynamic>;
            final games = (ro[2] as String).split('').map((c) {
              final i = int.tryParse(c) ?? 3;
              return MatchGame(
                  result: i < MatchResult.values.length
                      ? MatchResult.values[i]
                      : MatchResult.none);
            }).toList();
            return RoundRecord(
              opponentDeckName: ro[0] as String,
              opponentPokemonIds: List<int>.from(ro[1] as List),
              games: games.isEmpty ? [MatchGame()] : games,
            );
          }).toList(),
          createdAt: DateTime.fromMillisecondsSinceEpoch((r[6] as int) * 60000),
          folderId: fi >= 0 && fi < folders.length ? folders[fi].id : null,
        );
      }).toList();
      return (records: records, folders: folders);
    }
    if (code.startsWith(prefix1)) {
      final body = code.substring(prefix1.length);
      final text = utf8.decode(base64Url.decode(base64Url.normalize(body)));
      final data = jsonDecode(text) as Map<String, dynamic>;
      if (data['app'] != 'battlelog') {
        throw const FormatException('not battlelog');
      }
      return (
        records: (data['records'] as List<dynamic>)
            .map((j) =>
                TournamentRecord.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList(),
        folders: (data['folders'] as List<dynamic>? ?? [])
            .map((j) =>
                RecordFolder.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList(),
      );
    }
    throw const FormatException('bad prefix');
  }
}
