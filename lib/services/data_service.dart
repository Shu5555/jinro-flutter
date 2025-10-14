import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/role.dart';

// Utility functions for encryption/decryption
String _simpleEncrypt(String text, {String key = 'jinro2024'}) {
  try {
    final utf8Bytes = utf8.encode(text);
    final keyBytes = utf8.encode(key);
    final encrypted = Uint8List(utf8Bytes.length);
    for (int i = 0; i < utf8Bytes.length; i++) {
      encrypted[i] = utf8Bytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return base64Url.encode(encrypted);
  } catch (e) {
    print('Encryption error: $e');
    // In a real app, you might want to throw a custom exception or return null
    return '';
  }
}

String _simpleDecrypt(String encryptedText, {String key = 'jinro2024'}) {
  try {
    final encrypted = base64Url.decode(encryptedText);
    final keyBytes = utf8.encode(key);
    final decrypted = Uint8List(encrypted.length);
    for (int i = 0; i < encrypted.length; i++) {
      decrypted[i] = encrypted[i] ^ keyBytes[i % keyBytes.length];
    }
    return utf8.decode(decrypted);
  } catch (e) {
    print('Decryption error: $e');
    // In a real app, you might want to throw a custom exception or return null
    return '';
  }
}

class RoleService {
  Future<List<Role>> loadAllRoles() async {
    final List<String> files = [
      'assets/villager-roles.json',
      'assets/murder-roles.json',
      'assets/3rd-roles.json',
    ];
    List<Role> allRoles = [];

    for (String file in files) {
      final String response = await rootBundle.loadString(file);
      final List<dynamic> data = json.decode(response);
      allRoles.addAll(data.map((json) => Role.fromJson(json)).toList());
    }
    return allRoles;
  }
}

class JsonBinService {
  final String? apiKey;
  final String baseUrl = 'https://api.jsonbin.io/v3/b';

  JsonBinService({this.apiKey});

  Future<String> save(String data) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('JSONBin.io APIキーが設定されていません。');
    }
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Master-Key': apiKey!,
        'X-Bin-Private': 'true',
      },
      body: json.encode({'encryptedData': data}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('APIエラー: ${response.statusCode} - ${response.body}');
    }
    final result = json.decode(response.body);
    return result['metadata']['id'];
  }

  Future<String> load(String binId) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('JSONBin.io APIキーが設定されていません。');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/$binId'),
      headers: {'X-Master-Key': apiKey!},
    );

    if (response.statusCode == 404) {
      throw Exception('データが見つかりません。URLの有効期限が切れているか、URLが間違っている可能性があります。');
    }
    if (response.statusCode != 200) {
      throw Exception('APIエラー: ${response.statusCode} - ${response.body}');
    }
    final result = json.decode(response.body);
    if (result['record'] != null && result['record']['encryptedData'] != null) {
      return result['record']['encryptedData'];
    }
    throw Exception('サーバーから取得したデータの形式が正しくありません。');
  }
}

// Helper for encryption/decryption of player assignments
class AssignmentEncryptor {
  static String encryptAssignments(List<Map<String, dynamic>> assignments) {
    final String jsonString = json.encode(assignments);
    return _simpleEncrypt(jsonString);
  }

  static List<Map<String, dynamic>> decryptAssignments(String encryptedData) {
    final String decryptedString = _simpleDecrypt(encryptedData);
    return (json.decode(decryptedString) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
}
