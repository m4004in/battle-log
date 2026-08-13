import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/tournament_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BattleLogApp());
}

class BattleLogApp extends StatelessWidget {
  const BattleLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TournamentProvider(),
      child: MaterialApp(
        title: 'Battle Log',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFEF4444),
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
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
