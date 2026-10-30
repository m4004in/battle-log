import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 다크모드 상태 (저장됨)
class ThemeController extends ChangeNotifier {
  static const String _key = 'dark_mode';
  bool _dark = false;
  bool get isDark => _dark;

  ThemeController() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool(_key) ?? false;
      if (v != _dark) {
        _dark = v;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> toggle() async {
    _dark = !_dark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, _dark);
    } catch (_) {}
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
  Color get cSurface => isDark ? _dSurface : Colors.white;
  Color get cBg => isDark ? _dBg : const Color(0xFFFAFAFA);
  Color get cInk => isDark ? _dInk : const Color(0xFF0F172A);
  Color get cSlate => isDark ? _dSlate : const Color(0xFF64748B);
  Color get cLine => isDark ? _dLine : const Color(0xFFF0F0F0);
  Color get cBorder =>
      isDark ? const Color(0xFF4A4B52) : const Color(0xFFE2E8F0);
  Color get cFill => isDark ? _dFill : const Color(0xFFF5F5F5);
  Color get cTint => isDark ? const Color(0xFF3B2A2D) : const Color(0xFFFEF2F2);
  Color get cExportBg => isDark ? _dBg : const Color(0xFFF5F5F7);
}

/// 앱바용 전구 버튼 (눌러서 다크모드 전환)
class ThemeBulbButton extends StatelessWidget {
  const ThemeBulbButton({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return IconButton(
      tooltip: dark ? '라이트 모드' : '다크 모드',
      onPressed: () => context.read<ThemeController>().toggle(),
      icon: Icon(
        dark ? Icons.lightbulb_outline_rounded : Icons.lightbulb_rounded,
        color: dark ? const Color(0xFFA3A8B3) : const Color(0xFFF59E0B),
        size: 24,
      ),
    );
  }
}
