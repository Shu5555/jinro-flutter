import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jinro_flutter/services/room_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LobbyScreen extends StatefulWidget {
  final String roomCode;
  const LobbyScreen({super.key, required this.roomCode});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _nameController = TextEditingController();
  final _roomService = RoomService();
  bool _isLoading = false;
  bool _hasJoined = false;
  String _playerName = '';
  String _playerId = ''; // To store the player's own unique ID

  Map<String, dynamic>? _roomData;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _subscribeToRoomChanges(widget.roomCode);
    _loadSavedPlayer();
  }

  Future<void> _loadSavedPlayer() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final savedPlayerId = prefs.getString('player_id_${widget.roomCode}');
    final savedPlayerName = prefs.getString('player_name_${widget.roomCode}');

    if (savedPlayerId != null && savedPlayerName != null) {
      // Check if player still exists in the room (optional, but good for robustness)
      final room = await _roomService.findRoom(widget.roomCode);
      final playersInRoom = List<Map<String, dynamic>>.from(room?['players'] ?? []);
      if (playersInRoom.any((p) => p['id'] == savedPlayerId)) {
        setState(() {
          _hasJoined = true;
          _playerName = savedPlayerName;
          _playerId = savedPlayerId;
        });
        _showMessage('保存されたプレイヤー情報で自動再接続しました。');
      } else {
        // Player not found in room, clear saved data
        prefs.remove('player_id_${widget.roomCode}');
        prefs.remove('player_name_${widget.roomCode}');
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToRoomChanges(String roomCode) {
    _channel = _roomService.getRoomChannel(roomCode);
    _channel!
        .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'rooms',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_code',
              value: roomCode,
            ),
            callback: (payload) {
              if (mounted) {
                setState(() {
                  _roomData = payload.newRecord;
                });
              }
            })
        .onBroadcast(
            event: 'survivor_announcement',
            callback: (payload, [ref]) {
              if (mounted) {
                final count = payload['payload']['count']; // Access nested payload
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('現在の生存者数: $count 人')),
                );
              }
            })
        .subscribe((status, [ref]) async {
      if (status == 'SUBSCRIBED') {
        final initialData = await _roomService.findRoom(roomCode);
        if (mounted) {
          setState(() {
            _roomData = initialData;
          });
        }
      }
    });
  }

  Future<void> _joinLobby() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('ユーザー名を入力してください。', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Generate a unique ID for the player
      final playerId = '${DateTime.now().millisecondsSinceEpoch}-${name}';
      await _roomService.addPlayerToRoom(widget.roomCode, playerId, name);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('player_id_${widget.roomCode}', playerId);
      await prefs.setString('player_name_${widget.roomCode}', name);
      setState(() {
        _hasJoined = true;
        _playerName = name;
        _playerId = playerId;
      });
    } catch (e) {
      _showMessage('部屋への参加に失敗しました: ${e.toString()}', isError: true);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('部屋: ${widget.roomCode}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildContent(),
                ),
              ),
            ),
    );
  }

  Widget _buildContent() {
    if (!_hasJoined) {
      return _buildNameInputView();
    }

    if (_roomData == null) {
      return _buildWaitingView('部屋の情報を取得中...');
    }

    final players = List<Map<String, dynamic>>.from(_roomData!['players'] ?? []);
    final self = players.firstWhere((p) => p['id'] == _playerId, orElse: () => {});
    final bool isDead = self['is_dead'] == true;

    final gameState = _roomData!['game_state'];
    if (gameState == 'LOBBY' || gameState == 'CONFIG') {
      return _buildWaitingView('GMがゲームを開始するのを待っています...');
    }

    if (gameState == 'PLAYING') {
      final assignments = List<Map<String, dynamic>>.from(_roomData!['assignments'] ?? []);
      final myAssignment = assignments.firstWhere((a) => a['name'] == _playerName, orElse: () => {});

      if (myAssignment.isEmpty) {
        return _buildWaitingView('役職情報を取得できませんでした。');
      }
      return _buildRoleView(myAssignment, isDead: isDead);
    }

    if (gameState == 'FINISHED') {
      // Show game end dialog, but still display role view underneath
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !(_isGameEndDialogShowing ?? false)) {
          _showGameEndDialog();
        }
      });
      final assignments = List<Map<String, dynamic>>.from(_roomData!['assignments'] ?? []);
      final myAssignment = assignments.firstWhere((a) => a['name'] == _playerName, orElse: () => {});

      if (myAssignment.isEmpty) {
        return _buildWaitingView('役職情報を取得できませんでした。');
      }
      return _buildRoleView(myAssignment, isDead: isDead);
    }

    return Text('不明なゲーム状態です: $gameState');
  }

  bool? _isGameEndDialogShowing = false;

  Future<void> _showGameEndDialog() async {
    _isGameEndDialogShowing = true;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final winningFaction = _roomData!['winning_faction'] ?? '不明';
        final victoryReason = _roomData!['victory_reason'] ?? 'なし';
        final players = List<Map<String, dynamic>>.from(_roomData!['players'] ?? []);
        final assignments = List<Map<String, dynamic>>.from(_roomData!['assignments'] ?? []);

        return AlertDialog(
          title: const Text('ゲーム終了！'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('勝利陣営: $winningFaction', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text('勝因: $victoryReason', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                const Text('全プレイヤーの最終情報:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...players.map((player) {
                  final assignment = assignments.firstWhere((a) => a['name'] == player['name'], orElse: () => {});
                  final role = Map<String, dynamic>.from(assignment['role'] ?? {});
                  final bool isDead = player['is_dead'] ?? false;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '${player['name']} (${role['role_name'] ?? '不明'}) - ${isDead ? '死亡' : '生存'}',
                      style: TextStyle(color: isDead ? Colors.red : Colors.black),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
    _isGameEndDialogShowing = false;
  }

  Widget _buildNameInputView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('あなたの名前を入力してください', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'ユーザー名',
            border: OutlineInputBorder(),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _joinLobby,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text('待機画面へ'),
        ),
      ],
    );
  }

  Widget _buildWaitingView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildRoleView(Map<String, dynamic> assignment, {required bool isDead}) {
    final role = Map<String, dynamic>.from(assignment['role'] ?? {});
    if (role.isEmpty) return const Text('役職データがありません。');

    return Opacity(
      opacity: isDead ? 0.5 : 1.0,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (isDead)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'あなたは死亡しました',
                    style: TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            Text(
              'プレイヤー名: ${assignment['name']}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16.0),
            _buildRoleDetailRow('役職', role['role_name'] ?? ''),
            _buildRoleDetailRow('陣営', role['faction'] ?? ''),
            _buildRoleDetailRow('勝利条件', role['victory_condition'] ?? '', isMultiline: true),
            _buildRoleDetailRow('能力', role['ability'] ?? '', isMultiline: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDetailRow(String label, String value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4.0),
          Text(value),
        ],
      ),
    );
  }
}
