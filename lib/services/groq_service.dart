import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  // TODO: Replace with your Groq API key
  static const String _apiKey = 'YOUR_GROQ_API_KEY';
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<Map<String, dynamic>> parseFoodEntry(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content': '''Extract food, quantity, and estimate calories/macros from the user's meal description. Return JSON ONLY with this exact structure:
{"calories": number, "protein": number (grams), "carbs": number (grams), "fat": number (grams), "food": "main food item"}
Estimate calories based on typical serving sizes.''',
            },
            {
              'role': 'user',
              'content': text,
            }
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Extract JSON from response
        final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(content);
        if (jsonMatch != null) {
          return jsonDecode(jsonMatch.group(0)!);
        }
      }
      
      // Fallback estimation
      return _estimateFallback(text);
    } catch (e) {
      return _estimateFallback(text);
    }
  }

  static Map<String, dynamic> _estimateFallback(String text) {
    // Simple keyword-based fallback estimation
    int calories = 200; // default
    int protein = 10;
    int carbs = 25;
    int fat = 8;

    final lower = text.toLowerCase();
    
    if (lower.contains('oatmeal') || lower.contains('oats')) {
      calories = 150; protein = 5; carbs = 27; fat = 3;
    } else if (lower.contains('egg')) {
      calories = 70; protein = 6; carbs = 0; fat = 5;
    } else if (lower.contains('chicken')) {
      calories = 200; protein = 30; carbs = 0; fat = 5;
    } else if (lower.contains('rice')) {
      calories = 200; protein = 4; carbs = 45; fat = 0;
    } else if (lower.contains('salad')) {
      calories = 100; protein = 2; carbs = 10; fat = 5;
    } else if (lower.contains('pizza')) {
      calories = 300; protein = 12; carbs = 35; fat = 12;
    } else if (lower.contains('burger')) {
      calories = 400; protein = 20; carbs = 30; fat = 20;
    } else if (lower.contains('blueberry') || lower.contains('berries')) {
      calories = 80; protein = 1; carbs = 20; fat = 0;
    } else if (lower.contains('milk') || lower.contains('almond milk')) {
      calories = 30; protein = 1; carbs = 1; fat = 2;
    }

    if (lower.contains('big') || lower.contains('large')) {
      calories = (calories * 1.5).round();
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'food': text.split(' ').take(3).join(' '),
    };
  }
}
