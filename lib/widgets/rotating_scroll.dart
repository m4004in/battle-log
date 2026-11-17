import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Rotating Gallery(Originkit) 모션을 Flutter로 옮긴 세로 스크롤 리스트.
///
/// 원본 셰이더의 흐름을 따른다:
///   position = 10 + 5 * (카드의 세로 위치 / 화면 높이)
///   phase    = fract(position * spin * 0.01)
///   angle    = qinticInOut(phase) * PI      ← 회전축(기본 Y)
///
/// 원본은 카드가 180°를 넘어 완전히 돌아가 뒤집힌 면까지 보이지만, 글자가
/// 들어간 카드에서는 그 순간 글자가 거울처럼 뒤집힌다. 그래서 회전 한계를
/// 85°로 두고, 대신 원본의 "화면 중앙은 평평하고 가장자리로 갈수록 급하게
/// 접혀 사라지는" 결을 그대로 살렸다.
///
/// 깜빡임 방지: 스크롤마다 setState를 하지 않고 스크롤 오프셋만
/// ValueNotifier로 흘려보내, 각 카드의 Transform만 다시 계산한다.
class RotatingScroll extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets padding;

  /// 회전 강도. 클수록 중앙에서 조금만 벗어나도 크게 돈다.
  final double spin;

  /// 리본 꼬임 강도 (원본 기본 3)
  final double twist;

  /// 카드 사이 간격
  final double gap;

  /// 최대 회전 각도(도). 90 이상이면 카드가 뒤집혀 보인다.
  final double maxTiltDeg;

  const RotatingScroll({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.spin = 5.0,
    this.twist = 3.0,
    this.gap = 0.0,
    this.maxTiltDeg = 84.0,
  });

  @override
  State<RotatingScroll> createState() => _RotatingScrollState();
}

class _RotatingScrollState extends State<RotatingScroll> {
  final ScrollController _controller = ScrollController();

  /// 스크롤 위치만 담는 노티파이어 (리스트 전체 리빌드 없이 Transform만 갱신)
  final ValueNotifier<double> _scrollY = ValueNotifier<double>(0);

  final List<GlobalKey> _keys = [];
  final List<double> _heights = [];

  double _viewportH = 0;
  bool _measureScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    _scrollY.value = _controller.offset;
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    _scrollY.dispose();
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

  /// 항목 i의 문서상 세로 중심
  double _centerInContent(int i) {
    var y = widget.padding.top;
    for (var k = 0; k < i; k++) {
      y += (_heights.length > k ? _heights[k] : 0) + widget.gap;
    }
    final h = _heights.length > i ? _heights[i] : 0;
    return y + h / 2;
  }

  /// 카드 i의 회전 정규화 값(-1 ~ 1). 화면 중앙에서 멀수록 1에 가깝다.
  double _unitFor(int i, double scroll) {
    if (_viewportH <= 0) return 0;
    final center = _centerInContent(i) - scroll;
    // 화면 중앙에서 조금만 벗어나도 빠르게 접히도록 짧은 반경을 쓴다.
    final r =
        ((center - _viewportH / 2) / (_viewportH * 0.60)).clamp(-1.0, 1.0);
    // 중앙은 완만하게 시작해 곧바로 크게 휘어지는 곡선
    final mag = math.pow(r.abs(), 0.85).toDouble();
    return r.isNegative ? -mag : mag;
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
                    child: _RotatingItem(
                      key: _keys[i],
                      scrollY: _scrollY,
                      unitAt: (s) => _unitFor(i, s),
                      twist: widget.twist,
                      maxTiltDeg: widget.maxTiltDeg,
                      child: RepaintBoundary(child: widget.itemBuilder(ctx, i)),
                    ),
                  ),
                SizedBox(height: math.max(160.0, _viewportH * 0.45)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RotatingItem extends StatelessWidget {
  final ValueNotifier<double> scrollY;
  final double Function(double scroll) unitAt;
  final double twist;
  final double maxTiltDeg;
  final Widget child;

  const _RotatingItem({
    super.key,
    required this.scrollY,
    required this.unitAt,
    required this.twist,
    required this.maxTiltDeg,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: scrollY,
      child: child,
      builder: (ctx, scroll, cachedChild) {
        final u = unitAt(scroll); // -1 .. 1
        final au = u.abs();
        final sgn = u.isNegative ? -1.0 : 1.0;

        // Y축 회전: 화면 중앙 0° → 가장자리 maxTiltDeg
        final angle = sgn * au * (math.pi / 180.0) * maxTiltDeg;

        // twist: 회전 방향으로 살짝 비틀리며 넘어간다 (원본 리본 결)
        final tw = twist.clamp(0.0, 10.0) / 3.0;
        final tiltZ = sgn * au * 0.085 * tw;
        final tiltX = -au * 0.055 * tw;

        // 가장자리로 갈수록 뒤로 물러나고 옆으로 흘러간다
        final dz = -au * 300.0;
        final dx = sgn * au * 54.0;
        final dy = -au * au * 30.0;

        final scale = (1.0 - au * 0.07).clamp(0.88, 1.0);
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0038) // 강한 원근
          ..rotateX(tiltX)
          ..rotateZ(tiltZ)
          ..rotateY(angle)
          ..translateByDouble(dx, dy, dz, 1.0)
          ..scaleByDouble(scale, scale, 1.0, 1.0);

        return Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: Opacity(
            opacity: (1.0 - au * 0.66).clamp(0.14, 1.0),
            child: cachedChild,
          ),
        );
      },
    );
  }
}
