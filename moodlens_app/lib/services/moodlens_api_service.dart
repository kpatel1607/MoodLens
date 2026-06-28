import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/moodlens_result.dart';

class MoodLensApiService {
static const String baseUrl =
    "https://kpatel1607-moodlens-api.hf.space";

  Future<MoodLensResult> analyzeSequence(String text) async {
    final cleanedText = text.trim();

    if (cleanedText.isEmpty) {
      throw Exception('Please enter some text first.');
    }

    final uri = Uri.parse('$baseUrl/analyze/sequence/compact');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': cleanedText,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Server error: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    return MoodLensResult.fromJson(decoded);
  }
}