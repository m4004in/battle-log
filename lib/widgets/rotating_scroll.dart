import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Rotating Gallery(Originkit) 모션을 Flutter로 옮긴 세로 스크롤 리스트.
///
/// 원본 셰이더의 수학을 따른다:
///   position = 10 + 5 * (카드의 세로 위치 / 화면 높이)
///   phase    = fract(position * spin * 0.01)
///   angle    = qinticInOut(phase) * PI      ← 회전축(기본 Y)
///
/// 원본은 카드가 한 바퀴를 다 돌기 때문에 뒤집힌 면(거울상)이 보인다.
/// 글이 들어간 카드에서는 그 부분이 글자가 뒤집혀 보이므로, 여기서는
/// 회전을 90°까지만 쓰는 "리본 접힘"으로 옮겼다. 움직임의 결(가운데는
/// 평평, 화면 끝으로 갈수록 강하게 접혀 사라짐)은 원본과 같다.
///
/// 깜빡임 방지: 스크롤마다 setState를 하지 않고, 스크롤 오프셋만
/// ValueNotifier로 흘려보내 각 카드의 Transform만 갱신한다.
class RotatingScroll extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets padding;

  /// 화면 한 칸당 회전량 (원본 기본 5)
  final double spin;

  /// 리본 꼬임 강도 0~10 (원본 기본 3)
  final double twist;

  /// 카드 사이 간격
  final double gap;

  const RotatingScroll({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.spin = 5.0,
    this.twist = 3.0,
    this.gap = 0.0,
  });

  @override
  State<RotatingScroll> createState() => _RotatingScrollState();
}

class _RotatingScrollState extends State<RotatingScroll> {
  final ScrollController _controller = ScrollController();

  /// 스크롤 위치만 담는 노티파이어 (전체 리빌드 없이 Transform만 갱신)
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

  /// 원본 셰이더의 qinticInOut
  static double _qinticInOut(double t) {
    final x = t.clamp(0.0, 1.0);
    if (x < 0.5) return 16.0 * math.pow(x, 5).toDouble();
    return -0.5 * math.pow(2.0 * x - 2.0, 5).abs() + 1.0;
  }

  /// 카드 i의 회전 정보(라디안) — 화면 중앙 기준 거리로 계산
  double _angleFor(int i, double scroll) {
    if (_viewportH <= 0) return 0;
    final center = _centerInContent(i) - scroll;
    final rel = (center - _viewportH / 2) / _viewportH; // 화면 높이 기준 거리
    // 원본: 한 화면 이동당 spin*5*0.01 만큼 위상이 흐른다
    final u = (rel.abs() * widget.spin / 5.0).clamp(0.0, 1.0);
    final eased = _qinticInOut(u);
    // 90°까지만 (뒤집힌 면이 보이지 않도록)
    final mag = eased * (math.pi / 2) * 0.985;
    return rel.isNegative ? -mag : mag;
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
                      angleAt: (s) => _angleFor(i, s),
                      twist: widget.twist,
                      child: widget.itemBuilder(ctx, i),
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
  final double Function(double scroll) angleAt;
  final double twist;
  final Widget child;

  const _RotatingItem({
    super.key,
    required this.scrollY,
    required this.angleAt,
    required this.twist,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: scrollY,
      child: child,
      builder: (ctx, scroll, cachedChild) {
        final a = angleAt(scroll);
        final s = math.sin(a);
        final absSin = s.abs();
        final cos = math.cos(a);
        // 원본의 twist: 회전이 살짝 비틀리며 진행
        final tilt = (twist / 3.0) * 0.05;
        final scale = (0.86 + cos.abs() * 0.14).clamp(0.84, 1.0);
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0042) // 강한 원근
          ..rotateX(s * tilt)
          ..rotateY(a)
          ..rotateZ(s * tilt * 0.6)
          ..translateByDouble(s * 26.0, s.abs() * 8.0, -absSin * 150.0, 1.0)
          ..scaleByDouble(scale, scale, 1.0, 1.0);

        return Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: Opacity(
            // 옆면에 가까울수록 서서히 사라진다
            opacity: (1.0 - absSin * 0.55).clamp(0.25, 1.0),
            child: cachedChild,
          ),
        );
      },
    );
  }
}
