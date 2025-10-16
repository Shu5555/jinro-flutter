import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jinro_flutter/providers/room_repository_provider.dart';

final _isLoadingProvider = StateProvider<bool>((ref) => false);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomCodeController = TextEditingController();
    final isLoading = ref.watch(_isLoadingProvider);

    void showMessage(String message, {bool isError = false}) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }

    Future<void> joinRoom() async {
      final roomCode = roomCodeController.text.trim().toUpperCase();
      if (roomCode.isEmpty) {
        showMessage('部屋番号を入力してください。', isError: true);
        return;
      }

      ref.read(_isLoadingProvider.notifier).state = true;
      try {
        final roomRepository = ref.read(roomRepositoryProvider);
        final room = await roomRepository.findRoom(roomCode);

        if (room == null) {
          showMessage('部屋が見つかりません。', isError: true);
        } else if (room['game_state'] != 'LOBBY') {
          showMessage('この部屋は現在参加受付中です。', isError: true);
        } else {
          if (context.mounted) {
            context.push('/lobby/$roomCode');
          }
        }
      } catch (e) {
        showMessage('エラーが発生しました: ${e.toString()}', isError: true);
      } finally {
        ref.read(_isLoadingProvider.notifier).state = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('人狼ゲームへようこそ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text('部屋番号で参加', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                const SizedBox(height: 16),
                TextField(
                  controller: roomCodeController,
                  decoration: const InputDecoration(
                    labelText: '部屋番号',
                    border: OutlineInputBorder(),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, letterSpacing: 4),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : joinRoom,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: isLoading ? const CircularProgressIndicator() : const Text('参加する'),
                ),
                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 24),
                const Text('ゲームマスターの方', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.push('/gmtool'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('GMツールを開く'),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => context.push('/role_management'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('役職管理'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


