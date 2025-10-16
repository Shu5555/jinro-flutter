import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jinro_flutter/screens/home_screen.dart';
import 'package:jinro_flutter/screens/lobby_screen.dart';
import 'package:jinro_flutter/screens/gm_tool_screen.dart';
import 'package:jinro_flutter/screens/player_screen.dart';
import 'package:jinro_flutter/screens/role_management_screen.dart';
import 'package:jinro_flutter/screens/random_tool_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/lobby/:roomCode',
        name: 'lobby',
        builder: (context, state) {
          final roomCode = state.pathParameters['roomCode']!;
          return LobbyScreen(roomCode: roomCode);
        },
      ),
      GoRoute(
        path: '/player',
        name: 'player',
        builder: (context, state) => const PlayerScreen(),
      ),
      GoRoute(
        path: '/gmtool',
        name: 'gmtool',
        builder: (context, state) => const GmToolScreen(),
      ),
      GoRoute(
        path: '/role_management',
        name: 'role_management',
        builder: (context, state) => const RoleManagementScreen(),
      ),
      GoRoute(
        path: '/random',
        name: 'random',
        builder: (context, state) => const RandomToolScreen(),
      ),
    ],
  );
});
