import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GroqService {
  static const String _apiKeyKey = 'groq_api_key';
  
  static Future<String> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey) ?? '';
  }

  static Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, key);
  }

  static Future<Map<String, dynamic>> parseFoodEntry(String text) async {
    final apiKey = await _getApiKey();
    
    if (apiKey.isEmpty) {
      return _estimateFallback(text);
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a nutrition assistant. Parse the user's meal description and estimate nutritional values.
Return JSON ONLY with this exact structure:
{"calories": number, "protein": number (grams), "carbs": number (grams), "fat": number (grams)}
Estimate based on typical serving sizes. If unsure, make reasonable estimates.''',
            },
            {
              'role': 'user',
              'content': text,
            }
          ],
          'temperature': 0.3,
          'max_tokens': 200,
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
      
      return _estimateFallback(text);
    } catch (e) {
      return _estimateFallback(text);
    }
  }

  static Map<String, dynamic> _estimateFallback(String text) {
    // Keyword-based estimation
    int calories = 200;
    int protein = 10;
    int carbs = 25;
    int fat = 8;

    final lower = text.toLowerCase();
    
    // Common foods
    if (lower.contains('oatmeal') || lower.contains('oats')) {
      calories = 150; protein = 5; carbs = 27; fat = 3;
    } else if (lower.contains('egg')) {
      calories = 70; protein = 6; carbs = 0; fat = 5;
    } else if (lower.contains('chicken') || lower.contains('breast')) {
      calories = 165; protein = 31; carbs = 0; fat = 4;
    } else if (lower.contains('rice')) {
      calories = 200; protein = 4; carbs = 45; fat = 0;
    } else if (lower.contains('salad')) {
      calories = 100; protein = 2; carbs = 10; fat = 5;
    } else if (lower.contains('pizza')) {
      calories = 285; protein = 12; carbs = 36; fat = 10;
    } else if (lower.contains('burger') || lower.contains('hamburger')) {
      calories = 354; protein = 20; carbs = 29; fat = 17;
    } else if (lower.contains('blueberry') || lower.contains('blueberries')) {
      calories = 84; protein = 1; carbs = 21; fat = 1;
    } else if (lower.contains('milk')) {
      calories = 30; protein = 1; carbs = 1; fat = 2;
    } else if (lower.contains('banana')) {
      calories = 105; protein = 1; carbs = 27; fat = 0;
    } else if (lower.contains('apple')) {
      calories = 95; protein = 1; carbs = 25; fat = 0;
    } else if (lower.contains('bread') || lower.contains('toast')) {
      calories = 80; protein = 3; carbs = 15; fat = 1;
    } else if (lower.contains('pasta')) {
      calories = 220; protein = 8; carbs = 43; fat = 1;
    } else if (lower.contains('soup')) {
      calories = 100; protein = 4; carbs = 15; fat = 3;
    } else if (lower.contains('sandwich')) {
      calories = 350; protein = 18; carbs = 35; fat = 14;
    } else if (lower.contains('coffee') || lower.contains('espresso')) {
      calories = 5; protein = 0; carbs = 0; fat = 0;
    } else if (lower.contains('juice')) {
      calories = 110; protein = 1; carbs = 26; fat = 0;
    } else if (lower.contains('yogurt')) {
      calories = 100; protein = 17; carbs = 6; fat = 1;
    } else if (lower.contains('fish') || lower.contains('salmon')) {
      calories = 208; protein = 20; carbs = 0; fat = 13;
    } else if (lower.contains('steak') || lower.contains('beef')) {
      calories = 271; protein = 26; carbs = 0; fat = 18;
    } else if (lower.contains('avocado')) {
      calories = 160; protein = 2; carbs = 9; fat = 15;
    }

    // Portion modifiers
    if (lower.contains('big') || lower.contains('large') || lower.contains('large')) {
      calories = (calories * 1.5).round();
      protein = (protein * 1.3).round();
      carbs = (carbs * 1.3).round();
      fat = (fat * 1.3).round();
    } else if (lower.contains('small') || lower.contains('little')) {
      calories = (calories * 0.7).round();
      protein = (protein * 0.7).round();
      carbs = (carbs * 0.7).round();
      fat = (fat * 0.7).round();
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}
