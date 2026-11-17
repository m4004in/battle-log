import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Rotating Gallery (Originkit) 의 움직임을 Flutter로 옮긴 스크롤 리스트.
///
/// 원본 셰이더의 수학을 그대로 따른다:
///   position = 10 + 5 * (카드의 세로 위치 / 화면 높이)
///   phase    = fract(position * spin * 0.01)
///   angle    = qinticInOut(phase) * PI      ← 회전축(기본 Y) 기준 회전
///
/// 카드는 스크롤에 따라 Y축으로 돌아가고, 옆면을 향할수록 흐려진다.
class RotatingScroll extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets padding;

  /// 화면 한 칸당 회전량. 클수록 빠르게 돈다.
  final double spin;

  /// 리본 꼬임 강도(0~10).
  final double twist;

  /// 회전 위상 시작값
  final double phaseOffset;

  /// 항목 사이 추가 간격 (카드 자체 여백과 별개)
  final double gap;

  const RotatingScroll({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.spin = 9.0,
    this.twist = 3.0,
    this.phaseOffset = 0.0,
    this.gap = 0.0,
  });

  @override
  State<RotatingScroll> createState() => _RotatingScrollState();
}

class _RotatingScrollState extends State<RotatingScroll> {
  final ScrollController _controller = ScrollController();
  final List<GlobalKey> _keys = [];
  final List<double> _heights = [];
  double _offset = 0;
  double _viewportH = 0;
  bool _measureScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted || !_controller.hasClients) return;
    final o = _controller.offset;
    if ((o - _offset).abs() < 0.5) return;
    setState(() => _offset = o);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _scheduleMeasure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) return;
      var changed = false;
      for (var i = 0; i < _keys.length; i++) {
        final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) continue;
        final h = box.size.height;
        if (i >= _heights.length) {
          _heights.add(h);
          changed = true;
        } else if ((_heights[i] - h).abs() > 0.5) {
          _heights[i] = h;
          changed = true;
        }
      }
      if (changed) setState(() {});
    });
  }

  /// 항목 i의 화면상 세로 중심 (뷰포트 상단 기준)
  double _centerY(int i) {
    var y = widget.padding.top;
    for (var k = 0; k < i; k++) {
      y += (_heights.length > k ? _heights[k] : 0) + widget.gap;
    }
    final h = _heights.length > i ? _heights[i] : 0;
    return y + h / 2 - _offset;
  }

  /// 원본의 qinticInOut
  static double _qinticInOut(double t) {
    final x = t.clamp(0.0, 2.0);
    if (x < 0.5) return 16.0 * math.pow(x, 5).toDouble();
    return -0.5 * math.pow(2.0 * x - 2.0, 5).abs() + 1.0;
  }

  double _phaseFor(int i) {
    if (_viewportH <= 0) return 0;
    final rel = (_centerY(i) - _viewportH / 2) / _viewportH;
    final position = 10 + 5 * rel;
    final raw = position * widget.spin * 0.01 + widget.phaseOffset;
    return raw - raw.floorToDouble();
  }

  double _angleFor(int i) {
    final p = _phaseFor(i);
    final shift = (widget.twist.clamp(0.0, 10.0) * 0.01) / 2;
    final t = ((p - shift) / (1 - shift * 2)).clamp(0.0, 1.0);
    return _qinticInOut(t) * math.pi;
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.itemCount;
    while (_keys.length < count) {
      _keys.add(GlobalKey());
    }
    _scheduleMeasure();

    return LayoutBuilder(
      builder: (ctx, box) {
        _viewportH = box.maxHeight;
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(ctx).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            padding: widget.padding,
            child: Column(
              children: [
                for (var i = 0; i < count; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: widget.gap),
                    child: Transform(
                      key: _keys[i],
                      alignment: Alignment.center,
                      transform: _matrixFor(i),
                      child: Opacity(
                        opacity: _opacityFor(i),
                        child: widget.itemBuilder(ctx, i),
                      ),
                    ),
                  ),
                SizedBox(height: math.max(140.0, _viewportH * 0.3)),
              ],
            ),
          ),
        );
      },
    );
  }

  double _opacityFor(int i) {
    final sinA = math.sin(_angleFor(i)).abs();
    return (1.0 - sinA * 0.9).clamp(0.06, 1.0);
  }

  Matrix4 _matrixFor(int i) {
    final a = _angleFor(i);
    final sinA = math.sin(a).abs();
    final scale = (1.0 - sinA * 0.10).clamp(0.82, 1.0);
    return Matrix4.identity()
      ..setEntry(3, 2, 0.0022)
      ..rotateX(-sinA * 0.06)
      ..rotateY(a)
      ..rotateZ(math.sin(a) * 0.035)
      ..translateByDouble(math.sin(a) * 10, 0.0, -sinA * 60.0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }
}
