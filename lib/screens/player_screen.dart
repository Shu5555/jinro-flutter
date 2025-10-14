import 'package:flutter/material.dart';
import 'package:jinro_flutter/models/player_assignment.dart';
import 'package:jinro_flutter/services/assignment_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final TextEditingController _passwordController = TextEditingController();
  List<PlayerAssignment>? _allAssignments;
  PlayerAssignment? _currentPlayerAssignment;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlayerData();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayerData() async {
    try {
      final uri = Uri.base;

      // For Flutter web with hash routing, the path is in the fragment.
      if (!uri.hasFragment) {
        setState(() {
          _isLoading = false;
          _errorMessage = '無効な共有URLです。URLに#が含まれていません。';
        });
        return;
      }

      // Parse the fragment which contains the route path and query params.
      final fragmentUri = Uri.parse(uri.fragment);

      if (fragmentUri.path != '/player') {
        setState(() {
          _isLoading = false;
          _errorMessage = 'この画面は共有URLから直接開く必要があります。';
        });
        return;
      }

      final binId = fragmentUri.queryParameters['bin'];

      if (binId == null || binId.isEmpty) {
        throw Exception('URLに共有ID(bin)が含まれていません。');
      }

      final assignmentService = AssignmentService();
      final assignments = await assignmentService.loadAssignments(binId);

      setState(() {
        _allAssignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'データ読み込みエラー: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _revealRole() {
    if (_allAssignments == null) return;
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      _showMessage('合言葉を入力してください。', isError: true);
      return;
    }

    try {
      final assignment = _allAssignments!.firstWhere(
        (a) => a.password == password,
        orElse: () => throw Exception('合言葉が間違っています。'),
      );

      setState(() {
        _currentPlayerAssignment = assignment;
      });
      _showMessage('${assignment.name}さんの役職を表示しました');
    } catch (e) {
      _showMessage(e.toString(), isError: true);
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
        title: const Text('役職確認'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
                ))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: _currentPlayerAssignment == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text('合言葉を入力してください:'),
                            const SizedBox(height: 8.0),
                            TextField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: '合言葉',
                              ),
                              onSubmitted: (_) => _revealRole(),
                            ),
                            const SizedBox(height: 16.0),
                            Center(
                              child: ElevatedButton(
                                onPressed: _revealRole,
                                child: const Text('役職を表示'),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'プレイヤー名: ${_currentPlayerAssignment!.name}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16.0),
                            _buildRoleDetailRow('役職', _currentPlayerAssignment!.role.roleName),
                            _buildRoleDetailRow('陣営', _currentPlayerAssignment!.role.faction),
                            _buildRoleDetailRow('占い結果', _currentPlayerAssignment!.role.fortuneTellingResult.isEmpty ? (_currentPlayerAssignment!.role.faction == '人狼陣営' && _currentPlayerAssignment!.role.category == '人狼' ? '人狼' : '人狼ではない') : _currentPlayerAssignment!.role.fortuneTellingResult),
                            _buildRoleDetailRow('能力', _currentPlayerAssignment!.role.ability, isMultiline: true),
                            _buildRoleDetailRow('勝利条件', _currentPlayerAssignment!.role.victoryCondition, isMultiline: true),
                            _buildRoleDetailRow('制作者', _currentPlayerAssignment!.role.creator),
                            if (_currentPlayerAssignment!.role.relatedRole.isNotEmpty) ...[
                              _buildRoleDetailRow('関連役職', _currentPlayerAssignment!.role.relatedRole),
                              _buildRoleDetailRow('関連役職人数', _currentPlayerAssignment!.role.numberOfRelatedRoles),
                            ],
                            const SizedBox(height: 24.0),
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _currentPlayerAssignment = null;
                                    _passwordController.clear();
                                  });
                                },
                                child: const Text('別の役職を確認'),
                              ),
                            ),
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
          isMultiline
              ? Text(value) // Removed replaceAll, assuming text is clean
              : Text(value),
        ],
      ),
    );
  }
}
