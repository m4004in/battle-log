import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/pokemon_data.dart';
import '../models/tournament_record.dart';
import '../theme/app_theme.dart';
import '../widgets/wheel_list.dart';

/// 덱 한 개의 전적
class DeckStat {
  final String signature; // 내부 구분용 키
  final List<int> pokemonIds;
  String deckName;
  int wins = 0;
  int loses = 0;
  int draws = 0;

  DeckStat({
    required this.signature,
    required this.pokemonIds,
    required this.deckName,
  });

  int get total => wins + loses + draws;
  double get winRate => total == 0 ? 0 : wins / total * 100;
}

/// 내 덱 하나 + 그 덱이 만난 상대 덱들
class MyDeckStat extends DeckStat {
  final Map<String, DeckStat> opponents = {};

  MyDeckStat({
    required super.signature,
    required super.pokemonIds,
    required super.deckName,
  });

  List<DeckStat> get opponentList {
    final list = opponents.values.toList()
      ..sort((a, b) {
        final c = b.total.compareTo(a.total);
        if (c != 0) return c;
        return b.winRate.compareTo(a.winRate);
      });
    return list;
  }
}

/// 기록들을 내 덱 기준으로 묶고, 각 덱의 상대 덱 전적을 계산한다.
class WinRateReport {
  final List<MyDeckStat> myDecks = [];
  int wins = 0;
  int loses = 0;
  int draws = 0;

  WinRateReport();

  int get total => wins + loses + draws;
  double get winRate => total == 0 ? 0 : wins / total * 100;

  /// 상대 전체(모든 내 덱 합산)의 상대 덱별 전적
  final Map<String, DeckStat> allOpponents = {};

  static String _keyOf(List<int> ids, String name) {
    if (ids.isNotEmpty) {
      final sorted = List<int>.from(ids)..sort();
      return 'ids:${sorted.join('-')}';
    }
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isNotEmpty) return 'name:$trimmed';
    return 'unknown';
  }

  factory WinRateReport.from(List<TournamentRecord> records) {
    final report = WinRateReport();
    for (final record in records) {
      for (final round in record.rounds) {
        final result = round.roundResult;
        if (result == MatchResult.none) continue;

        final myKey = _keyOf(record.myPokemonIds, record.myDeckName);
        final myDeck = report.myDecks.firstWhere(
          (d) => d.signature == myKey,
          orElse: () {
            final d = MyDeckStat(
              signature: myKey,
              pokemonIds: record.myPokemonIds,
              deckName: record.myDeckName,
            );
            report.myDecks.add(d);
            return d;
          },
        );
        if (myDeck.deckName.trim().isEmpty && record.myDeckName.trim().isNotEmpty) {
          myDeck.deckName = record.myDeckName;
        }

        final oppKey = _keyOf(round.opponentPokemonIds, round.opponentDeckName);
        final opp = myDeck.opponents.putIfAbsent(
          oppKey,
          () => DeckStat(
            signature: oppKey,
            pokemonIds: round.opponentPokemonIds,
            deckName: round.opponentDeckName,
          ),
        );
        if (opp.deckName.trim().isEmpty &&
            round.opponentDeckName.trim().isNotEmpty) {
          opp.deckName = round.opponentDeckName;
        }

        final allOpp = report.allOpponents.putIfAbsent(
          oppKey,
          () => DeckStat(
            signature: oppKey,
            pokemonIds: round.opponentPokemonIds,
            deckName: round.opponentDeckName,
          ),
        );

        void add(DeckStat target) {
          if (result == MatchResult.win) {
            target.wins++;
          } else if (result == MatchResult.lose) {
            target.loses++;
          } else {
            target.draws++;
          }
        }

        add(myDeck);
        add(opp);
        add(allOpp);

        if (result == MatchResult.win) {
          report.wins++;
        } else if (result == MatchResult.lose) {
          report.loses++;
        } else {
          report.draws++;
        }
      }
    }

    report.myDecks.sort((a, b) {
      final c = b.total.compareTo(a.total);
      if (c != 0) return c;
      return b.winRate.compareTo(a.winRate);
    });
    return report;
  }

  List<DeckStat> get allOpponentList {
    final list = allOpponents.values.toList()
      ..sort((a, b) {
        final c = b.total.compareTo(a.total);
        if (c != 0) return c;
        return b.winRate.compareTo(a.winRate);
      });
    return list;
  }
}

/// 색: 승률에 따라 초록 / 노랑 / 빨강
Color rateColor(double rate) {
  if (rate >= 60) return const Color(0xFF16A34A);
  if (rate >= 45) return const Color(0xFFD97706);
  return const Color(0xFFDC2626);
}

class WinRateScreen extends StatefulWidget {
  final List<TournamentRecord> records;

  const WinRateScreen({super.key, required this.records});

  @override
  State<WinRateScreen> createState() => _WinRateScreenState();
}

class _WinRateScreenState extends State<WinRateScreen> {
  late final WinRateReport _report;
  int _selected = -1; // -1 = 내 덱 전체

  @override
  void initState() {
    super.initState();
    _report = WinRateReport.from(widget.records);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cBg,
      appBar: AppBar(
        backgroundColor: context.cSurface,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          '상대 덱별 승률',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.cInk,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.cLine),
        ),
      ),
      body: _report.total == 0
          ? _buildEmpty(context)
          : Column(
              children: [
                _buildSummary(context),
                _buildDeckSelector(context),
                Expanded(child: _buildOpponentList(context)),
              ],
            ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insights_rounded, size: 44, color: context.cSlate),
          const SizedBox(height: 12),
          Text(
            '승률을 낼 기록이 아직 없어요',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: context.cInk),
          ),
          const SizedBox(height: 6),
          Text(
            '라운드 결과를 남기면 여기에 승률이 쌓입니다',
            style: TextStyle(fontSize: 13, color: context.cSlate),
          ),
        ],
      ),
    );
  }

  // ── 상단 요약
  Widget _buildSummary(BuildContext context) {
    final shown = _selected < 0 ? null : _report.myDecks[_selected];
    final wins = shown?.wins ?? _report.wins;
    final loses = shown?.loses ?? _report.loses;
    final draws = shown?.draws ?? _report.draws;
    final total = wins + loses + draws;
    final rate = total == 0 ? 0.0 : wins / total * 100;

    return Container(
      color: context.cSurface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: rateColor(rate).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: rateColor(rate),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '승률',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: rateColor(rate),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selected < 0
                      ? '내 덱 전체'
                      : (_report.myDecks[_selected].deckName.trim().isNotEmpty
                          ? _report.myDecks[_selected].deckName.trim()
                          : '내 덱 ${_selected + 1}'),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.cInk),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _miniCount('승', wins, const Color(0xFF16A34A)),
                    const SizedBox(width: 10),
                    _miniCount('패', loses, const Color(0xFFDC2626)),
                    const SizedBox(width: 10),
                    _miniCount('무', draws, const Color(0xFFD97706)),
                    const SizedBox(width: 10),
                    Text(
                      '총 $total판',
                      style: TextStyle(fontSize: 12, color: context.cSlate),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniCount(String label, int value, Color color) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: label,
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
        ),
        TextSpan(
          text: ' $value',
          style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color),
        ),
      ]),
    );
  }

  // ── 내 덱 선택
  Widget _buildDeckSelector(BuildContext context) {
    return Container(
      color: context.cSurface,
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        children: [
          _deckChip(
            context,
            index: -1,
            label: '전체',
            rate: _report.winRate,
            ids: const [],
          ),
          for (var i = 0; i < _report.myDecks.length; i++)
            _deckChip(
              context,
              index: i,
              label: _report.myDecks[i].deckName.trim().isNotEmpty
                  ? _report.myDecks[i].deckName.trim()
                  : '내 덱 ${i + 1}',
              rate: _report.myDecks[i].winRate,
              ids: _report.myDecks[i].pokemonIds,
            ),
        ],
      ),
    );
  }

  Widget _deckChip(
    BuildContext context, {
    required int index,
    required String label,
    required double rate,
    required List<int> ids,
  }) {
    final on = _selected == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: on ? const Color(0xFFEF4444).withValues(alpha: 0.07) : context.cFill,
        shape: StadiumBorder(
          side: BorderSide(
            color: on ? const Color(0xFFEF4444) : context.cBorder,
            width: on ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => setState(() => _selected = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ids.isNotEmpty)
                  SpriteCluster(ids: ids, size: 26, spacing: -8)
                else
                  Icon(Icons.dashboard_rounded,
                      size: 18, color: on ? const Color(0xFFEF4444) : context.cSlate),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: on ? const Color(0xFFEF4444) : context.cInk,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${rate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: rateColor(rate),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 상대 덱 목록
  Widget _buildOpponentList(BuildContext context) {
    final opponents = _selected < 0
        ? _report.allOpponentList
        : _report.myDecks[_selected].opponentList;

    if (opponents.isEmpty) {
      return Center(
        child: Text(
          '상대 기록이 없어요',
          style: TextStyle(fontSize: 14, color: context.cSlate),
        ),
      );
    }

    // 물레방아(세로 3D) 스크롤
    return WheelList(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      itemCount: opponents.length + 1,
      strength: 1.0,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(
                  '상대 덱',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: context.cSlate),
                ),
                const Spacer(),
                Text(
                  '${opponents.length}종',
                  style: TextStyle(fontSize: 12, color: context.cSlate),
                ),
              ],
            ),
          );
        }
        return _buildOpponentCard(context, opponents[i - 1], i);
      },
    );
  }

  Widget _buildOpponentCard(BuildContext context, DeckStat opp, int rank) {
    final color = rateColor(opp.winRate);
    final title = deckTitle(opp.deckName, opp.pokemonIds);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: context.cCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (opp.pokemonIds.isNotEmpty)
                SpriteCluster(ids: opp.pokemonIds, size: 40, spacing: -12)
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.cFill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.help_outline_rounded,
                      size: 20, color: context.cSlate),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: context.cInk,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${opp.wins}승 ${opp.loses}패 ${opp.draws}무',
                      style: TextStyle(fontSize: 12, color: context.cSlate),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${opp.winRate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '${opp.total}판',
                    style: TextStyle(fontSize: 10.5, color: context.cSlate),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 6, color: context.cFill),
                FractionallySizedBox(
                  widthFactor: (opp.winRate / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 포켓몬 스프라이트를 겹쳐서 보여주는 위젯
class SpriteCluster extends StatelessWidget {
  final List<int> ids;
  final double size;
  final double spacing;

  const SpriteCluster({
    super.key,
    required this.ids,
    this.size = 40,
    this.spacing = -12,
  });

  @override
  Widget build(BuildContext context) {
    final shown = ids.take(3).toList();
    if (shown.isEmpty) return SizedBox(width: size, height: size);
    final step = size + spacing; // spacing이 음수면 겹쳐진다
    final width = size + step * (shown.length - 1);
    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: step * i,
              child: _sprite(shown[i], context),
            ),
        ],
      ),
    );
  }

  Widget _sprite(int id, BuildContext context) {
    final p = pokemonById(id);
    if (p == null) return SizedBox(width: size, height: size);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.cFill,
        shape: BoxShape.circle,
        border: Border.all(color: context.cSurface, width: 1.5),
      ),
      child: ClipOval(
        child: Padding(
          padding: EdgeInsets.all(size * 0.08),
          child: CachedNetworkImage(
            imageUrl: p.spriteUrl,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            placeholder: (c, u) => const SizedBox.shrink(),
            errorWidget: (c, u, e) => Icon(
              Icons.catching_pokemon,
              size: size * 0.5,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

/// 덱 이름이 있으면 이름을, 없으면 포켓몬 이름으로 표시 제목을 만든다.
String deckTitle(String deckName, List<int> ids) {
  final name = deckName.trim();
  if (name.isNotEmpty) return name;
  if (ids.isEmpty) return '이름 없는 덱';
  final names = ids
      .take(3)
      .map((id) => pokemonById(id)?.nameKo)
      .whereType<String>()
      .toList();
  if (names.isEmpty) return '이름 없는 덱';
  return names.join(' · ');
}
