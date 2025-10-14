import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jinro_flutter/services/data_service.dart';
import 'package:jinro_flutter/services/role_assignment_service.dart';

class GmToolScreen extends StatefulWidget {
  const GmToolScreen({super.key});

  @override
  State<GmToolScreen> createState() => _GmToolScreenState();
}

class _GmToolScreenState extends State<GmToolScreen> {
  final TextEditingController _participantsController = TextEditingController();
  final Map<String, TextEditingController> _roleCountControllers = {
    'fortuneTeller': TextEditingController(text: '0'),
    'medium': TextEditingController(text: '0'),
    'knight': TextEditingController(text: '0'),
    'villager': TextEditingController(text: '0'),
    'werewolf': TextEditingController(text: '0'),
    'madman': TextEditingController(text: '0'),
    'thirdParty': TextEditingController(text: '0'),
  };

  late RoleAssignmentService _roleAssignmentService;
  late JsonBinService _jsonBinService;

  List<PlayerAssignment> _playerAssignments = [];
  String? _shareableUrl;

  // TODO: Replace with a secure way to manage API keys (e.g., environment variables)
  final String _jsonBinApiKey = 'YOUR_JSONBIN_API_KEY'; // Placeholder

  @override
  void initState() {
    super.initState();
    _roleAssignmentService = RoleAssignmentService(RoleService());
    _jsonBinService = JsonBinService(apiKey: _jsonBinApiKey);
  }

  @override
  void dispose() {
    _participantsController.dispose();
    _roleCountControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _assignRoles() async {
    final List<String> participants = _participantsController.text
        .split('\n')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    final Map<String, int> counts = {};
    _roleCountControllers.forEach((key, controller) {
      counts[key] = int.tryParse(controller.text) ?? 0;
    });

    final int totalRolesCount = counts.values.fold(0, (sum, count) => sum + count);

    if (participants.isEmpty) {
      _showMessage('参加者を入力してください。', isError: true);
      return;
    }
    if (participants.length != totalRolesCount) {
      _showMessage(
          '参加者数 (${participants.length}) と役職合計 ($totalRolesCount) が一致しません。',
          isError: true);
      return;
    }

    try {
      final List<PlayerAssignment> assignments = await _roleAssignmentService.assignRoles(participants, counts);
      setState(() {
        _playerAssignments = assignments;
        _shareableUrl = null; // Reset URL
      });

      // Generate shareable URL
      final List<Map<String, dynamic>> assignmentsJson = assignments.map((e) => e.toJson()).toList();
      final String encryptedData = AssignmentEncryptor.encryptAssignments(assignmentsJson);

      if (_jsonBinApiKey == 'YOUR_JSONBIN_API_KEY' || _jsonBinApiKey.isEmpty) {
        _showMessage('JSONBin.io APIキーが設定されていないため、URL共有機能は利用できません。', isError: true);
        // Fallback to direct URL encoding if API key is not set
        // This might hit URL length limits for many players
        final String encodedData = Uri.encodeComponent(encryptedData);
        setState(() {
          _shareableUrl = '${Uri.base.origin}/#/player?data=$encodedData';
        });
      } else {
        try {
          final String binId = await _jsonBinService.save(encryptedData);
          setState(() {
            _shareableUrl = '${Uri.base.origin}/#/player?bin=$binId';
          });
          _showMessage('共有URLを生成しました！');
        } catch (e) {
          _showMessage('URLの生成中にエラーが発生しました: ${e.toString()}', isError: true);
          // Fallback to direct URL encoding on JSONBin error
          final String encodedData = Uri.encodeComponent(encryptedData);
          setState(() {
            _shareableUrl = '${Uri.base.origin}/#/player?data=$encodedData';
          });
        }
      }

      _showMessage('役職割り当てが完了しました！');
    } catch (e) {
      _showMessage('役職割り当て中にエラーが発生しました: ${e.toString()}', isError: true);
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
        title: const Text('GMツール'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('参加者名 (1行に1人): '),
            const SizedBox(height: 8.0),
            TextField(
              controller: _participantsController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例: プレイヤーA\nプレイヤーB\nプレイヤーC',
              ),
            ),
            const SizedBox(height: 24.0),
            const Text('役職数設定:'),
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
                onPressed: _assignRoles,
                child: const Text('役職を割り当てる'),
              ),
            ),
            const SizedBox(height: 24.0),
            if (_playerAssignments.isNotEmpty) ...[
              const Text('割り当て結果:'),
              const SizedBox(height: 8.0),
              ..._playerAssignments.map((assignment) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                        '${assignment.name}: ${assignment.role.roleName} (${assignment.password})'),
                  )),
              const SizedBox(height: 16.0),
              if (_shareableUrl != null) ...[
                const Text('共有URL:'),
                const SizedBox(height: 8.0),
                InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: _shareableUrl!));
                    _showMessage('URLをクリップボードにコピーしました！');
                  },
                  child: Text(
                    _shareableUrl!,
                    style: const TextStyle(
                        color: Colors.blue, decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 8.0),
                ElevatedButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _shareableUrl!));
                    _showMessage('URLをクリップボードにコピーしました！');
                  },
                  child: const Text('URLをコピー'),
                ),
              ],
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  final String allPasswords = _playerAssignments
                      .map((a) => '${a.name}: ${a.password}')
                      .join('\n');
                  await Clipboard.setData(ClipboardData(text: allPasswords));
                  _showMessage('全パスワードをクリップボードにコピーしました！');
                },
                child: const Text('全パスワードをコピー'),
              ),
            ]
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
          SizedBox(
            width: 100,
            child: Text(label),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}