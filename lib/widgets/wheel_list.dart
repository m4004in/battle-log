import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 세로 스크롤을 하면서 각 항목이 물레방아처럼 돌아가는 3D 리스트.
/// 화면 중앙에서 멀어진 항목은 X축으로 기울고 뒤로 물러나며 작아진다.
class WheelList extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets padding;

  /// 3D 강도 (클수록 강하게 기울고 멀리 물러난다)
  final double strength;

  const WheelList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.strength = 1.0,
  });

  @override
  State<WheelList> createState() => _WheelListState();
}

class _WheelListState extends State<WheelList> {
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
        final h = _keys[i].currentContext?.size?.height ?? 0;
        if (h <= 0) continue;
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

  double get _contentTop => widget.padding.top;

  /// 항목 i의 화면상 중심 좌표 (스크롤 위치 반영) - 뷰포트 상단 기준
  double _centerY(int i) {
    var y = _contentTop;
    for (var k = 0; k < i; k++) {
      y += (_heights.length > k ? _heights[k] : 0);
    }
    final h = _heights.length > i ? _heights[i] : 0;
    return y + h / 2 - _offset;
  }

  Matrix4 _transformFor(int i) {
    if (_viewportH <= 0) return Matrix4.identity();
    final center = _centerY(i);
    // -1(위 끝) ~ 0(중앙) ~ 1(아래 끝)
    final rel = ((center - _viewportH / 2) / (_viewportH / 2)).clamp(-1.6, 1.6);
    final abs = rel.abs();
    final s = widget.strength;
    final scale = (1 - abs * 0.13 * s).clamp(0.55, 1.0);
    return Matrix4.identity()
      ..setEntry(3, 2, 0.0022)
      ..rotateX(-rel * 0.42 * s)
      ..translateByDouble(0.0, 0.0, -abs * 190.0 * s, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }

  double _opacityFor(int i) {
    if (_viewportH <= 0) return 1;
    final center = _centerY(i);
    final rel = ((center - _viewportH / 2) / (_viewportH / 2)).abs();
    return (1 - rel * 0.45).clamp(0.12, 1.0);
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
          behavior: ScrollConfiguration.of(ctx).copyWith(
            scrollbars: false,
            overscroll: false,
          ),
          child: SingleChildScrollView(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            padding: widget.padding,
            child: Column(
              children: [
                for (var i = 0; i < count; i++)
                  Transform(
                    key: _keys[i],
                    alignment: Alignment.center,
                    transform: _transformFor(i),
                    child: Opacity(
                      opacity: _opacityFor(i),
                      child: widget.itemBuilder(ctx, i),
                    ),
                  ),
                SizedBox(height: math.max(160.0, _viewportH * 0.35)),
              ],
            ),
          ),
        );
      },
    );
  }
}
