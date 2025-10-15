import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jsonInputController = TextEditingController();

  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _customRoles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCustomRoles();
  }

  @override
  void dispose() {
    _jsonInputController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomRoles() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.from('custom_roles').select().order('created_at', ascending: false);
      setState(() {
        _customRoles = response;
      });
    } catch (e) {
      _showMessage('カスタム役職の取得に失敗しました: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addRole() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final jsonString = _jsonInputController.text;
      final Map<String, dynamic> roleData = json.decode(jsonString);

      // Validate required fields (using the keys from the provided JSON structure)
      final requiredFields = [
        '役職名', '陣営', '分類', '能力', '占い結果', '勝利条件',
      ];
      for (var field in requiredFields) {
        if (!roleData.containsKey(field) || roleData[field].toString().isEmpty) {
          _showMessage('${field}は必須です。', isError: true);
          setState(() => _isLoading = false);
          return;
        }
      }

      await _supabase.from('custom_roles').insert({
        'role_name': roleData['役職名'],
        'faction': roleData['陣営'],
        'ability': roleData['能力'],
        'fortune_telling_result': roleData['占い結果'],
        'related_role': roleData['関連役職'] ?? '',
        'number_of_related_roles': roleData['関連役職人数'] ?? '0',
        'victory_condition': roleData['勝利条件'],
        'creator': roleData['制作者'] ?? '',
        'category': roleData['分類'] ?? 'custom',
      });
      _showMessage('役職を追加しました！');
      _jsonInputController.clear();
      _fetchCustomRoles(); // Refresh list
    } on FormatException catch (e) {
      _showMessage('JSON形式が不正です: ${e.message}', isError: true);
    } catch (e) {
      _showMessage('役職の追加に失敗しました: ${e.toString()}', isError: true);
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
        title: const Text('役職管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAddRoleForm(),
                  const Divider(height: 32),
                  _buildCustomRolesList(),
                ],
              ),
            ),
    );
  }

  Widget _buildAddRoleForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('新しい役職をJSONで追加', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _jsonInputController,
            maxLines: 10,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              labelText: '役職JSON',
              hintText: '例: { "役職名": "村人", "陣営": "村人陣営", ... }',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'JSONを入力してください。';
              }
              try {
                json.decode(value);
              } catch (e) {
                return '不正なJSON形式です。';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: _addRole,
              child: const Text('役職を追加'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRolesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('既存のカスタム役職', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _customRoles.isEmpty
            ? const Text('カスタム役職はまだありません。')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _customRoles.length,
                itemBuilder: (context, index) {
                  final role = _customRoles[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(role['role_name']),
                      subtitle: Text('陣営: ${role['faction']}, 能力: ${role['ability']}'),
                      // TODO: Add edit/delete functionality
                    ),
                  );
                },
              ),
      ],
    );
  }
}
