import 'dart:convert';
import 'package:http/http.dart' as http;

class AiAssistantService {
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static Future<String> generateProgressionAdvice(
      List<Map<String, dynamic>> assignments, String apiKey) async {
    if (apiKey.isEmpty) {
      return 'エラー: APIキーが設定されていません.\nアプリの実行時に --dart-define-from-file=config.json を指定しているか確認してください。';
    }

    final url = Uri.parse('$_geminiApiUrl?key=$apiKey');

    final prompt = _buildPrompt(assignments);

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        
        // Defensive checks for nested structure
        if (responseBody['candidates'] != null &&
            responseBody['candidates'].isNotEmpty &&
            responseBody['candidates'][0]['content'] != null &&
            responseBody['candidates'][0]['content']['parts'] != null &&
            responseBody['candidates'][0]['content']['parts'].isNotEmpty &&
            responseBody['candidates'][0]['content']['parts'][0]['text'] != null) {
          return responseBody['candidates'][0]['content']['parts'][0]['text'];
        } else {
          // Check for safety ratings that might filter content
          if (responseBody['promptFeedback'] != null && responseBody['promptFeedback']['safetyRatings'] != null) {
            return 'AIからの応答が安全上の理由でフィルタリングされました。プロンプトの内容を調整してください。\n詳細: ${responseBody['promptFeedback']}';
          }
          return 'AIからの応答が空または予期せぬ形式でした。\nレスポンス: ${utf8.decode(response.bodyBytes)}';
        }
      } else {
        return 'APIエラーが発生しました.\nステータスコード: ${response.statusCode}\nレスポンス: ${utf8.decode(response.bodyBytes)}';
      }
    } catch (e) {
      return 'APIへのリクエスト中にエラーが発生しました: ${e.toString()}';
    }
  }

  static String _buildPrompt(List<Map<String, dynamic>> assignments) {
    final buffer = StringBuffer();
    buffer.writeln('あなたは人狼ゲームの経験豊富なゲームマスター(GM)です。受け取った役職構成を元に、初心者のGMがゲームをスムーズに進行できるよう、具体的なアドバイスを生成してください。');
    buffer.writeln('\n## 現在の役職構成');
    for (var assignment in assignments) {
      final role = Map<String, dynamic>.from(assignment['role']);
      buffer.writeln('- プレイヤー: ${assignment['name']}');
      buffer.writeln('  - 役職: ${role['role_name']}');
      buffer.writeln('  - 陣営: ${role['faction']}');
      buffer.writeln('  - 能力: ${role['ability']}');
      buffer.writeln('  - 勝利条件: ${role['victory_condition']}');
    }

    buffer.writeln('\n## 生成するアドバイスの形式');
    buffer.writeln('以下の3つの項目を、日本語で、マークダウン形式で記述してください。');
    buffer.writeln('1. **役職の能力と注意点**: 各役職の能力を簡潔に紹介し、特にGMが見落としがちな特殊な勝利条件や死亡条件があれば、★マークを付けて注意を促してください。');
    buffer.writeln('2. **夜の能力使用順(推奨)**: 夜のアクションをどの役職から行うべきかの推奨順を提示してください。');
    buffer.writeln('3. **ゲーム進行のモデルプラン**: 上記を踏まえ、具体的なゲーム進行の段取りを番号付きリストで示してください。');

    return buffer.toString();
  }
}