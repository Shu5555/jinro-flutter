import 'package:flutter/material.dart';
import 'package:jinro_flutter/screens/gm_tool_screen.dart';
import 'package:jinro_flutter/screens/home_screen.dart';
import 'package:jinro_flutter/screens/lobby_screen.dart';
import 'package:jinro_flutter/screens/player_screen.dart';
import 'package:jinro_flutter/screens/random_tool_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://odvtupoyrgtsygscvmnv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9kdnR1cG95cmd0c3lnc2N2bW52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA0MjYwNTMsImV4cCI6MjA3NjAwMjA1M30.mq0_PLP7R_nDQS99nGS2yZIPaBWiEhhl61UytQyN8o8',
  );

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
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        final path = uri.path;

        switch (path) {
          case '/lobby':
            final roomCode = settings.arguments as String?;
            if (roomCode != null) {
              return MaterialPageRoute(
                builder: (context) => LobbyScreen(roomCode: roomCode),
              );
            }
            // Handle error: room code not provided
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('部屋番号が渡されませんでした。')),
              ),
            );
          case '/player':
            return MaterialPageRoute(
              builder: (context) => const PlayerScreen(),
              settings: settings, // Pass settings for backward compatibility
            );
          case '/gmtool':
            return MaterialPageRoute(builder: (context) => const GmToolScreen());
          case '/random':
            return MaterialPageRoute(builder: (context) => const RandomToolScreen());
          case '/':
          default:
            return MaterialPageRoute(builder: (context) => const HomeScreen());
        }
      },
    );
  }
}