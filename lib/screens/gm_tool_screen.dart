import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinro_flutter/providers/gm_tool_screen_controller_provider.dart';
import 'package:flutter/services.dart';

class GmToolScreen extends ConsumerStatefulWidget {
  const GmToolScreen({super.key});

  @override
  ConsumerState<GmToolScreen> createState() => _GmToolScreenState();
}

class _GmToolScreenState extends ConsumerState<GmToolScreen> {
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
    // Load the saved room when the widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gmToolScreenControllerProvider.notifier).loadSavedRoom();
    });
  }

  @override
  void dispose() {
    _roleCountControllers.forEach((_, controller) => controller.dispose());
    _victoryReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(gmToolScreenControllerProvider);
    final notifier = ref.read(gmToolScreenControllerProvider.notifier);

    ref.listen<GmToolScreenState>(gmToolScreenControllerProvider, (previous, next) {
      if (next.eventState is AsyncError) {
        final error = next.eventState as AsyncError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: ${error.error}'), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('GMツール'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.roomCode == null
              ? _buildCreateRoomView(context, notifier)
              : _buildRoomView(context, controller, notifier),
    );
  }

  Widget _buildCreateRoomView(BuildContext context, GmToolScreenController notifier) {
    return Center(
      child: ElevatedButton(
        onPressed: () => notifier.createRoom(),
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
        child: const Text('新しい部屋を作成する', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildRoomView(BuildContext context, GmToolScreenState controller, GmToolScreenController notifier) {
    final roomData = controller.roomData;
    if (roomData == null) return const Center(child: CircularProgressIndicator());
    final gameState = roomData['game_state'];
    switch (gameState) {
      case 'LOBBY': return _buildLobbyView(context, controller, notifier);
      case 'CONFIG': return _buildConfigView(context, controller, notifier);
      case 'PLAYING': return _buildPlayingView(context, controller, notifier);
      case 'FINISHED': return _buildFinishedView(context, controller.roomData!);
      default: return Center(child: Text('不明なゲーム状態です: $gameState'));
    }
  }

  Widget _buildLobbyView(BuildContext context, GmToolScreenState controller, GmToolScreenController notifier) {
    final players = List<Map<String, dynamic>>.from(controller.roomData!['players'] ?? []);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRoomCodeCard(context, controller.roomCode!),
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
            onPressed: () => notifier.changeGameState('CONFIG'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('参加受付を終了して設定に進む', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigView(BuildContext context, GmToolScreenState controller, GmToolScreenController notifier) {
    final players = List<Map<String, dynamic>>.from(controller.roomData!['players'] ?? []);
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
              onPressed: () {
                final counts = _roleCountControllers.map((key, controller) {
                  return MapEntry(key, int.tryParse(controller.text) ?? 0);
                });
                notifier.assignRolesAndStartGame(counts);
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('ゲーム開始', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayingView(BuildContext context, GmToolScreenState controller, GmToolScreenController notifier) {
    final players = List<Map<String, dynamic>>.from(controller.roomData!['players'] ?? []);
    final assignments = List<Map<String, dynamic>>.from(controller.roomData!['assignments'] ?? []);

    if (players.isEmpty) return const Center(child: Text('プレイヤー情報がありません。'));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => notifier.broadcastSurvivorCount(),
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
                      subtitle: Text('役職: ${role['role_name'] ?? '不明'}'),
                      trailing: ElevatedButton(
                        onPressed: () => notifier.setPlayerDeadStatus(player['id'], !isDead),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDead ? Colors.blue : Colors.red,
                        ),
                        child: Text(isDead ? '生存させる' : '死亡させる'),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _showEndGameDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('ゲームを終了する', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCodeCard(BuildContext context, String roomCode) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('部屋番号', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            SelectableText(roomCode, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 4), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy), label: const Text('コピー'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: roomCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('部屋番号をコピーしました！'), backgroundColor: Colors.green),
                );
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

  Future<void> _showAiAdvice() async {
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
      final advice = await ref.read(gmToolScreenControllerProvider.notifier).getAiAdvice();

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AIアドバイスの生成に失敗しました: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  String? _selectedWinningFaction;
  final TextEditingController _victoryReasonController = TextEditingController();

  Widget _buildFinishedView(BuildContext context, Map<String, dynamic> roomData) {
    final winningFaction = roomData['winning_faction'] ?? '不明';
    final victoryReason = roomData['victory_reason'] ?? '理由がありません';
    final assignments = List<Map<String, dynamic>>.from(roomData['assignments'] ?? []);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ゲーム終了', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24.0),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('勝利陣営: $winningFaction', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8.0),
                  Text(victoryReason, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          Text('役職割り当て結果:', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 16.0),
          Expanded(
            child: ListView.builder(
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                final playerName = assignment['name'] ?? '不明';
                final roleName = (assignment['role'] as Map<String, dynamic>)['role_name'] ?? '不明';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text(playerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(roleName),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEndGameDialog() async {
    _selectedWinningFaction = null; // Reset for new dialog
    _victoryReasonController.clear();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('ゲーム終了'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('勝利陣営を選択してください:'),
                  RadioListTile<String>(
                    title: const Text('村人陣営'),
                    value: '村人陣営',
                    groupValue: _selectedWinningFaction,
                    onChanged: (value) => setState(() => _selectedWinningFaction = value),
                  ),
                  RadioListTile<String>(
                    title: const Text('人狼陣営'),
                    value: '人狼陣営',
                    groupValue: _selectedWinningFaction,
                    onChanged: (value) => setState(() => _selectedWinningFaction = value),
                  ),
                  RadioListTile<String>(
                    title: const Text('第三陣営'),
                    value: '第三陣営',
                    groupValue: _selectedWinningFaction,
                    onChanged: (value) => setState(() => _selectedWinningFaction = value),
                  ),
                  const SizedBox(height: 20),
                  const Text('勝因を記入してください:'),
                  TextField(
                    controller: _victoryReasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '例: 人狼が全滅したため',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_selectedWinningFaction == null || _victoryReasonController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('勝利陣営と勝因をすべて入力してください。'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  Navigator.of(context).pop(); // Close dialog
                  await ref.read(gmToolScreenControllerProvider.notifier).endGame(
                        _selectedWinningFaction!,
                        _victoryReasonController.text,
                      );
                },
                child: const Text('ゲームを終了する'),
              ),
            ],
          );
        },
      ),
    );
  }
}