
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinro_flutter/providers/room_repository_provider.dart';
import 'package:jinro_flutter/providers/room_service_provider.dart';
import 'package:jinro_flutter/providers/role_assignment_service_provider.dart';
import 'package:jinro_flutter/services/ai_assistant_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This will hold the state of the GM Tool Screen
class GmToolScreenState {
  final bool isLoading;
  final String? roomCode;
  final Map<String, dynamic>? roomData;
  final AsyncValue<void> eventState;

  GmToolScreenState({
    this.isLoading = false,
    this.roomCode,
    this.roomData,
    this.eventState = const AsyncValue.data(null),
  });

  GmToolScreenState copyWith({
    bool? isLoading,
    String? roomCode,
    Map<String, dynamic>? roomData,
    AsyncValue<void>? eventState,
  }) {
    return GmToolScreenState(
      isLoading: isLoading ?? this.isLoading,
      roomCode: roomCode ?? this.roomCode,
      roomData: roomData ?? this.roomData,
      eventState: eventState ?? this.eventState,
    );
  }
}

class GmToolScreenController extends StateNotifier<GmToolScreenState> {
  GmToolScreenController(this._read) : super(GmToolScreenState()) {
    // Cancel the subscription when the controller is disposed
    ref.onDispose(() {
      _channel?.unsubscribe();
    });
  }

  final Reader _read;
  RealtimeChannel? _channel;

  void _subscribeToRoomChanges(String roomCode) {
    _channel?.unsubscribe(); // Unsubscribe from any previous channel
    final roomService = _read(roomServiceProvider);
    _channel = roomService.getRoomChannel(roomCode);
    _channel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'rooms',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room_code',
          value: roomCode,
        ),
        callback: (payload) {
          if (payload.newRecord != null) {
            state = state.copyWith(roomData: payload.newRecord);
          }
        })
    .subscribe();
  }

  Future<void> createRoom() async {
    state = state.copyWith(isLoading: true, eventState: const AsyncValue.loading());
    try {
      // We use the repository to create the room now
      final roomRepository = _read(roomRepositoryProvider);
      final roomCode = await roomRepository.createRoom();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gm_room_code', roomCode);

      // Fetch initial data
      final initialData = await roomRepository.findRoom(roomCode);

      state = state.copyWith(
        isLoading: false,
        roomCode: roomCode,
        roomData: initialData,
        eventState: const AsyncValue.data(null),
      );
      _subscribeToRoomChanges(roomCode);
      
      // It's better to handle subscription in the UI or a dedicated service
      // For now, we focus on state management

    } catch (e, st) {
      state = state.copyWith(isLoading: false, eventState: AsyncValue.error(e, st));
    }
  }

  Future<void> loadSavedRoom() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final savedRoomCode = prefs.getString('gm_room_code');
    if (savedRoomCode != null && savedRoomCode.isNotEmpty) {
      final roomRepository = _read(roomRepositoryProvider);
      final room = await roomRepository.findRoom(savedRoomCode);
      if (room != null && room['game_state'] != 'FINISHED') {
        state = state.copyWith(
          isLoading: false,
          roomCode: savedRoomCode,
          roomData: room,
        );
        _subscribeToRoomChanges(savedRoomCode);
      } else {
        await prefs.remove('gm_room_code');
        state = state.copyWith(isLoading: false);
      }
    } else {
    }
  }

  Future<void> changeGameState(String newState) async {
    if (state.roomCode == null) return;
    state = state.copyWith(eventState: const AsyncValue.loading());
    try {
      final roomRepository = _read(roomRepositoryProvider);
      await roomRepository.updateGameState(state.roomCode!, newState);
      // The UI will update automatically via the real-time subscription
      state = state.copyWith(eventState: const AsyncValue.data(null));
    } catch (e, st) {
      state = state.copyWith(eventState: AsyncValue.error(e, st));
    }
  }

  Future<void> assignRolesAndStartGame(Map<String, int> counts) async {
    if (state.roomCode == null || state.roomData == null) return;

    final players = List<Map<String, dynamic>>.from(state.roomData!['players'] ?? []);
    final participants = players.map((p) => p['name'] as String).toList();
    final int totalRolesCount = counts.values.fold(0, (sum, count) => sum + count);

    if (participants.isEmpty || participants.length != totalRolesCount) {
      state = state.copyWith(eventState: AsyncValue.error('参加者数 (${participants.length}) と役職合計 ($totalRolesCount) が一致しません。', StackTrace.current));
      return;
    }

    state = state.copyWith(eventState: const AsyncValue.loading());
    try {
      final roleAssignmentService = _read(roleAssignmentServiceProvider);
      final assignments = await roleAssignmentService.assignRoles(participants, counts);
      final assignmentsJson = assignments.map((a) => a.toJson()).toList();

      final roomRepository = _read(roomRepositoryProvider);
      await roomRepository.startGame(state.roomCode!, assignmentsJson);

      state = state.copyWith(eventState: const AsyncValue.data(null));
    } catch (e, st) {
      state = state.copyWith(eventState: AsyncValue.error(e, st));
    }
  }

  Future<void> setPlayerDeadStatus(String playerId, bool isDead) async {
    if (state.roomCode == null) return;
    state = state.copyWith(eventState: const AsyncValue.loading());
    try {
      final roomRepository = _read(roomRepositoryProvider);
      await roomRepository.setPlayerDeadStatus(state.roomCode!, playerId, isDead);
      state = state.copyWith(eventState: const AsyncValue.data(null));
    } catch (e, st) {
      state = state.copyWith(eventState: AsyncValue.error(e, st));
    }
  }

  Future<void> broadcastSurvivorCount() async {
    if (state.roomCode == null || state.roomData == null) return;
    final players = List<Map<String, dynamic>>.from(state.roomData!['players'] ?? []);
    final survivorCount = players.where((p) => p['is_dead'] != true).length;

    state = state.copyWith(eventState: const AsyncValue.loading());
    try {
      final roomService = _read(roomServiceProvider);
      await roomService.broadcastSurvivorCount(state.roomCode!, survivorCount);
      state = state.copyWith(eventState: const AsyncValue.data(null));
    } catch (e, st) {
      state = state.copyWith(eventState: AsyncValue.error(e, st));
    }
  }

  Future<String> getAiAdvice() async {
    if (state.roomData == null) {
      throw Exception('役職割り当て情報がなく、アドバイスを生成できません。');
    }
    final assignments = List<Map<String, dynamic>>.from(state.roomData!['assignments'] ?? []);
    if (assignments.isEmpty) {
      throw Exception('役職割り当て情報がなく、アドバイスを生成できません。');
    }

    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    return await AiAssistantService.generateProgressionAdvice(assignments, apiKey);
  }

  Future<void> endGame(String winningFaction, String victoryReason) async {
    if (state.roomCode == null) return;
    state = state.copyWith(eventState: const AsyncValue.loading());
    try {
      final roomRepository = _read(roomRepositoryProvider);
      await roomRepository.endGame(state.roomCode!, winningFaction, victoryReason);
      state = state.copyWith(eventState: const AsyncValue.data(null));
    } catch (e, st) {
      state = state.copyWith(eventState: AsyncValue.error(e, st));
    }
  }
}

final gmToolScreenControllerProvider = StateNotifierProvider<GmToolScreenController, GmToolScreenState>((ref) {
  return GmToolScreenController(ref.read);
});
