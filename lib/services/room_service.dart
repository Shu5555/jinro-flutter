import 'dart:math';
import 'package:realtime_client/src/types.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoomService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Generate a random alphanumeric code
  String _generateRoomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

  // Create a new room and return the room code
  Future<String> createRoom() async {
    String roomCode;
    bool exists;
    do {
      roomCode = _generateRoomCode(5);
      final res = await _supabase
          .from('rooms')
          .select('room_code')
          .eq('room_code', roomCode)
          .maybeSingle();
      exists = res != null;
    } while (exists);

    await _supabase.from('rooms').insert({
      'room_code': roomCode,
      'game_state': 'LOBBY',
      'players': [],
    });

    return roomCode;
  }

  // Check if a room exists and is in LOBBY state
  Future<Map<String, dynamic>?> findRoom(String roomCode) async {
    final res = await _supabase
        .from('rooms')
        .select()
        .eq('room_code', roomCode)
        .maybeSingle();
    return res;
  }

  // Add a player to a room
  Future<void> addPlayerToRoom(String roomCode, String playerId, String playerName) async {
    // First, fetch the current list of players.
    final room = await findRoom(roomCode);
    if (room == null) {
      throw Exception('Room not found.');
    }

    final players = List<Map<String, dynamic>>.from(room['players'] ?? []);
    
    // Add the new player with their ID and default dead status
    players.add({
      'id': playerId,
      'name': playerName,
      'is_dead': false, // Default to alive
    });

    // Update the room with the new list of players.
    await _supabase
        .from('rooms')
        .update({'players': players})
        .eq('room_code', roomCode);
  }

  // Set the is_dead status for a specific player
  Future<void> setPlayerDeadStatus(String roomCode, String playerId, bool isDead) async {
    final room = await findRoom(roomCode);
    if (room == null) {
      throw Exception('Room not found.');
    }

    final players = List<Map<String, dynamic>>.from(room['players'] ?? []);
    final playerIndex = players.indexWhere((p) => p['id'] == playerId);

    if (playerIndex != -1) {
      players[playerIndex]['is_dead'] = isDead;
      await _supabase
          .from('rooms')
          .update({'players': players})
          .eq('room_code', roomCode);
    }
  }

  // Broadcast a message to all players in a room
  Future<void> broadcastSurvivorCount(String roomCode, int count) async {
    final channel = getRoomChannel(roomCode);
    await channel.send(
      type: RealtimeListenTypes.broadcast,
      event: 'survivor_announcement',
      payload: {'count': count},
    );
  }

  // Get a real-time channel for a specific room
  RealtimeChannel getRoomChannel(String roomCode) {
    return _supabase.channel('public:rooms:room_code=eq.$roomCode');
  }

  // Update the game state of a room
  Future<void> updateGameState(String roomCode, String newState) async {
    await _supabase
        .from('rooms')
        .update({'game_state': newState})
        .eq('room_code', roomCode);
  }

  // Start the game by saving assignments and updating the state
  Future<void> startGame(String roomCode, List<Map<String, dynamic>> assignments) async {
    await _supabase
        .from('rooms')
        .update({
          'assignments': assignments,
          'game_state': 'PLAYING',
        })
        .eq('room_code', roomCode);
  }
}
