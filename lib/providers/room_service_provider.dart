import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinro_flutter/services/room_service.dart';

final roomServiceProvider = Provider<RoomService>((ref) {
  return RoomService();
});
