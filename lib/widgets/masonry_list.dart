import 'package:flutter/material.dart';

/// 카드 목록.
/// - 폭 700 미만(핸드폰): 기존과 동일한 세로 한 줄 ListView
/// - 폭 700 이상(데스크탑): 카드 가로 폭은 핸드폰 비율 그대로 두고 여러 열로 나열
class MasonryList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsets padding;

  static const double wideBreakpoint = 700;
  static const double targetCardWidth = 430;
  static const double gap = 16;

  const MasonryList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < wideBreakpoint) {
          return ListView.builder(
            padding: padding,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          );
        }
        final avail = constraints.maxWidth - padding.horizontal;
        final cols =
            ((avail + gap) / (targetCardWidth + gap)).round().clamp(1, 8);
        final colWidth = (avail - gap * (cols - 1)) / cols;

        final columns = List.generate(cols, (_) => <Widget>[]);
        for (var i = 0; i < itemCount; i++) {
          columns[i % cols].add(itemBuilder(context, i));
        }
        return SingleChildScrollView(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < cols; c++) ...[
                if (c > 0) const SizedBox(width: gap),
                SizedBox(
                  width: colWidth,
                  child: Column(children: columns[c]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
