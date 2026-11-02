import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/tournament_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const BattleLogApp());
}

class BattleLogApp extends StatelessWidget {
  const BattleLogApp({super.key});

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
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
