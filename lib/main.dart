import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'providers/tournament_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'utils/boot_signal.dart';

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
  const assets = [
    'assets/fonts/NotoSansKR-Regular.ttf',
    'assets/fonts/NotoSansKR-Bold.ttf',
  ];

  Future<void> loadOnce() async {
    final loader = FontLoader(family);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  try {
    await loadOnce().timeout(const Duration(seconds: 4));
  } catch (_) {
    // 실패/지연되면 한 번 더 시도하되, 그래도 안 되면 그냥 진행한다.
    try {
      await loadOnce();
    } catch (_) {}
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

/// 폰트 로딩이 끝날 때까지 앱 화면을 그리지 않는다 (두부 노출 방지).
///
/// HTML 쪽 부팅 스플래시가 이미 화면을 덮고 있으므로, 여기서는 같은 색 배경만
/// 칠하다가 준비가 끝나면 실제 화면으로 바꾼다.
class _StartupGate extends StatefulWidget {
  const _StartupGate({required this.child, this.ready});

  final Widget child;
  final Future<void>? ready;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _done = false;
  bool _signaled = false;

  @override
  void initState() {
    super.initState();
    final ready = widget.ready;
    if (ready == null) {
      _done = true;
      _scheduleSignal();
      return;
    }
    ready.whenComplete(() {
      if (!mounted) return;
      setState(() => _done = true);
      _scheduleSignal();
    });
  }

  /// 첫 프레임이 실제로 그려진 뒤에 HTML 스플래시를 걷는다.
  /// (폰트가 등록된 상태의 프레임만 노출되도록 보장)
  void _scheduleSignal() {
    if (_signaled) return;
    _signaled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // 다음 프레임까지 한 번 더 기다려 폰트 적용 프레임을 보장한다
      SchedulerBinding.instance.addPostFrameCallback((_) {
        signalBootReady();
      });
    });
    // setState 이후 프레임을 요청한다
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    if (!_done) {
      return const ColoredBox(color: Color(0xFFFAFAFA));
    }
    return widget.child;
  }
}
