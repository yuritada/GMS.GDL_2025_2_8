// lib/services/ai_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

class AiService {
  // ★★★ 必ずあなたのURLに書き換えてください ★★★
  final String _evaluateUrl = 'https://us-central1-no2-g8.cloudfunctions.net/evaluate_idea';
  final String _generateUrl = 'https://us-central1-no2-g8.cloudfunctions.net/generate_idea';

  // ネタを評価するAPIを呼び出す
  Future<Map<String, dynamic>> evaluateIdea(String memoContent) async {
    try {
      final response = await http.post(
        Uri.parse(_evaluateUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'data': {'memo': memoContent}
        }),
      );
      if (response.statusCode == 200) {
        // UTF-8でデコードしてからJSONを解析
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody);
      } else {
        throw Exception('評価APIの呼び出しに失敗しました。 Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('評価APIのエラー: $e');
      rethrow;
    }
  }

  // 新しいネタを生成するAPIを呼び出す
  Future<Map<String, dynamic>> generateIdea(List<String> referenceMemos) async {
    try {
      final response = await http.post(
        Uri.parse(_generateUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'data': {'memos': referenceMemos}
        }),
      );

      if (response.statusCode == 200) {
        // UTF-8でデコードしてからJSONを解析
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody);
      } else {
        throw Exception('生成APIの呼び出しに失敗しました。 Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('生成APIのエラー: $e');
      rethrow;
    }
  }
}
