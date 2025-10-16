import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoomRepository {
  final SupabaseClient _supabase;

  RoomRepository(this._supabase);

  String _generateRoomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
  }

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

  Future<Map<String, dynamic>?> findRoom(String roomCode) async {
    final res = await _supabase
        .from('rooms')
        .select()
        .eq('room_code', roomCode)
        .maybeSingle();
    return res;
  }

  Future<void> addPlayerToRoom(String roomCode, String playerId, String playerName) async {
    final room = await findRoom(roomCode);
    if (room == null) {
      throw Exception('Room not found.');
    }

    final players = List<Map<String, dynamic>>.from(room['players'] ?? []);
    
    players.add({
      'id': playerId,
      'name': playerName,
      'is_dead': false,
    });

    await _supabase
        .from('rooms')
        .update({'players': players})
        .eq('room_code', roomCode);
  }

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

  Future<void> updateGameState(String roomCode, String newState) async {
    await _supabase
        .from('rooms')
        .update({'game_state': newState})
        .eq('room_code', roomCode);
  }

  Future<void> startGame(String roomCode, List<Map<String, dynamic>> assignments) async {
    await _supabase
        .from('rooms')
        .update({
          'assignments': assignments,
          'game_state': 'PLAYING',
        })
        .eq('room_code', roomCode);
  }

  Future<void> endGame(String roomCode, String winningFaction, String victoryReason) async {
    await _supabase
        .from('rooms')
        .update({
          'game_state': 'FINISHED',
          'winning_faction': winningFaction,
          'victory_reason': victoryReason,
        })
        .eq('room_code', roomCode);
  }
}
