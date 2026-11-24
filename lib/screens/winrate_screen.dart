import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/pokemon_data.dart';
import '../models/tournament_record.dart';
import '../theme/app_theme.dart';

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

/// 기본 정렬: 많이 만난 덱 → 승률 높은 덱
int compareDeckStat(DeckStat a, DeckStat b) {
  final c = b.total.compareTo(a.total);
  if (c != 0) return c;
  return b.winRate.compareTo(a.winRate);
}

/// 첫 번째 스프라이트가 같은 덱끼리 연속으로 붙여서 정렬한다.
/// (같은 덱인데 카드 몇 장만 다른 덱들을 옆에서 바로 비교하기 편하게)
/// - 입력은 이미 [compareDeckStat] 순으로 정렬되어 있다고 본다.
/// - 그룹(첫 스프라이트) 순서는 그 그룹에서 가장 앞선 덱 순서를 따른다.
/// - 그룹 내부는 [compareDeckStat] 순서 그대로.
/// - 첫 스프라이트가 없는 덱은 맨 뒤로 보낸다.
List<DeckStat> sortByFirstSprite(List<DeckStat> sorted) {
  if (sorted.length <= 1) return sorted;

  final groups = <int, List<DeckStat>>{};
  final noSprite = <DeckStat>[];
  for (final d in sorted) {
    if (d.pokemonIds.isEmpty) {
      noSprite.add(d);
      continue;
    }
    groups.putIfAbsent(d.pokemonIds.first, () => <DeckStat>[]).add(d);
  }

  // 그룹 순서: 입력(많이 만난 순)에서 가장 앞에 나온 덱의 순서
  final firstIndex = <int, int>{};
  for (var i = 0; i < sorted.length; i++) {
    final d = sorted[i];
    if (d.pokemonIds.isEmpty) continue;
    firstIndex.putIfAbsent(d.pokemonIds.first, () => i);
  }
  final keys = groups.keys.toList()
    ..sort((a, b) => firstIndex[a]!.compareTo(firstIndex[b]!));

  final out = <DeckStat>[];
  for (final key in keys) {
    out.addAll(groups[key]!);
  }
  out.addAll(noSprite);
  return out;
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
    final list = opponents.values.toList()..sort(compareDeckStat);
    return sortByFirstSprite(list);
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

  /// 내 덱 구분 키: 스프라이트 조합 우선, 없으면 이름
  static String _myKeyOf(List<int> ids, String name) {
    if (ids.isNotEmpty) {
      final sorted = List<int>.from(ids)..sort();
      return 'ids:${sorted.join('-')}';
    }
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isNotEmpty) return 'name:$trimmed';
    return 'unknown';
  }

  /// 상대 덱 구분 키: 오직 스프라이트 조합으로만.
  /// (직접 쓴 이름은 분류에 쓰지 않는다)
  static String _oppKeyOf(List<int> ids) {
    if (ids.isNotEmpty) {
      final sorted = List<int>.from(ids)..sort();
      return 'ids:${sorted.join('-')}';
    }
    return 'unknown';
  }

  factory WinRateReport.from(List<TournamentRecord> records) {
    final report = WinRateReport();
    for (final record in records) {
      for (final round in record.rounds) {
        final result = round.roundResult;
        if (result == MatchResult.none) continue;

        final myKey = _myKeyOf(record.myPokemonIds, record.myDeckName);
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
        if (myDeck.deckName.trim().isEmpty &&
            record.myDeckName.trim().isNotEmpty) {
          myDeck.deckName = record.myDeckName;
        }

        final oppKey = _oppKeyOf(round.opponentPokemonIds);
        final opp = myDeck.opponents.putIfAbsent(
          oppKey,
          () => DeckStat(
            signature: oppKey,
            pokemonIds: round.opponentPokemonIds,
            deckName: '',
          ),
        );

        final allOpp = report.allOpponents.putIfAbsent(
          oppKey,
          () => DeckStat(
            signature: oppKey,
            pokemonIds: round.opponentPokemonIds,
            deckName: '',
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
    final list = allOpponents.values.toList()..sort(compareDeckStat);
    return sortByFirstSprite(list);
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
                if (_report.myDecks.length > 1) _buildDeckSelector(context),
                Expanded(child: _buildOpponentGrid(context)),
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

  // ── 상단 요약 (메인 통계 헤더와 같은 결: 숫자 + 라벨 + 구분선)
  Widget _buildSummary(BuildContext context) {
    final shown = _selected < 0 ? null : _report.myDecks[_selected];
    final wins = shown?.wins ?? _report.wins;
    final loses = shown?.loses ?? _report.loses;
    final draws = shown?.draws ?? _report.draws;
    final total = wins + loses + draws;
    final rate = total == 0 ? 0.0 : wins / total * 100;

    return Container(
      color: context.cSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _statCell('${rate.toStringAsFixed(0)}%', '승률', rateColor(rate)),
          _divider(),
          _statCell('$wins', '승', const Color(0xFF22C55E)),
          _divider(),
          _statCell('$draws', '무', const Color(0xFFF59E0B)),
          _divider(),
          _statCell('$loses', '패', const Color(0xFFEF4444)),
          _divider(),
          _statCell('$total', '판', context.cInk),
        ],
      ),
    );
  }

  Widget _statCell(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              height: 1.1,
              color: context.cSlate,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: context.cLine,
    );
  }

  // ── 내 덱 선택
  Widget _buildDeckSelector(BuildContext context) {
    return Container(
      color: context.cSurface,
      height: 62,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
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
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: on
            ? const Color(0xFFEF4444).withValues(alpha: 0.06)
            : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(color: on ? const Color(0xFFEF4444) : context.cBorder),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => setState(() => _selected = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ids.isNotEmpty)
                  SpriteCluster(ids: ids, size: 22, spacing: -7)
                else
                  Icon(Icons.dashboard_rounded,
                      size: 16,
                      color: on ? const Color(0xFFEF4444) : context.cSlate),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: on ? const Color(0xFFEF4444) : context.cInk,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 6),
                Text(
                  '${rate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: rateColor(rate),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 상대 덱: 한 줄에 4개 (첫 스프라이트가 같은 덱끼리 연속 배치)
  static const int kOpponentColumns = 4;

  Widget _buildOpponentGrid(BuildContext context) {
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

    const columns = kOpponentColumns;
    const gap = 8.0;
    const maxContentWidth = 720.0;
    const minCardHeight = 128.0;
    const maxCardHeight = 154.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final sidePad = ((width - maxContentWidth) / 2).clamp(12.0, 999.0);
        final cardWidth =
            (width - sidePad * 2 - gap * (columns - 1)) / columns;
        final cardHeight =
            (cardWidth / 0.63).clamp(minCardHeight, maxCardHeight);
        final aspect = cardWidth / cardHeight;

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(sidePad, 10, sidePad, 24),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            childAspectRatio: aspect,
          ),
          itemCount: opponents.length,
          itemBuilder: (ctx, i) => _buildOpponentCard(context, opponents[i]),
        );
      },
    );
  }

  Widget _buildOpponentCard(BuildContext context, DeckStat opp) {
    final color = rateColor(opp.winRate);
    final title = opponentTitle(opp.pokemonIds);

    return Container(
      key: Key('opp-card-${opp.signature}'),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      decoration: BoxDecoration(
        color: context.cCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Spacer(),
          // 스프라이트만 (원/배경 없음)
          if (opp.pokemonIds.isNotEmpty)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: SpriteCluster(ids: opp.pokemonIds, size: 38, spacing: -18),
            )
          else
            Icon(Icons.help_outline_rounded, size: 28, color: context.cSlate),
          const Spacer(),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: context.cSlate,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${opp.winRate.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 17.5,
              height: 1.05,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            opp.draws > 0
                ? '${opp.wins}-${opp.loses}-${opp.draws}'
                : '${opp.wins}-${opp.loses}',
            style: TextStyle(
              fontSize: 10,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: context.cSlate,
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                Container(height: 3, color: context.cFill),
                FractionallySizedBox(
                  widthFactor: (opp.winRate / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
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

/// 포켓몬 스프라이트를 겹쳐서 보여주는 위젯 (원형 배경 없음)
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
            Positioned(left: step * i, child: _sprite(shown[i])),
        ],
      ),
    );
  }

  Widget _sprite(int id) {
    final p = pokemonById(id);
    if (p == null) return SizedBox(width: size, height: size);
    return SizedBox(
      width: size,
      height: size,
      child: CachedNetworkImage(
        imageUrl: p.spriteUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        placeholder: (c, u) => const SizedBox.shrink(),
        errorWidget: (c, u, e) =>
            Icon(Icons.catching_pokemon, size: size * 0.6, color: Colors.grey),
      ),
    );
  }
}

/// 내 덱 이름: 이름이 있으면 이름, 없으면 포켓몬 이름
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

/// 상대 덱 이름: 스프라이트(포켓몬)로만 표시
String opponentTitle(List<int> ids) {
  if (ids.isEmpty) return '알 수 없음';
  final names = ids
      .take(3)
      .map((id) => pokemonById(id)?.nameKo)
      .whereType<String>()
      .toList();
  if (names.isEmpty) return '알 수 없음';
  return names.join(' · ');
}
