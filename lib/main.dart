import 'package:flutter/material.dart';
import 'package:pictionnary/ui/screens/drawing_screen.dart';
import 'package:pictionnary/ui/screens/end_game_screen.dart';
import 'package:pictionnary/ui/screens/game_screen.dart';
import 'package:pictionnary/ui/screens/guess_screen.dart';
import 'package:pictionnary/ui/screens/loading_screen.dart';
import 'package:pictionnary/ui/screens/splashscreen.dart';
import 'package:pictionnary/ui/screens/summary_detail_screen.dart';
import 'package:pictionnary/ui/screens/team_composition.dart';
import 'package:pictionnary/ui/screens/team_proposition.dart';
import 'ui/screens/loginscreen.dart';
import 'ui/screens/dashboard.dart';
import 'ui/screens/challenge_input_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Piction.ia.ry',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[300],
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          headlineSmall: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          bodyMedium: TextStyle(
            fontSize: 18.0,
            color: Colors.black,
          ),
          bodySmall: TextStyle(
            fontSize: 16.0,
            color: Colors.black,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 18),
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.red,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/loading_screen': (context) => LoadingScreen(sessionId: ''),
        '/game_screen': (context) => GameScreen(sessionId: '',),
        '/challenge_input_screen': (context) => ChallengeInputScreen(sessionId: ''),
      },
    );
  }
}
