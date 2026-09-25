import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String baseUrl =
      'http://10.0.2.2:5000'; // Standard Android emulator localhost fallback
  static const String localFallbackUrl = 'http://127.0.0.1:5000';

  Future<Map<String, dynamic>> sendChatMessage({
    required String prompt,
    Map<String, dynamic>? context,
    List<Map<String, String>>? history,
    String? customBaseUrl,
  }) async {
    final targetUrl = customBaseUrl ?? localFallbackUrl;
    final Uri url = Uri.parse('$targetUrl/api/chat');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'prompt': prompt,
              'context': context,
              'history': history ?? [],
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reply': data['reply'] ?? 'No response received.',
        };
      } else {
        return {
          'success': false,
          'reply': 'Server error (${response.statusCode}): ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'reply':
            'Could not connect to Gemini backend server. Ensure backend is running. Error: $e',
      };
    }
  }

  Future<List<Map<String, dynamic>>> fetchAvailableModels({
    String? customBaseUrl,
  }) async {
    final targetUrl = customBaseUrl ?? localFallbackUrl;
    final Uri url = Uri.parse('$targetUrl/api/models');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List models = data['models'] ?? [];
        return models.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    // Fallback default list
    return [
      {
        'model_id': 'rice_pests',
        'name': 'Rice Pest Classifier',
        'category': 'pests',
        'crop_type': 'rice',
      },
      {
        'model_id': 'plant_diseases_38',
        'name': 'Plant Diseases (38 Conditions)',
        'category': 'diseases',
        'crop_type': 'multi_crop',
      },
      {
        'model_id': 'ip102_pests_102',
        'name': 'IP102 Agricultural Pests (102 Species)',
        'category': 'pests',
        'crop_type': 'general_crops',
      },
    ];
  }
}
