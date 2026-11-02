import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/tournament_provider.dart';
import '../models/tournament_record.dart';
import '../data/pokemon_data.dart';
import 'record_edit_screen.dart';
import 'calendar_screen.dart';
import 'folder_screen.dart';
import '../widgets/folder_picker_sheet.dart';
import '../utils/image_saver.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _selecting = false;
  bool _exporting = false;
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final records = provider.records;
    return Scaffold(
      backgroundColor: context.cBg,
      appBar: _selecting
          ? _buildSelectAppBar(records)
          : _buildNormalAppBar(records),
      body: Builder(
        builder: (ctx) {
          if (records.isEmpty) {
            return _buildEmptyState(context);
          }
          return Column(
            children: [
              _buildStatsHeader(records),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                      _selecting ? 8 : 16, 12, 16, _selecting ? 24 : 40),
                  itemCount: records.length,
                  itemBuilder: (ctx, i) {
                    final r = records[i];
                    final card = _buildRecordCard(context, r, provider);
                    if (!_selecting) return card;
                    final on = _selected.contains(r.id);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _toggleSelect(r.id),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(4, 18, 8, 0),
                            child: Icon(
                              on
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 28,
                              color: on
                                  ? const Color(0xFFEF4444)
                                  : context.cBorder,
                            ),
                          ),
                        ),
                        Expanded(child: card),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _selecting
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  color: context.cSurface,
                  border: Border(top: BorderSide(color: context.cLine)),
                ),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _selected.isEmpty || _exporting
                        ? null
                        : () => _confirmAndSave(records),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE5E7EB),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      _selected.isEmpty
                          ? '저장할 대회를 선택하세요'
                          : '선택한 로그 이미지로 저장 (${_selected.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // ────────────────────────────────────────────────
  // 앱바
  // ────────────────────────────────────────────────
  PreferredSizeWidget _buildNormalAppBar(List<TournamentRecord> records) {
    return AppBar(
      backgroundColor: context.cSurface,
      elevation: 0,
      titleSpacing: 16,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
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
            Text(
              'Battle Log',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.cInk,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 10),
            _appBarChip(
              icon: Icons.add,
              label: '새 기록',
              filled: true,
              onTap: () => _createNewRecord(context),
            ),
            const SizedBox(width: 6),
            _appBarChip(
              icon: Icons.calendar_month_rounded,
              label: '월별',
              filled: false,
              onTap: () => _openCalendar(context),
            ),
            const SizedBox(width: 6),
            _appBarChip(
              icon: Icons.folder_rounded,
              label: '폴더',
              filled: false,
              onTap: () => _openFolders(context),
            ),
            if (records.isNotEmpty) ...[
              const SizedBox(width: 6),
              _appBarChip(
                icon: Icons.download_rounded,
                label: '저장',
                filled: false,
                onTap: () => setState(() {
                  _selecting = true;
                  _selected.clear();
                }),
              ),
            ],
          ],
        ),
      ),
      actions: const [ThemeBulbButton(), SizedBox(width: 4)],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: context.cLine),
      ),
    );
  }

  Widget _appBarChip({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    const red = Color(0xFFEF4444);
    return Material(
      color: filled ? red : context.cSurface,
      shape: StadiumBorder(
        side: BorderSide(color: filled ? red : context.cBorder),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: filled ? Colors.white : context.cInk),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : context.cInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSelectAppBar(List<TournamentRecord> records) {
    final allOn = records.isNotEmpty && _selected.length == records.length;
    return AppBar(
      backgroundColor: context.cSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exporting ? null : _exitSelect,
      ),
      title: Text(
        _selected.isEmpty ? '저장할 대회 선택' : '${_selected.length}개 선택됨',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      actions: [
        TextButton(
          onPressed: _exporting
              ? null
              : () => setState(() {
                    if (allOn) {
                      _selected.clear();
                    } else {
                      _selected
                        ..clear()
                        ..addAll(records.map((r) => r.id));
                    }
                  }),
          child: Text(allOn ? '전체 해제' : '전체 선택',
              style: const TextStyle(
                  color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: context.cLine),
      ),
    );
  }

  void _toggleSelect(String id) {
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  void _exitSelect() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
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
      color: context.cSurface,
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
      Container(width: 1, height: 28, color: context.cLine);

  // ────────────────────────────────────────────────
  // 기록 카드 (Dismissible로 좌→삭제)
  // ────────────────────────────────────────────────
  Widget _buildRecordCard(BuildContext context, TournamentRecord record,
      TournamentProvider provider) {
    return Dismissible(
      key: ValueKey(record.id),
      direction:
          _selecting ? DismissDirection.none : DismissDirection.endToStart,
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
        onTap: () => _selecting
            ? _toggleSelect(record.id)
            : _editRecord(context, record, provider),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          foregroundDecoration: _selecting && _selected.contains(record.id)
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: const Color(0xFFEF4444), width: 2.5),
                )
              : null,
          decoration: BoxDecoration(
            color: context.cSurface,
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
              _buildCardBody(record, showFolder: !_selecting),
              // ── 슬라이드 힌트 표시줄
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: context.cTint,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(14)),
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

  Widget _buildCardBody(TournamentRecord record, {bool showFolder = false}) {
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            record.tournamentName.isEmpty
                                ? '대회명 없음'
                                : record.tournamentName,
                            style: TextStyle(
                              fontSize: 21,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: context.cInk,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        if (showFolder) ...[
                          const SizedBox(width: 8),
                          _buildFolderButton(record),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${DateFormat('yyyy.MM.dd').format(record.date)}  ·  승률 $rate%',
                      style: TextStyle(fontSize: 13, color: context.cSlate),
                    ),
                    if (record.myDeckName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.myDeckName,
                        style: TextStyle(fontSize: 12, color: context.cSlate),
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
                    style: TextStyle(
                      fontSize: 26,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: context.cInk,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (myPokemons.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: myPokemons
                          .take(3)
                          .map((p) => Align(
                                widthFactor: 0.78,
                                child: _buildSprite(p.spriteUrl, size: 54),
                              ))
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text('라운드',
                      style: TextStyle(
                          fontSize: 13,
                          color: context.cSlate,
                          fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: Text('덱',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: context.cSlate,
                          fontWeight: FontWeight.w500)),
                ),
                SizedBox(
                  width: 56,
                  child: Text('결과',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 13,
                          color: context.cSlate,
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
        bg = context.isDark ? const Color(0xFF1F4A38) : const Color(0xFFD9F8E7);
        fg = context.isDark ? const Color(0xFF4ADE80) : const Color(0xFF059669);
        break;
      case MatchResult.lose:
        bg = context.isDark ? const Color(0xFF5A2A2E) : const Color(0xFFFFE0E0);
        fg = context.isDark ? const Color(0xFFFF7B7B) : const Color(0xFFDC2626);
        break;
      case MatchResult.draw:
        bg = context.isDark ? const Color(0xFF574516) : const Color(0xFFFEF3C7);
        fg = context.isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
        break;
      case MatchResult.none:
        bg = context.isDark ? context.cFill : const Color(0xFFF3F4F6);
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
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      color: bg,
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
                          child: _buildSprite(p.spriteUrl, size: 54),
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
          Text(
            '아직 기록이 없어요',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: context.cInk),
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

  Widget _buildFolderButton(TournamentRecord record) {
    final folder =
        context.watch<TournamentProvider>().folderById(record.folderId);
    final inFolder = folder != null;
    const red = Color(0xFFEF4444);
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Material(
        color: inFolder ? red.withValues(alpha: 0.12) : context.cFill,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => showFolderPickerSheet(context, record),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  inFolder ? Icons.folder_rounded : Icons.folder_outlined,
                  size: 16,
                  color: inFolder ? red : context.cSlate,
                ),
                if (inFolder) ...[
                  const SizedBox(width: 3),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 70),
                    child: Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openFolders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => FolderListScreen(
          cardBuilder: (r) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: context.cSurface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildCardBody(r, showFolder: true),
          ),
          onEdit: (c, r) => _editRecord(c, r, c.read<TournamentProvider>()),
        ),
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

  void _openCalendar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CalendarScreen(
          cardBuilder: (r) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: context.cSurface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildCardBody(r, showFolder: true),
          ),
          onEdit: (c, r) => _editRecord(c, r, c.read<TournamentProvider>()),
        ),
      ),
    );
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

  // ────────────────────────────────────────────────
  // 이미지 저장
  // ────────────────────────────────────────────────
  Future<void> _confirmAndSave(List<TournamentRecord> records) async {
    final targets = records.where((r) => _selected.contains(r.id)).toList();
    if (targets.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('저장하시겠습니까?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Text(
          '선택한 ${targets.length}개의 대회 로그를\n이미지(PNG)로 저장합니다.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('아니오', style: TextStyle(color: Colors.grey)),
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
            child:
                const Text('예', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _exporting = true);
    // 진행 표시
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFEF4444)),
                  const SizedBox(height: 14),
                  Text('이미지 만드는 중...',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                          color: context.cInk)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    int saved = 0;
    try {
      for (final r in targets) {
        final bytes = await _captureRecord(r);
        if (bytes == null) continue;
        final ok2 = await savePngImage(bytes, _fileNameOf(r));
        if (ok2) saved++;
        await Future.delayed(const Duration(milliseconds: 400));
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // 진행 다이얼로그
    setState(() => _exporting = false);
    if (saved > 0) _exitSelect();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved > 0
            ? '$saved개의 대회 로그를 이미지로 저장했습니다.'
            : '이미지 저장에 실패했습니다. (브라우저에서만 지원됩니다)'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _fileNameOf(TournamentRecord r) {
    final name =
        r.tournamentName.trim().isEmpty ? 'battlelog' : r.tournamentName.trim();
    final safe = name.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
    return 'battlelog_${safe}_${DateFormat('yyyyMMdd').format(r.date)}.png';
  }

  /// 화면 밖에 카드를 그려서 PNG로 캡처
  Future<Uint8List?> _captureRecord(TournamentRecord r) async {
    // 스프라이트 미리 로드
    final urls = <String>{
      ..._pokemonOf(r.myPokemonIds).map((p) => p.spriteUrl),
      for (final round in r.rounds)
        ..._pokemonOf(round.opponentPokemonIds).map((p) => p.spriteUrl),
    };
    await Future.wait(urls.map((u) async {
      try {
        await precacheImage(CachedNetworkImageProvider(u), context)
            .timeout(const Duration(seconds: 8));
      } catch (_) {}
    }));
    if (!mounted) return null;

    final key = GlobalKey();
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -3000,
        top: 0,
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: key,
            child: Container(
              width: 420,
              color: context.cExportBg,
              padding: const EdgeInsets.all(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.cSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildCardBody(r),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    try {
      await Future.delayed(const Duration(milliseconds: 900));
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }
}
