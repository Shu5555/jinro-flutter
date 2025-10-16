import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinro_flutter/repositories/room_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository(Supabase.instance.client);
});
