import 'package:flutter/material.dart';
import 'package:jinro_flutter/screens/gm_tool_screen.dart';
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
      // initialRoute: '/', // Let Flutter handle the initial route from the URL
      onGenerateRoute: (settings) {
        // Handle initial route with query parameters
        final uri = Uri.parse(settings.name ?? '/');
        final path = uri.path;

        switch (path) {
          case '/player':
            return MaterialPageRoute(
              builder: (context) => const PlayerScreen(),
              settings: settings, // Pass settings to the new route
            );
          case '/random':
            return MaterialPageRoute(builder: (context) => const RandomToolScreen());
          case '/':
          default:
            return MaterialPageRoute(builder: (context) => const GmToolScreen());
        }
      },
    );
  }
}