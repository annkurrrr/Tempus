import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for communicating with the Google Gemini API.
class GeminiService {
  static const String _model = 'gemini-2.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  /// Sends a prompt to Gemini and returns the response text.
  /// Throws an [Exception] on failure.
  static Future<String> generateSchedule({
    required String apiKey,
    required String goalText,
    required int daysRemaining,
    required String userContext,
  }) async {
    final systemPrompt = '''
You are a productivity coach inside the "Tempus" app.
The user has set a weekly goal and wants a daily schedule to achieve it.

Rules:
- Be concise and actionable.
- Break the goal into specific daily tasks for each remaining day.
- For each day include: a clear task title, estimated time, and a short tip.
- End with 2-3 motivational insights based on the goal.
- Use plain text formatting. Use bullet points (•) and dashes (–) for lists.
- Do NOT use markdown headers (#), bold (**), or any markdown formatting.
- Keep the entire response under 400 words.
''';

    final userMessage =
        '''
Goal: "$goalText"
Days remaining this week: $daysRemaining
$userContext

Please generate a daily schedule to complete this goal, with time estimates and actionable insights.
''';

    final url = Uri.parse('$_baseUrl?key=$apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': userMessage},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 4096},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>;
        final parts = content['parts'] as List<dynamic>;
        if (parts.isNotEmpty) {
          return parts[0]['text'] as String;
        }
      }
      throw Exception('No response from Gemini.');
    } else {
      // Try to extract a readable error message from the response.
      String errorMsg;
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final error = data['error'] as Map<String, dynamic>?;
        errorMsg =
            error?['message'] as String? ??
            'Unknown error (${response.statusCode})';
      } catch (_) {
        errorMsg = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
      }
      throw Exception(errorMsg);
    }
  }
}
