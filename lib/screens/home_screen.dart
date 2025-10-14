import 'package:flutter/material.dart';
import 'package:jinro_flutter/screens/gm_tool_screen.dart';
import 'package:jinro_flutter/services/room_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _roomCodeController = TextEditingController();
  final _roomService = RoomService();
  bool _isLoading = false;

  Future<void> _joinRoom() async {
    final roomCode = _roomCodeController.text.trim().toUpperCase();
    if (roomCode.isEmpty) {
      _showMessage('部屋番号を入力してください。', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final room = await _roomService.findRoom(roomCode);
      if (room == null) {
        _showMessage('部屋が見つかりません。', isError: true);
      } else if (room['game_state'] != 'LOBBY') {
        _showMessage('この部屋は現在参加受付中です。', isError: true);
      } else {
        // Navigate to Lobby Screen
        if (mounted) {
          Navigator.of(context).pushNamed('/lobby', arguments: roomCode);
        }
      }
    } catch (e) {
      _showMessage('エラーが発生しました: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  controller: _roomCodeController,
                  decoration: const InputDecoration(
                    labelText: '部屋番号',
                    border: OutlineInputBorder(),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, letterSpacing: 4),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _joinRoom,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('参加する'),
                ),
                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 24),
                const Text('ゲームマスターの方', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const GmToolScreen(),
                    ));
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('GMツールを開く'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
