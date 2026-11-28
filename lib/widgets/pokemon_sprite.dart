import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 포켓몬 스프라이트를 그린다.
///
/// 대부분은 PokeAPI 네트워크 이미지지만, 앱에 내장한 스프라이트
/// (예: 직접 만든 '해머' 카드)는 에셋에서 읽는다.
class PokemonSprite extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final FilterQuality filterQuality;

  /// 네트워크 로딩 중 보여줄 위젯
  final Widget Function(BuildContext, String)? placeholder;

  /// 로딩 실패 시 보여줄 위젯
  final Widget Function(BuildContext, String, Object)? errorWidget;

  const PokemonSprite({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.none,
    this.placeholder,
    this.errorWidget,
  });

  /// 에셋 경로인지 판별
  static bool isAsset(String url) => url.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    if (isAsset(url)) {
      // 내장 스프라이트는 즉시 로드되므로 placeholder 가 필요 없다.
      // 내장 스프라이트도 도트로 그려져 있어 네트워크 스프라이트와 같은 필터를 쓴다.
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        filterQuality: filterQuality,
        errorBuilder: (c, e, s) => errorWidget?.call(c, url, e) ??
            const SizedBox.shrink(),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      placeholder: placeholder ?? (c, u) => const SizedBox.shrink(),
      errorWidget: errorWidget ?? (c, u, e) => const SizedBox.shrink(),
    );
  }
}
