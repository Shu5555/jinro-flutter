import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jinro_flutter/models/player_assignment.dart';
import 'package:jinro_flutter/services/ai_assistant_service.dart';
import 'package:jinro_flutter/services/data_service.dart';
import 'package:jinro_flutter/services/role_assignment_service.dart';
import 'package:jinro_flutter/services/room_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GmToolScreen extends StatefulWidget {
  const GmToolScreen({super.key});

  @override
  State<GmToolScreen> createState() => _GmToolScreenState();
}

class _GmToolScreenState extends State<GmToolScreen> {
  // Services
  final _roomService = RoomService();
  late RoleAssignmentService _roleAssignmentService;

  // State
  String? _roomCode;
  Map<String, dynamic>? _roomData;
  RealtimeChannel? _channel;
  bool _isLoading = false;

  // Role Count Controllers
  final Map<String, TextEditingController> _roleCountControllers = {
    'fortuneTeller': TextEditingController(text: '0'),
    'medium': TextEditingController(text: '0'),
    'knight': TextEditingController(text: '0'),
    'villager': TextEditingController(text: '0'),
    'werewolf': TextEditingController(text: '0'),
    'madman': TextEditingController(text: '0'),
    'thirdParty': TextEditingController(text: '0'),
  };

  @override
  void initState() {
    super.initState();
    _roleAssignmentService = RoleAssignmentService(RoleService());
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _roleCountControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // Room & Game State Management
  Future<void> _createRoom() async {
    setState(() => _isLoading = true);
    try {
      final roomCode = await _roomService.createRoom();
      final initialData = await _roomService.findRoom(roomCode);
      setState(() {
        _roomCode = roomCode;
        _roomData = initialData;
      });
      _subscribeToRoomChanges(roomCode);
    } catch (e) {
      _showMessage('部屋の作成に失敗しました: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
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
              if (mounted) setState(() => _roomData = payload.newRecord);
            })
        .subscribe((status, [ref]) async {
      if (status == 'SUBSCRIBED') {
        final initialData = await _roomService.findRoom(roomCode);
        if (mounted) setState(() => _roomData = initialData);
      }
    });
  }

  Future<void> _changeGameState(String newState) async {
    if (_roomCode == null) return;
    setState(() => _isLoading = true);
    try {
      await _roomService.updateGameState(_roomCode!, newState);
    } catch (e) {
      _showMessage('ゲーム状態の更新に失敗しました: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _assignRolesAndStartGame() async {
    final players = List<Map<String, dynamic>>.from(_roomData!['players'] ?? []);
    final participants = players.map((p) => p['name'] as String).toList();

    final Map<String, int> counts = {};
    _roleCountControllers.forEach((key, controller) {
      counts[key] = int.tryParse(controller.text) ?? 0;
    });

    final int totalRolesCount = counts.values.fold(0, (sum, count) => sum + count);

    if (participants.isEmpty || participants.length != totalRolesCount) {
      _showMessage('参加者数 (${participants.length}) と役職合計 ($totalRolesCount) が一致しません。', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final List<PlayerAssignment> assignments = await _roleAssignmentService.assignRoles(participants, counts);
      final assignmentsJson = assignments.map((a) => a.toJson()).toList();
      await _roomService.startGame(_roomCode!, assignmentsJson);
    } catch (e) {
      _showMessage('ゲーム開始に失敗: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAiAdvice() async {
    final assignments = List<Map<String, dynamic>>.from(_roomData!['assignments'] ?? []);
    if (assignments.isEmpty) {
      _showMessage('役職割り当て情報がなく、アドバイスを生成できません。', isError: true);
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('AIがアドバイスを生成中...'),
        content: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      const apiKey = String.fromEnvironment('GEMINI_API_KEY');
      final advice = await AiAssistantService.generateProgressionAdvice(assignments, apiKey);

      // Pop loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show result dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI進行アシスタント'),
          content: SingleChildScrollView(child: Text(advice)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Pop loading dialog on error
      if (mounted) Navigator.of(context).pop();
      _showMessage('AIアドバイスの生成に失敗しました: ${e.toString()}', isError: true);
    }
  }

  // UI Build Methods
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GMツール'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _roomCode == null
              ? _buildCreateRoomView()
              : _buildRoomView(),
    );
  }

  Widget _buildCreateRoomView() {
    return Center(
      child: ElevatedButton(
        onPressed: _createRoom,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
        child: const Text('新しい部屋を作成する', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildRoomView() {
    if (_roomData == null) return const Center(child: CircularProgressIndicator());
    final gameState = _roomData!['game_state'];
    switch (gameState) {
      case 'LOBBY': return _buildLobbyView();
      case 'CONFIG': return _buildConfigView();
      case 'PLAYING': return _buildPlayingView();
      default: return Center(child: Text('不明なゲーム状態です: $gameState'));
    }
  }

  Widget _buildLobbyView() {
    final players = List<Map<String, dynamic>>.from(_roomData!['players'] ?? []);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRoomCodeCard(),
          const SizedBox(height: 24),
          Text('参加者 (${players.length}人)', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: players.isEmpty
                ? const Center(child: Text('まだ参加者はいません。'))
                : ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) => Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text((index + 1).toString())),
                        title: Text(players[index]['name'], style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _changeGameState('CONFIG'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('参加受付を終了して設定に進む', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigView() {
    final players = List<Map<String, dynamic>>.from(_roomData!['players'] ?? []);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('参加者 (${players.length}人)', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...players.map((p) => Text('- ${p['name']}', style: const TextStyle(fontSize: 16))),
          const SizedBox(height: 24.0),
          const Text('役職数設定:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          _buildRoleCountInput('占い師', _roleCountControllers['fortuneTeller']!),
          _buildRoleCountInput('霊媒師', _roleCountControllers['medium']!),
          _buildRoleCountInput('騎士', _roleCountControllers['knight']!),
          _buildRoleCountInput('村人', _roleCountControllers['villager']!),
          _buildRoleCountInput('人狼', _roleCountControllers['werewolf']!),
          _buildRoleCountInput('狂人', _roleCountControllers['madman']!),
          _buildRoleCountInput('第三陣営', _roleCountControllers['thirdParty']!),
          const SizedBox(height: 24.0),
          Center(
            child: ElevatedButton(
              onPressed: _assignRolesAndStartGame,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('ゲーム開始', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayingView() {
    final players = List<Map<String, dynamic>>.from(_roomData!['players'] ?? []);
    final assignments = List<Map<String, dynamic>>.from(_roomData!['assignments'] ?? []);

    if (players.isEmpty) return const Center(child: Text('プレイヤー情報がありません。'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final survivorCount = players.where((p) => p['is_dead'] != true).length;
                    _roomService.broadcastSurvivorCount(_roomCode!, survivorCount);
                    _showMessage('生存者数 ($survivorCount 人) を全員に告知しました。');
                  },
                  icon: const Icon(Icons.campaign),
                  label: const Text('生存者数を告知'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAiAdvice,
                  icon: const Icon(Icons.support_agent),
                  label: const Text('AIに進行を相談'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final assignment = assignments.firstWhere((a) => a['name'] == player['name'], orElse: () => {});
              final role = Map<String, dynamic>.from(assignment['role'] ?? {});
              final bool isDead = player['is_dead'] ?? false;
      
              return Opacity(
                opacity: isDead ? 0.5 : 1.0,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: CircleAvatar(child: Text((index + 1).toString())),
                      title: Text(player['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('役職: ${role['role_name'] ?? '不明'}', style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 2),
                            Text('陣営: ${role['faction'] ?? '不明'}', style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 2),
                            Text('能力: ${role['ability'] ?? 'なし'}', style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          _roomService.setPlayerDeadStatus(_roomCode!, player['id'], !isDead);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDead ? Colors.blue : Colors.red,
                        ),
                        child: Text(isDead ? '生存させる' : '死亡させる'),
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper Widgets & Methods
  Widget _buildRoomCodeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('部屋番号', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            SelectableText(_roomCode!, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 4), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy), label: const Text('コピー'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _roomCode!));
                _showMessage('部屋番号をコピーしました！');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCountInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: <Widget>[
          SizedBox(width: 100, child: Text(label)),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }
}