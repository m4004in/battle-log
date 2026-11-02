import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 화면 테마 3종: 흰색 -> 다크 -> 배경 이미지 순서로 돈다.
enum AppThemeMode { light, dark, art }

class ThemeController extends ChangeNotifier {
  static const String _key = 'theme_mode';
  static const String _legacyKey = 'dark_mode';
  AppThemeMode _mode = AppThemeMode.light;
  AppThemeMode get mode => _mode;
  bool get isDark => _mode == AppThemeMode.dark;
  bool get isArt => _mode == AppThemeMode.art;

  ThemeController() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_key);
      final AppThemeMode v;
      if (saved != null && saved >= 0 && saved < AppThemeMode.values.length) {
        v = AppThemeMode.values[saved];
      } else {
        v = (prefs.getBool(_legacyKey) ?? false)
            ? AppThemeMode.dark
            : AppThemeMode.light;
      }
      if (v != _mode) {
        _mode = v;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> toggle() async {
    _mode = AppThemeMode.values[(_mode.index + 1) % AppThemeMode.values.length];
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, _mode.index);
    } catch (_) {}
  }
}

/// 배경 이미지 테마용: 원본 그대로, 비율 유지하며 화면에 맞게 잘라서 채운다.
/// 가로 화면(데스크탑)에서는 사진을 90도 눕혀서 가로로 보여준다.
class ArtBackground extends StatelessWidget {
  const ArtBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final landscape = c.maxWidth > c.maxHeight;
        final img = Image.asset(
          'assets/bg/bg.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        );
        return RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFFFAFAFA)),
              landscape ? RotatedBox(quarterTurns: 1, child: img) : img,
            ],
          ),
        );
      },
    );
  }
}

const Color kRed = Color(0xFFEF4444);

// 다크 팔레트 (완전 검정 X, 아주 짙은 다크 그레이)
const Color _dBg = Color(0xFF1E1F22);
const Color _dSurface = Color(0xFF2A2B2F);
const Color _dFill = Color(0xFF35363B);
const Color _dLine = Color(0xFF3C3D43);
const Color _dInk = Color(0xFFF2F2F4);
const Color _dSlate = Color(0xFFA3A8B3);

ThemeData buildLightTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: kRed,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: 'sans-serif',
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

/// 배경 이미지 테마: 라이트 팔레트 + 투명 스캐폴드
ThemeData buildArtTheme() =>
    buildLightTheme().copyWith(scaffoldBackgroundColor: Colors.transparent);

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kRed,
    brightness: Brightness.dark,
  ).copyWith(
    surface: _dSurface,
    onSurface: _dInk,
    primary: kRed,
    onPrimary: Colors.white,
    surfaceContainerHighest: _dFill,
    outline: _dLine,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'sans-serif',
    scaffoldBackgroundColor: _dBg,
    canvasColor: _dSurface,
    cardColor: _dSurface,
    dividerColor: _dLine,
    textTheme: ThemeData(brightness: Brightness.dark)
        .textTheme
        .apply(bodyColor: _dInk, displayColor: _dInk),
    iconTheme: const IconThemeData(color: _dInk),
    appBarTheme: const AppBarTheme(
      backgroundColor: _dSurface,
      foregroundColor: _dInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: _dInk,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: _dSurface,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF45464C),
      contentTextStyle: TextStyle(color: _dInk),
    ),
  );
}

/// 라이트/다크에 맞는 색 팔레트
extension AppPalette on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  // 배경 이미지 테마 (스캐폴드가 투명한 경우)
  bool get isArt => Theme.of(this).scaffoldBackgroundColor == Colors.transparent;
  /// 기록 카드 바탕: 배경 이미지 테마에서만 살짝 투명
  Color get cCard => isArt ? Colors.white.withValues(alpha: 0.74) : cSurface;
  /// 기록 카드 하단 힌트 줄 바탕
  Color get cCardTint =>
      isArt ? const Color(0xFFFEF2F2).withValues(alpha: 0.6) : cTint;
  Color get cSurface => isDark ? _dSurface : Colors.white;
  Color get cBg => Theme.of(this).scaffoldBackgroundColor;
  Color get cInk => isDark ? _dInk : const Color(0xFF0F172A);
  Color get cSlate => isDark ? _dSlate : const Color(0xFF64748B);
  Color get cLine => isDark ? _dLine : const Color(0xFFF0F0F0);
  Color get cBorder =>
      isDark ? const Color(0xFF4A4B52) : const Color(0xFFE2E8F0);
  Color get cFill => isDark ? _dFill : const Color(0xFFF5F5F5);
  Color get cTint => isDark ? const Color(0xFF3B2A2D) : const Color(0xFFFEF2F2);
  Color get cExportBg => isDark ? _dBg : const Color(0xFFF5F5F7);
}

/// 앱바용 전구 버튼 (눌러서 흰색 -> 다크 -> 배경 이미지 순환)
class ThemeBulbButton extends StatelessWidget {
  const ThemeBulbButton({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeController>().mode;
    late final IconData icon;
    late final Color color;
    late final String tip;
    switch (mode) {
      case AppThemeMode.light:
        icon = Icons.lightbulb_rounded;
        color = const Color(0xFFF59E0B);
        tip = '다크 모드로';
        break;
      case AppThemeMode.dark:
        icon = Icons.lightbulb_outline_rounded;
        color = const Color(0xFFA3A8B3);
        tip = '배경 이미지로';
        break;
      case AppThemeMode.art:
        icon = Icons.auto_awesome_rounded;
        color = const Color(0xFFEC4899);
        tip = '흰색 모드로';
        break;
    }
    return IconButton(
      tooltip: tip,
      onPressed: () => context.read<ThemeController>().toggle(),
      icon: Icon(icon, color: color, size: 24),
    );
  }
}
