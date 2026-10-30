import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';
import '../models/tournament_record.dart';

/// 월별 캘린더 화면.
/// - 항상 현재 달로 시작, 좌우 스와이프/화살표로 이전·다음 달 이동
/// - 대회가 있는 날짜에 아이콘 표시 (그날 승패 우세에 따라 색 변경)
/// - 날짜를 누르면 그날의 대회 기록(승패 로그)이 아래에 표시
class CalendarScreen extends StatefulWidget {
  /// 홈 화면과 동일한 로그 카드 디자인을 그려주는 빌더
  final Widget Function(TournamentRecord record) cardBuilder;

  /// 카드를 눌렀을 때 편집 화면으로 이동
  final void Function(BuildContext context, TournamentRecord record) onEdit;

  const CalendarScreen({
    super.key,
    required this.cardBuilder,
    required this.onEdit,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const int _basePage = 1200;
  static const Color _kRed = Color(0xFFEF4444);
  static const List<String> _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  late final PageController _pageController;
  late final DateTime _now;
  int _page = _basePage;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _selected = DateTime(_now.year, _now.month, _now.day);
    _pageController = PageController(initialPage: _basePage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthOf(int page) =>
      DateTime(_now.year, _now.month + (page - _basePage));

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<TournamentRecord> _recordsOn(List<TournamentRecord> all, DateTime day) {
    return all.where((r) => _sameDay(r.date, day)).toList();
  }

  List<TournamentRecord> _recordsInMonth(
      List<TournamentRecord> all, DateTime month) {
    final list = all
        .where((r) => r.date.year == month.year && r.date.month == month.month)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Color _dayColor(List<TournamentRecord> rs) {
    final w = rs.fold<int>(0, (s, r) => s + r.totalWins);
    final l = rs.fold<int>(0, (s, r) => s + r.totalLoses);
    if (w > l) return const Color(0xFF059669);
    if (l > w) return const Color(0xFFDC2626);
    return const Color(0xFFD97706);
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _goToday() {
    setState(() => _selected = DateTime(_now.year, _now.month, _now.day));
    if (_page == _basePage) return;
    _goTo(_basePage);
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<TournamentProvider>().records;
    final month = _monthOf(_page);
    final isCurrentMonth = _page == _basePage;

    final List<TournamentRecord> shown;
    final String listTitle;
    if (_selected != null &&
        _selected!.year == month.year &&
        _selected!.month == month.month) {
      shown = _recordsOn(all, _selected!);
      listTitle = '${_selected!.month}월 ${_selected!.day}일 기록';
    } else {
      shown = _recordsInMonth(all, month);
      listTitle = '${month.month}월 전체 기록';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: context.cSurface,
        elevation: 0,
        leading: IconButton(
          tooltip: '뒤로가기',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          '월별 기록',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.cInk,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Material(
                color: isCurrentMonth &&
                        _selected != null &&
                        _sameDay(_selected!, _now)
                    ? context.cFill
                    : Colors.white,
                shape: StadiumBorder(side: BorderSide(color: context.cBorder)),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: _goToday,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text('오늘',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: context.cInk)),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.cLine),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildMonthHeader(month),
                _buildWeekdayRow(),
                SizedBox(
                  height: 6 * 54.0,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (p) => setState(() {
                      _page = p;
                      final m = _monthOf(p);
                      // 현재 달로 돌아오면 오늘 선택, 그 외에는 월 전체 보기
                      _selected = (m.year == _now.year && m.month == _now.month)
                          ? DateTime(_now.year, _now.month, _now.day)
                          : null;
                    }),
                    itemBuilder: (ctx, p) => _buildMonthGrid(_monthOf(p), all),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          Divider(height: 1, color: context.cLine),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(listTitle,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.cInk)),
                const SizedBox(width: 6),
                Text('${shown.length}개',
                    style: TextStyle(fontSize: 13, color: context.cSlate)),
              ],
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy_rounded,
                            size: 36, color: Colors.grey[350]),
                        const SizedBox(height: 8),
                        Text(
                            _selected == null
                                ? '이 달은 대회 기록이 없어요'
                                : '이 날은 대회 기록이 없어요',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[500])),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: shown.length,
                    itemBuilder: (ctx, i) => GestureDetector(
                      onTap: () => widget.onEdit(context, shown[i]),
                      child: widget.cardBuilder(shown[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── 월 헤더: ‹  2026년 10월  ›
  Widget _buildMonthHeader(DateTime month) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: '이전 달',
            icon: const Icon(Icons.chevron_left_rounded, size: 30),
            color: context.cInk,
            onPressed: () => _goTo(_page - 1),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${month.year}년 ${month.month}월',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.cInk,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '다음 달',
            icon: const Icon(Icons.chevron_right_rounded, size: 30),
            color: context.cInk,
            onPressed: () => _goTo(_page + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: List.generate(7, (i) {
          final color = i == 0
              ? const Color(0xFFEF4444)
              : i == 6
                  ? const Color(0xFF3B82F6)
                  : context.cSlate;
          return Expanded(
            child: Center(
              child: Text(_weekdays[i],
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ),
          );
        }),
      ),
    );
  }

  // ── 한 달 그리드 (항상 6줄 고정 → 달 이동 시 높이 흔들림 없음)
  Widget _buildMonthGrid(DateTime month, List<TournamentRecord> all) {
    final first = DateTime(month.year, month.month, 1);
    final leading = first.weekday % 7; // 일요일 시작
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: List.generate(6, (row) {
          return SizedBox(
            height: 54,
            child: Row(
              children: List.generate(7, (col) {
                final dayNum = row * 7 + col - leading + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox.shrink());
                }
                final date = DateTime(month.year, month.month, dayNum);
                return Expanded(child: _buildDayCell(date, col, all));
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayCell(DateTime date, int col, List<TournamentRecord> all) {
    final rs = _recordsOn(all, date);
    final has = rs.isNotEmpty;
    final isToday = _sameDay(date, _now);
    final isSel = _selected != null && _sameDay(date, _selected!);

    Color numColor = col == 0
        ? const Color(0xFFEF4444)
        : col == 6
            ? const Color(0xFF3B82F6)
            : context.cInk;
    if (isSel) numColor = Colors.white;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() {
          if (_selected != null && _sameDay(_selected!, date)) {
            _selected = null; // 다시 누르면 월 전체 보기
          } else {
            _selected = date;
          }
        }),
        child: Container(
          decoration: BoxDecoration(
            color: isSel ? _kRed : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border:
                isToday && !isSel ? Border.all(color: _kRed, width: 1.5) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: (isToday || isSel || has)
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: numColor,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 16,
                child: has
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isSel ? Colors.white : _dayColor(rs),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.catching_pokemon,
                              size: 11,
                              color: isSel ? _kRed : Colors.white,
                            ),
                          ),
                          if (rs.length > 1) ...[
                            const SizedBox(width: 2),
                            Text(
                              '${rs.length}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isSel ? Colors.white : _dayColor(rs),
                              ),
                            ),
                          ],
                        ],
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
