import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/tournament_provider.dart';
import '../models/tournament_record.dart';
import '../data/pokemon_data.dart';
import 'record_edit_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.catching_pokemon,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text(
              'Battle Log',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF0F0F0)),
        ),
      ),
      body: Consumer<TournamentProvider>(
        builder: (ctx, provider, _) {
          final records = provider.records;
          if (records.isEmpty) {
            return _buildEmptyState(context);
          }
          return Column(
            children: [
              _buildStatsHeader(records),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: records.length,
                  itemBuilder: (ctx, i) =>
                      _buildRecordCard(context, records[i], provider),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewRecord(context),
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          '새 기록',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // 통계 헤더
  // ────────────────────────────────────────────────
  Widget _buildStatsHeader(List<TournamentRecord> records) {
    int totalWins = records.fold(0, (sum, r) => sum + r.totalWins);
    int totalLoses = records.fold(0, (sum, r) => sum + r.totalLoses);
    int totalDraws = records.fold(0, (sum, r) => sum + r.totalDraws);
    int total = totalWins + totalLoses + totalDraws;
    double winRate = total > 0 ? totalWins / total * 100 : 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStatItem('대회', '${records.length}', const Color(0xFF6366F1)),
          _buildStatDivider(),
          _buildStatItem('승', '$totalWins', const Color(0xFF22C55E)),
          _buildStatDivider(),
          _buildStatItem('무', '$totalDraws', const Color(0xFFF59E0B)),
          _buildStatDivider(),
          _buildStatItem('패', '$totalLoses', const Color(0xFFEF4444)),
          _buildStatDivider(),
          _buildStatItem(
              '승률', '${winRate.toStringAsFixed(0)}%', const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() => Container(
        width: 1, height: 28, color: const Color(0xFFF0F0F0));

  // ────────────────────────────────────────────────
  // 기록 카드 (Dismissible로 좌→삭제)
  // ────────────────────────────────────────────────
  Widget _buildRecordCard(BuildContext context, TournamentRecord record,
      TournamentProvider provider) {
    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text(
              '삭제',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text(
              '기록 삭제',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            content: Text(
              '"${record.tournamentName.isEmpty ? '대회명 없음' : record.tournamentName}" 기록을 삭제할까요?\n삭제 후 복구할 수 없습니다.',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('삭제',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        provider.deleteRecord(record.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '"${record.tournamentName.isEmpty ? '대회' : record.tournamentName}" 기록이 삭제되었습니다.'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _editRecord(context, record, provider),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
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
            children: [
              // ── 카드 내용
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더: 대회명 + 날짜 + 전적 배지
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.tournamentName.isEmpty
                                    ? '대회명 없음'
                                    : record.tournamentName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                DateFormat('yyyy.MM.dd').format(record.date),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        _buildWinLoseBadge(
                            record.totalWins,
                            record.totalLoses,
                            record.totalDraws),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 내 덱 정보
                    Row(
                      children: [
                        ...record.myPokemonIds.take(3).map((id) {
                          final p = allPokemon.firstWhere(
                            (p) => p.id == id,
                            orElse: () => const PokemonInfo(
                                id: 1,
                                name: 'bulbasaur',
                                nameKo: '이상해씨'),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: _buildMiniAvatar(p.spriteUrl),
                          );
                        }),
                        if (record.myPokemonIds.isNotEmpty)
                          const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            record.myDeckName.isEmpty
                                ? '덱 미설정'
                                : record.myDeckName,
                            style: TextStyle(
                              fontSize: 13,
                              color: record.myDeckName.isEmpty
                                  ? Colors.grey[400]
                                  : const Color(0xFF444444),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 16, color: Colors.grey),
                      ],
                    ),
                    if (record.rounds.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(
                          height: 1, color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 10),
                      _buildRoundPreview(record),
                    ],
                  ],
                ),
              ),
              // ── 슬라이드 힌트 표시줄
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.swipe_left,
                        size: 13, color: Color(0xFFEF4444)),
                    SizedBox(width: 4),
                    Text(
                      '← 밀어서 삭제',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(width: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // 라운드 미리보기 (세로)
  // ────────────────────────────────────────────────
  Widget _buildRoundPreview(TournamentRecord record) {
    return Column(
      children: record.rounds.asMap().entries.map((e) {
        final idx = e.key;
        final round = e.value;
        final roundResult = round.roundResult;

        final opponentPokemons = round.opponentPokemonIds
            .map((id) {
              try {
                return allPokemon.firstWhere((p) => p.id == id);
              } catch (_) {
                return null;
              }
            })
            .whereType<PokemonInfo>()
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 라운드 번호
              SizedBox(
                width: 28,
                child: Text(
                  'R${idx + 1}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey),
                ),
              ),
              const SizedBox(width: 4),
              // 개별 게임 결과 아이콘 — 색깔만, 텍스트 없음
              ...round.games.map((game) {
                final Color dotColor;
                if (game.result == MatchResult.win) {
                  dotColor = const Color(0xFF22C55E);
                } else if (game.result == MatchResult.lose) {
                  dotColor = const Color(0xFFEF4444);
                } else if (game.result == MatchResult.draw) {
                  dotColor = const Color(0xFFF59E0B);
                } else {
                  dotColor = const Color(0xFFDDDDDD);
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
              // 라운드 최종 결과 배지
              Container(
                margin: const EdgeInsets.only(left: 2, right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: roundResult == MatchResult.win
                      ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                      : roundResult == MatchResult.lose
                          ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                          : roundResult == MatchResult.draw
                              ? const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.12)
                              : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  roundResult == MatchResult.win
                      ? '승'
                      : roundResult == MatchResult.lose
                          ? '패'
                          : roundResult == MatchResult.draw
                              ? '무'
                              : '−',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: roundResult == MatchResult.win
                        ? const Color(0xFF22C55E)
                        : roundResult == MatchResult.lose
                            ? const Color(0xFFEF4444)
                            : roundResult == MatchResult.draw
                                ? const Color(0xFFF59E0B)
                                : Colors.grey,
                  ),
                ),
              ),
              // 상대 덱 이름
              if (round.opponentDeckName.isNotEmpty)
                Expanded(
                  child: Text(
                    round.opponentDeckName,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF555555)),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
              // 상대 포켓몬 아이콘
              ...opponentPokemons.take(3).map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: _buildMiniAvatar(p.spriteUrl, size: 26),
                    ),
                  ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniAvatar(String url, {double size = 30}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (c, u) => const SizedBox(),
          errorWidget: (c, u, e) => Icon(
            Icons.catching_pokemon,
            size: size * 0.5,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }

  // 승/무/패 + 승률 — 배지 없이 색상만
  Widget _buildWinLoseBadge(int wins, int loses, int draws) {
    final total = wins + loses + draws;
    final winRate = total > 0 ? (wins / total * 100).toStringAsFixed(0) : '0';

    return Row(children: [
      // 승
      Text('$wins', style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800,
          color: Color(0xFF22C55E))),
      const Text('승', style: TextStyle(
          fontSize: 11, color: Color(0xFF22C55E),
          fontWeight: FontWeight.w500)),
      const SizedBox(width: 4),
      // 무 (있을 때만)
      if (draws > 0) ...[
        Text('$draws', style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800,
            color: Color(0xFFF59E0B))),
        const Text('무', style: TextStyle(
            fontSize: 11, color: Color(0xFFF59E0B),
            fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
      ],
      // 패
      Text('$loses', style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800,
          color: Color(0xFFEF4444))),
      const Text('패', style: TextStyle(
          fontSize: 11, color: Color(0xFFEF4444),
          fontWeight: FontWeight.w500)),
      const SizedBox(width: 6),
      // 구분선
      Container(width: 1, height: 12, color: const Color(0xFFE0E0E0)),
      const SizedBox(width: 6),
      // 승률
      Text('$winRate%', style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800,
          color: Color(0xFF8B5CF6))),
    ]);
  }

  // ────────────────────────────────────────────────
  // 빈 상태
  // ────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.catching_pokemon,
                size: 40, color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 16),
          const Text(
            '아직 기록이 없어요',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 8),
          Text(
            '+ 새 기록 버튼을 눌러\n대회 기록을 시작하세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: Colors.grey[500], height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createNewRecord(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('첫 기록 시작하기',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // 네비게이션
  // ────────────────────────────────────────────────
  Future<void> _createNewRecord(BuildContext context) async {
    final newRecord = TournamentRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      rounds: [RoundRecord()],
    );
    final result = await Navigator.push<TournamentRecord>(
      context,
      MaterialPageRoute(
        builder: (ctx) =>
            RecordEditScreen(record: newRecord, isNew: true),
      ),
    );
    if (result != null && context.mounted) {
      await context.read<TournamentProvider>().addRecord(result);
    }
  }

  Future<void> _editRecord(BuildContext context, TournamentRecord record,
      TournamentProvider provider) async {
    final result = await Navigator.push<TournamentRecord>(
      context,
      MaterialPageRoute(
        builder: (ctx) => RecordEditScreen(record: record),
      ),
    );
    if (result != null && context.mounted) {
      await provider.updateRecord(result);
    }
  }
}
