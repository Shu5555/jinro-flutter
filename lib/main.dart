import 'package:flutter/material.dart';
import 'package:jinro_flutter/screens/gm_tool_screen.dart';
import 'package:jinro_flutter/screens/player_screen.dart';
import 'package:jinro_flutter/screens/random_tool_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '人狼アプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const GmToolScreen(),
        '/player': (context) => const PlayerScreen(),
        '/random': (context) => const RandomToolScreen(),
      },
    );
  }
}