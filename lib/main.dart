import 'package:flutter/material.dart';
import 'package:jinro_flutter/screens/home_screen.dart';
import 'package:jinro_flutter/screens/lobby_screen.dart';
import 'package:jinro_flutter/screens/gm_tool_screen.dart';
import 'package:jinro_flutter/screens/player_screen.dart';
import 'package:jinro_flutter/screens/role_management_screen.dart';
import 'package:jinro_flutter/screens/random_tool_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
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
          case '/role_management':
            return MaterialPageRoute(builder: (context) => const RoleManagementScreen());
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