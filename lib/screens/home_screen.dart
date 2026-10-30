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
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() =>
      Container(width: 1, height: 28, color: const Color(0xFFF0F0F0));

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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                child: const Text('취소', style: TextStyle(color: Colors.grey)),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              // ── 카드 내용 (배틀 로그 스타일)
              _buildCardBody(record),
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
                    Icon(Icons.swipe_left, size: 13, color: Color(0xFFEF4444)),
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
  // 기록 카드 본문 (타사이트 배틀 로그 스타일)
  // ────────────────────────────────────────────────
  static const Color _kInk = Color(0xFF0F172A);
  static const Color _kSlate = Color(0xFF64748B);

  List<PokemonInfo> _pokemonOf(List<int> ids) {
    return ids
        .map((id) {
          try {
            return allPokemon.firstWhere((p) => p.id == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<PokemonInfo>()
        .toList();
  }

  Widget _buildCardBody(TournamentRecord record) {
    final w = record.totalWins;
    final l = record.totalLoses;
    final d = record.totalDraws;
    final total = w + l + d;
    final rate = total > 0 ? (w / total * 100).toStringAsFixed(0) : '0';
    final recordText = d > 0 ? '$w-$l-$d' : '$w-$l';
    final myPokemons = _pokemonOf(record.myPokemonIds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더: 큰 대회명 / 큰 전적
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          child: Row(
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
                        fontSize: 21,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: _kInk,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${DateFormat('yyyy.MM.dd').format(record.date)}  ·  승률 $rate%',
                      style: const TextStyle(fontSize: 13, color: _kSlate),
                    ),
                    if (record.myDeckName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.myDeckName,
                        style: const TextStyle(fontSize: 12, color: _kSlate),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    recordText,
                    style: const TextStyle(
                      fontSize: 26,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: _kInk,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (myPokemons.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: myPokemons
                          .take(3)
                          .map((p) => _buildSprite(p.spriteUrl, size: 40))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (record.rounds.isNotEmpty) ...[
          // 표 헤더: Round / Deck / Result
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text('라운드',
                      style: TextStyle(
                          fontSize: 13,
                          color: _kSlate,
                          fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: Text('덱',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: _kSlate,
                          fontWeight: FontWeight.w500)),
                ),
                SizedBox(
                  width: 56,
                  child: Text('결과',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 13,
                          color: _kSlate,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          // 라운드 행: 승=연초록 / 패=연빨강 / 무=연노랑
          ...record.rounds
              .asMap()
              .entries
              .map((e) => _buildRoundRow(e.key, e.value)),
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildRoundRow(int idx, RoundRecord round) {
    final result = round.roundResult;
    final Color bg;
    final Color fg;
    switch (result) {
      case MatchResult.win:
        bg = const Color(0xFFD9F8E7);
        fg = const Color(0xFF059669);
        break;
      case MatchResult.lose:
        bg = const Color(0xFFFFE0E0);
        fg = const Color(0xFFDC2626);
        break;
      case MatchResult.draw:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
      case MatchResult.none:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF9CA3AF);
        break;
    }

    final letters = round.games.map((g) {
      switch (g.result) {
        case MatchResult.win:
          return 'W';
        case MatchResult.lose:
          return 'L';
        case MatchResult.draw:
          return 'D';
        case MatchResult.none:
          return '-';
      }
    }).join();

    final opponents = _pokemonOf(round.opponentPokemonIds);

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom:
              BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '${idx + 1}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: opponents
                    .take(3)
                    .map((p) => Align(
                          widthFactor: 0.78,
                          child: _buildSprite(p.spriteUrl, size: 56),
                        ))
                    .toList(),
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              letters,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: fg,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 배경 없는 도트 스프라이트 (픽셀 선명하게)
  Widget _buildSprite(String url, {double size = 44}) {
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      placeholder: (c, u) => SizedBox(width: size, height: size),
      errorWidget: (c, u, e) => SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.catching_pokemon,
            size: size * 0.5, color: Colors.grey[400]),
      ),
    );
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
            style:
                TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createNewRecord(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        builder: (ctx) => RecordEditScreen(record: newRecord, isNew: true),
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
