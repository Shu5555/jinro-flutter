import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jinro_flutter/models/player_assignment.dart';
import 'package:jinro_flutter/services/assignment_service.dart';

class RandomToolScreen extends StatefulWidget {
  const RandomToolScreen({super.key});

  @override
  State<RandomToolScreen> createState() => _RandomToolScreenState();
}

class _RandomToolScreenState extends State<RandomToolScreen> {
  final TextEditingController _playerListController = TextEditingController();
  final TextEditingController _numToSelectController = TextEditingController(text: '1');
  final TextEditingController _probabilityInputController = TextEditingController(text: '50');

  String _lotteryResult = '';
  String _coinTossResult = '';
  String _probabilityType = 'percent'; // 'percent' or 'fraction'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlayersFromBin();
    });
  }

  @override
  void dispose() {
    _playerListController.dispose();
    _numToSelectController.dispose();
    _probabilityInputController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayersFromBin() async {
    try {
      final uri = Uri.base;
      final binId = uri.queryParameters['bin'];

      if (binId != null && binId.isNotEmpty) {
        final assignmentService = AssignmentService();
        final assignments = await assignmentService.loadAssignments(binId);

        if (assignments.isNotEmpty) {
          _playerListController.text = assignments.map((a) => a.name).join('\n');
          _showMessage('プレイヤーリストをURLから読み込みました。');
        }
      }
    } catch (e) {
      _showMessage('URLからのプレイヤーリスト読み込み失敗: ${e.toString()}', isError: true);
    }
  }

  void _executeLottery() {
    final List<String> players = _playerListController.text
        .split('\n')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    final int numToSelect = int.tryParse(_numToSelectController.text) ?? 0;

    if (players.isEmpty) {
      _showMessage('プレイヤーを入力してください。', isError: true);
      return;
    }
    if (numToSelect <= 0) {
      _showMessage('選出人数は1以上である必要があります。', isError: true);
      return;
    }
    if (numToSelect > players.length) {
      _showMessage('エラー: 選出人数が対象人数を超えています。', isError: true);
      return;
    }

    players.shuffle(Random());
    final List<String> selected = players.sublist(0, numToSelect);

    setState(() {
      _lotteryResult = selected.join(', ');
    });
  }

  void _executeCoinToss() {
    final String probValue = _probabilityInputController.text;
    double probability = 0.5;

    try {
      if (_probabilityType == 'percent') {
        probability = (double.tryParse(probValue) ?? 50.0) / 100.0;
      } else {
        final parts = probValue.split('/');
        if (parts.length != 2) throw Exception("無効な分数です。");
        final num = double.tryParse(parts[0]);
        final den = double.tryParse(parts[1]);
        if (num == null || den == null || den == 0) throw Exception("無効な分数です。");
        probability = num / den;
      }

      if (probability < 0 || probability > 1) {
        throw Exception("確率は0%～100%の範囲で指定してください。");
      }

      final result = Random().nextDouble() < probability ? '表' : '裏';
      setState(() {
        _coinTossResult = result;
      });
    } catch (e) {
      _showMessage('コイントスエラー: ${e.toString()}', isError: true);
      setState(() {
        _coinTossResult = 'エラー: ${e.toString()}';
      });
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
        title: const Text('ランダムツール'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Player Lottery Section
            const Text('プレイヤー抽選:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16.0),
            const Text('プレイヤー名 (1行に1人): '),
            const SizedBox(height: 8.0),
            TextField(
              controller: _playerListController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例: プレイヤーA\nプレイヤーB',
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: <Widget>[
                const Text('選出人数:'),
                const SizedBox(width: 8.0),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _numToSelectController,
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
                const SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: _executeLottery,
                  child: const Text('抽選実行'),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            if (_lotteryResult.isNotEmpty) ...[
              const Text('抽選結果:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_lotteryResult),
            ],
            const SizedBox(height: 32.0),

            // Coin Toss Section
            const Text('コイントス:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16.0),
            Row(
              children: <Widget>[
                const Text('確率:'),
                const SizedBox(width: 8.0),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _probabilityInputController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                DropdownButton<String>(
                  value: _probabilityType,
                  onChanged: (String? newValue) {
                    setState(() {
                      _probabilityType = newValue!;
                    });
                  },
                  items: const <String>['percent', 'fraction']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value == 'percent' ? '%' : '分数'),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: _executeCoinToss,
                  child: const Text('コイントス実行'),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            if (_coinTossResult.isNotEmpty) ...[
              const Text('コイントス結果:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_coinTossResult, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _coinTossResult == '表' ? Colors.green : Colors.orange)),
            ],
          ],
        ),
      ),
    );
  }
}