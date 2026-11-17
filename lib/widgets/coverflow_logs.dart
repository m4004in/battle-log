import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/tournament_record.dart';

typedef LogCardBuilder = Widget Function(
    BuildContext context, TournamentRecord record);
typedef LogOpenCallback = void Function(
    TournamentRecord record, Rect sourceRect, Widget card);

/// 3D 커버플로우 형태로 로그 카드를 넘겨보는 위젯.
/// - 옆으로 스와이프하면 카드가 회전하며 넘어간다.
/// - 가운데 카드를 탭하면 원래 위치에서 비율을 유지한 채 크게 확대된다.
class CoverflowLogs extends StatefulWidget {
  final List<TournamentRecord> records;
  final LogCardBuilder cardBuilder;
  final LogOpenCallback onOpen;

  const CoverflowLogs({
    super.key,
    required this.records,
    required this.cardBuilder,
    required this.onOpen,
  });

  @override
  State<CoverflowLogs> createState() => _CoverflowLogsState();
}

class _CoverflowLogsState extends State<CoverflowLogs> {
  late final PageController _controller =
      PageController(viewportFraction: 0.84);
  final Map<String, GlobalKey> _keys = {};
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_sync);
  }

  void _sync() {
    if (!mounted || !_controller.hasClients) return;
    final p = _controller.page;
    if (p == null || (p - _page).abs() < 0.002) return;
    setState(() => _page = p);
  }

  @override
  void dispose() {
    _controller.removeListener(_sync);
    _controller.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String id) => _keys.putIfAbsent(id, () => GlobalKey());

  void _handleTap(int index, TournamentRecord record) {
    if ((index - _page).abs() > 0.35) {
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    final ctx = _keyFor(record.id).currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.isEmpty) return;
    final origin = box.localToGlobal(Offset.zero);
    widget.onOpen(
      record,
      origin & box.size,
      widget.cardBuilder(context, record),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = widget.records;
    if (records.isEmpty) return const SizedBox.shrink();

    return PageView.builder(
      controller: _controller,
      clipBehavior: Clip.none,
      physics: const BouncingScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (ctx, i) {
        final record = records[i];
        final rel = (i - _page).clamp(-2.5, 2.5);
        final abs = rel.abs();
        final scale = (1 - abs * 0.11).clamp(0.70, 1.0);
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0016)
          ..rotateY(-rel * 0.30)
          ..translateByDouble(0.0, 0.0, -abs * 70.0, 1.0)
          ..scaleByDouble(scale, scale, 1.0, 1.0);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleTap(i, record),
          child: Transform(
            transform: matrix,
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 14, 6, 18),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: KeyedSubtree(
                  key: _keyFor(record.id),
                  child: Stack(
                    children: [
                      widget.cardBuilder(ctx, record),
                      // 모션 중에도 대회 이름이 잘 보이도록 카드 위에 캡션
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _caption(record, (1 - abs * 0.45).clamp(0.35, 1.0)),
                        ),
                      ),
                      // 양옆 카드는 살짝 어둡게
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black
                                  .withValues(alpha: (abs * 0.26).clamp(0.0, 0.5)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _caption(TournamentRecord record, double opacity) {
    final w = record.totalWins;
    final l = record.totalLoses;
    final d = record.totalDraws;
    final recordText = d > 0 ? '$w-$l-$d' : '$w-$l';

    return Align(
      alignment: Alignment.bottomCenter,
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 30, 14, 12),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(14),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.0),
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0.82),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  record.tournamentName.isEmpty ? '대회명 없음' : record.tournamentName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    recordText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('yyyy.MM.dd').format(record.date),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 카드를 원래 자리에서 비율 그대로 확대해서 보여주는 오버레이.
Future<void> showExpandedLog(
  BuildContext context, {
  required Widget card,
  required Rect from,
  void Function(BuildContext routeContext)? onEdit,
  void Function(BuildContext routeContext)? onDelete,
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.64),
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (ctx, anim, secondary) => _ExpandedLog(
        card: card,
        from: from,
        anim: anim,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    ),
  );
}

class _ExpandedLog extends StatelessWidget {
  final Widget card;
  final Rect from;
  final Animation<double> anim;
  final void Function(BuildContext routeContext)? onEdit;
  final void Function(BuildContext routeContext)? onDelete;

  const _ExpandedLog({
    required this.card,
    required this.from,
    required this.anim,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final faded = CurvedAnimation(
      parent: anim,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );

    return LayoutBuilder(
      builder: (ctx, box) {
        final maxW = box.maxWidth;
        final maxH = box.maxHeight;
        final srcW = from.width <= 0 ? 1.0 : from.width;
        final srcH = from.height <= 0 ? 1.0 : from.height;

        // 화면에 들어가는 만큼만 키우되 가로/세로 비율은 그대로 유지한다.
        final fitScale = math.min(
          (maxW - 24) / srcW,
          (maxH - 140) / srcH,
        );
        final targetScale = fitScale.clamp(0.6, 4.0);
        final targetW = srcW * targetScale;
        final targetH = srcH * targetScale;
        final center = Offset(maxW / 2, (maxH - 40) / 2 + 6);

        return ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: anim,
                builder: (c, _) {
                  final t = Curves.easeOutCubic
                      .transform(anim.value.clamp(0.0, 1.0));
                  final k = ui.lerpDouble(from.width / targetW, 1.0, t)!;
                  final cx = ui.lerpDouble(from.center.dx, center.dx, t)!;
                  final cy = ui.lerpDouble(from.center.dy, center.dy, t)!;

                  return Positioned(
                    left: 0,
                    top: 0,
                    child: Transform(
                      alignment: Alignment.topLeft,
                      transform: Matrix4.identity()
                        ..translateByDouble(
                            cx - targetW * k / 2, cy - targetH * k / 2, 0.0, 1.0)
                        ..scaleByDouble(k, k, 1.0, 1.0),
                      child: SizedBox(
                        width: targetW,
                        height: targetH,
                        child: Material(
                          color: Colors.transparent,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: card,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                left: 8,
                top: MediaQuery.of(ctx).padding.top + 4,
                child: FadeTransition(
                  opacity: faded,
                  child: _roundButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: '뒤로',
                    onTap: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: MediaQuery.of(ctx).padding.top + 4,
                child: FadeTransition(
                  opacity: faded,
                  child: Row(
                    children: [
                      if (onEdit != null)
                        _roundButton(
                          icon: Icons.edit_outlined,
                          tooltip: '수정',
                          onTap: () => onEdit!(ctx),
                        ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 8),
                        _roundButton(
                          icon: Icons.delete_outline_rounded,
                          tooltip: '삭제',
                          onTap: () => onDelete!(ctx),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _roundButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }
}
