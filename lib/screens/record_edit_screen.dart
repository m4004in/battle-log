import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../models/tournament_record.dart';
import '../data/pokemon_data.dart';
import '../widgets/pokemon_picker_dialog.dart';
import '../widgets/pokemon_avatar_row.dart';

class RecordEditScreen extends StatefulWidget {
  final TournamentRecord record;
  final bool isNew;

  const RecordEditScreen({
    super.key,
    required this.record,
    this.isNew = false,
  });

  @override
  State<RecordEditScreen> createState() => _RecordEditScreenState();
}

class _RecordEditScreenState extends State<RecordEditScreen> {
  late TournamentRecord _record;
  final _tournamentNameCtrl = TextEditingController();
  final _myDeckNameCtrl = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _record = TournamentRecord(
      id: widget.record.id,
      tournamentName: widget.record.tournamentName,
      date: widget.record.date,
      myDeckName: widget.record.myDeckName,
      myPokemonIds: List.from(widget.record.myPokemonIds),
      rounds: widget.record.rounds
          .map((r) => RoundRecord(
                opponentDeckName: r.opponentDeckName,
                opponentPokemonIds: List.from(r.opponentPokemonIds),
                games: r.games.map((g) => MatchGame(result: g.result)).toList(),
              ))
          .toList(),
      createdAt: widget.record.createdAt,
    );
    _tournamentNameCtrl.text = _record.tournamentName;
    _myDeckNameCtrl.text = _record.myDeckName;
  }

  @override
  void dispose() {
    _tournamentNameCtrl.dispose();
    _myDeckNameCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _record.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFFEF4444),
                onPrimary: Colors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _record.date = picked);
  }

  Future<void> _pickMyPokemon() async {
    final result = await showDialog<List<int>>(
      context: context,
      builder: (ctx) => PokemonPickerDialog(
        selectedIds: _record.myPokemonIds,
        maxSelect: 3,
      ),
    );
    if (result != null) {
      setState(() => _record.myPokemonIds = result);
    }
  }

  Future<void> _pickOpponentPokemon(int roundIndex) async {
    final result = await showDialog<List<int>>(
      context: context,
      builder: (ctx) => PokemonPickerDialog(
        selectedIds: _record.rounds[roundIndex].opponentPokemonIds,
        maxSelect: 3,
      ),
    );
    if (result != null) {
      setState(() => _record.rounds[roundIndex].opponentPokemonIds = result);
    }
  }

  void _addRound() {
    setState(() {
      _record.rounds.add(RoundRecord());
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeRound(int index) {
    if (_record.rounds.length <= 1) return;
    setState(() => _record.rounds.removeAt(index));
  }

  void _toggleGameResult(int roundIndex, int gameIndex) {
    setState(() {
      final game = _record.rounds[roundIndex].games[gameIndex];
      switch (game.result) {
        case MatchResult.none:
          game.result = MatchResult.win;
          break;
        case MatchResult.win:
          game.result = MatchResult.lose;
          break;
        case MatchResult.lose:
          game.result = MatchResult.draw;
          break;
        case MatchResult.draw:
          game.result = MatchResult.none;
          break;
      }
    });
  }

  void _addGame(int roundIndex) {
    final round = _record.rounds[roundIndex];
    if (round.games.length >= 3) return;
    setState(() => round.games.add(MatchGame()));
  }

  void _removeGame(int roundIndex) {
    final round = _record.rounds[roundIndex];
    if (round.games.length <= 1) return;
    setState(() => round.games.removeLast());
  }

  void _save() {
    _record.tournamentName = _tournamentNameCtrl.text;
    _record.myDeckName = _myDeckNameCtrl.text;
    for (int i = 0; i < _record.rounds.length; i++) {
      // 덱 이름은 각 라운드 위젯에서 직접 업데이트됨
    }
    Navigator.pop(context, _record);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: context.cSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 18, color: context.cInk),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isNew ? '새 대회 기록' : '기록 수정',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.cInk,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              '저장',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.cLine),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 대회 정보 섹션 ───
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('대회 정보', Icons.emoji_events_outlined),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _tournamentNameCtrl,
                    label: '대회명',
                    hint: '예) 2024 시티 리그',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 10),
                  // 날짜 선택
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: context.cSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.cBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('yyyy년 MM월 dd일').format(_record.date),
                            style: TextStyle(
                              fontSize: 14,
                              color: context.cInk,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right,
                              size: 16, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── 내 덱 섹션 ───
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('내 덱', Icons.style_outlined),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: _myDeckNameCtrl,
                    label: '덱 이름',
                    hint: '예) 뮤 ex / 루기아 V STAR',
                    icon: Icons.label_outline,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '덱 포켓몬 (최대 3마리)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PokemonSelectorRow(
                    selectedIds: _record.myPokemonIds,
                    onTap: _pickMyPokemon,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── 라운드 섹션 ───
            _buildSectionTitle('라운드 기록', Icons.sports_score_outlined,
                isOutside: true),
            const SizedBox(height: 8),
            ..._record.rounds.asMap().entries.map((e) {
              return _buildRoundCard(e.key, e.value);
            }),
            const SizedBox(height: 10),
            // 라운드 추가 버튼
            GestureDetector(
              onTap: _addRound,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: context.cSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 18, color: Color(0xFFEF4444)),
                    SizedBox(width: 6),
                    Text(
                      '라운드 추가',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundCard(int roundIndex, RoundRecord round) {
    final roundOpponentNameCtrl =
        TextEditingController(text: round.opponentDeckName);
    roundOpponentNameCtrl
        .addListener(() => round.opponentDeckName = roundOpponentNameCtrl.text);

    return Container(
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
      child: Column(
        children: [
          // 라운드 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.cTint,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${roundIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${roundIndex + 1}라운드',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: context.cInk,
                  ),
                ),
                const Spacer(),
                // 라운드 결과 배지
                _buildResultBadge(round.roundResult),
                const SizedBox(width: 8),
                if (_record.rounds.length > 1)
                  GestureDetector(
                    onTap: () => _removeRound(roundIndex),
                    child: const Icon(Icons.remove_circle_outline,
                        size: 18, color: Colors.grey),
                  ),
              ],
            ),
          ),
          // 라운드 내용
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상대 덱 이름
                TextField(
                  controller: roundOpponentNameCtrl,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '상대 덱 이름 (예: 피카츄 ex)',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    prefixIcon: Icon(Icons.person_outline,
                        size: 16, color: Colors.grey[400]),
                    filled: true,
                    fillColor: context.cFill,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // 상대 포켓몬 선택
                Row(
                  children: [
                    const Text(
                      '상대 포켓몬',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _pickOpponentPokemon(roundIndex),
                      child: const Text(
                        '선택',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                PokemonSelectorRow(
                  selectedIds: round.opponentPokemonIds,
                  onTap: () => _pickOpponentPokemon(roundIndex),
                  avatarSize: 40,
                ),
                const SizedBox(height: 14),
                // 게임 결과
                Row(
                  children: [
                    const Text(
                      '매치 결과',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    // 게임 수 조절
                    GestureDetector(
                      onTap: () => _removeGame(roundIndex),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: context.cLine,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.remove, size: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${round.games.length}판',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _addGame(roundIndex),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: context.cLine,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.add, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 게임 결과 버튼들 + 범례
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...round.games.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Text(
                              '${e.key + 1}게임',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _toggleGameResult(roundIndex, e.key),
                              child: _buildGameResultButton(e.value.result),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Spacer(),
                    // 범례
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 2),
                        _buildLegendItem('○', '승', const Color(0xFF22C55E)),
                        const SizedBox(height: 2),
                        _buildLegendItem('△', '무', const Color(0xFFF59E0B)),
                        const SizedBox(height: 2),
                        _buildLegendItem('✕', '패', const Color(0xFFEF4444)),
                      ],
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

  Widget _buildGameResultButton(MatchResult result) {
    switch (result) {
      case MatchResult.win:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF22C55E), width: 2),
          ),
          child: const Center(
            child: Text('○',
                style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFF22C55E),
                    fontWeight: FontWeight.w700)),
          ),
        );
      case MatchResult.lose:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEF4444), width: 2),
          ),
          child: const Center(
            child: Text('✕',
                style: TextStyle(
                    fontSize: 22,
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w700)),
          ),
        );
      case MatchResult.draw:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF59E0B), width: 2),
          ),
          child: const Center(
            child: Text('△',
                style: TextStyle(
                    fontSize: 22,
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.w700)),
          ),
        );
      case MatchResult.none:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.cFill,
            shape: BoxShape.circle,
            border: Border.all(color: context.cBorder, width: 1.5),
          ),
          child: const Center(
            child: Text('−',
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400)),
          ),
        );
    }
  }

  Widget _buildResultBadge(MatchResult result) {
    switch (result) {
      case MatchResult.win:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
          ),
          child: const Text('승',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.w700)),
        );
      case MatchResult.lose:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
          ),
          child: const Text('패',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w700)),
        );
      case MatchResult.draw:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
          ),
          child: const Text('무',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w700)),
        );
      case MatchResult.none:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: context.cLine,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('미정',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
        );
    }
  }

  Widget _buildLegendItem(String symbol, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(symbol,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w700)),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon,
      {bool isOutside = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFEF4444)),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.cInk,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 14, color: context.cInk),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icon, size: 16, color: Colors.grey[400]),
        filled: true,
        fillColor: context.cFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
    );
  }
}

// 포켓몬 도감 ID -> PokemonInfo 변환 헬퍼
PokemonInfo? getPokemonById(int id) {
  try {
    return allPokemon.firstWhere((p) => p.id == id);
  } catch (e) {
    return null;
  }
}
