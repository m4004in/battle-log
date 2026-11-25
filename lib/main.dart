import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/tournament_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 폰트 로딩을 기다렸다가 앱을 띄운다 (두부현상 방지)
  runApp(BattleLogApp(ready: _preloadKoreanFont()));
}

/// 첫 프레임 전에 한글 폰트를 미리 로드한다.
///
/// 폰트가 번들에 있어도 CanvasKit 이 등록하기 전에 프레임이 그려지면
/// 글자가 네모(두부)로 보인다. 로드가 끝난 뒤에 화면을 그리게 해서 막는다.
Future<void> _preloadKoreanFont() async {
  const family = 'NotoSansKR';
  try {
    final loader = FontLoader(family);
    loader.addFont(rootBundle.load('assets/fonts/NotoSansKR-Regular.ttf'));
    loader.addFont(rootBundle.load('assets/fonts/NotoSansKR-Bold.ttf'));
    await loader.load();
  } catch (_) {
    // 폰트 로드 실패해도 앱은 떠야 한다
  }
}

class BattleLogApp extends StatelessWidget {
  const BattleLogApp({super.key, this.ready});

  /// 준비(폰트 로딩) 완료 신호. null 이면 즉시 시작.
  final Future<void>? ready;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Battle Log',
          debugShowCheckedModeBanner: false,
          theme: theme.isArt ? buildArtTheme() : buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
          themeAnimationDuration: const Duration(milliseconds: 250),
          builder: (context, child) => Stack(
            fit: StackFit.expand,
            children: [
              if (theme.isArt) const ArtBackground(),
              if (child != null) child,
            ],
          ),
          home: _StartupGate(ready: ready, child: const HomeScreen()),
        ),
      ),
    );
  }
}

/// 폰트 로딩이 끝날 때까지 흰 배경만 보여준다 (두부 노출 방지).
class _StartupGate extends StatefulWidget {
  const _StartupGate({required this.child, this.ready});

  final Widget child;
  final Future<void>? ready;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final ready = widget.ready;
    if (ready == null) {
      _done = true;
      return;
    }
    ready.whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_done) {
      return const ColoredBox(color: Color(0xFFFAFAFA));
    }
    return widget.child;
  }
}
