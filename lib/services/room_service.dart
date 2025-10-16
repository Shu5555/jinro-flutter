import 'package:realtime_client/src/types.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoomService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
}

