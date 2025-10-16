import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinro_flutter/repositories/room_repository.dart';
import 'package:jinro_flutter/providers/room_repository_provider.dart';

// 状態としてAsyncValueを管理するStateNotifier
class HomeScreenController extends StateNotifier<AsyncValue<void>> {
  HomeScreenController(this._read) : super(const AsyncValue.data(null));

  final Reader _read;

  Future<int?> findOrCreateRoom(String roomId) async {
    state = const AsyncValue.loading();
    try {
      final roomRepository = _read(roomRepositoryProvider);
      final room = await roomRepository.findRoom(roomId);
      final int newRoomId;
      if (room != null) {
        newRoomId = room.id;
      } else {
        final newRoom = await roomRepository.createRoom(roomId);
        newRoomId = newRoom.id;
      }
      state = const AsyncValue.data(null);
      return newRoomId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

// StateNotifierProviderの定義
final homeScreenControllerProvider = StateNotifierProvider<HomeScreenController, AsyncValue<void>>((ref) {
  return HomeScreenController(ref.read);
});