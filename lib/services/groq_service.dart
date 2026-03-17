import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  // For demo purposes - in production, use secure storage
  static String _apiKey = '';

  static void setApiKey(String key) {
    _apiKey = key;
  }

  static bool get hasApiKey => _apiKey.isNotEmpty;

  static Future<Map<String, dynamic>> parseFoodEntry(String text) async {
    // First try local estimation (fast, works offline)
    final localResult = _estimateFromLocal(text);
    
    // If no API key, return local estimation
    if (_apiKey.isEmpty) {
      print('No API key - using local estimation for: $text');
      return localResult;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a nutrition assistant. Parse this meal and estimate calories and macros.
Respond ONLY with valid JSON like: {"calories": 200, "protein": 10, "carbs": 25, "fat": 8}
Do not include any other text.''',
            },
            {
              'role': 'user',
              'content': text,
            }
          ],
          'temperature': 0.3,
          'max_tokens': 100,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Try to extract JSON
        final jsonMatch = RegExp(r'\{[^{}]+\}').firstMatch(content);
        if (jsonMatch != null) {
          try {
            final parsed = jsonDecode(jsonMatch.group(0)!);
            // Validate it has the required fields
            if (parsed['calories'] != null) {
              return {
                'calories': (parsed['calories'] ?? 0).round(),
                'protein': (parsed['protein'] ?? 0).round(),
                'carbs': (parsed['carbs'] ?? 0).round(),
                'fat': (parsed['fat'] ?? 0).round(),
              };
            }
          } catch (e) {
            print('Failed to parse JSON: $e');
          }
        }
      } else {
        print('Groq API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Groq API exception: $e');
    }
    
    // Fall back to local estimation
    return localResult;
  }

  static Map<String, dynamic> _estimateFromLocal(String text) {
    // Default values
    int calories = 200;
    int protein = 10;
    int carbs = 25;
    int fat = 8;

    final lower = text.toLowerCase();
    
    // Protein-rich
    if (lower.contains('chicken') || lower.contains('breast')) {
      calories = 165; protein = 31; carbs = 0; fat = 4;
    } else if (lower.contains('egg')) {
      calories = 78; protein = 6; carbs = 0; fat = 5;
    } else if (lower.contains('beef') || lower.contains('steak')) {
      calories = 271; protein = 26; carbs = 0; fat = 18;
    } else if (lower.contains('fish') || lower.contains('salmon') || lower.contains('tuna')) {
      calories = 180; protein = 22; carbs = 0; fat = 10;
    } else if (lower.contains('turkey')) {
      calories = 135; protein = 24; carbs = 0; fat = 3;
    } else if (lower.contains('yogurt') || lower.contains('greek')) {
      calories = 100; protein = 17; carbs = 6; fat = 1;
    } else if (lower.contains('tofu')) {
      calories = 94; protein = 10; carbs = 2; fat = 5;
    } else if (lower.contains('shrimp')) {
      calories = 85; protein = 18; carbs = 0; fat = 1;
    
    // Carbs
    } else if (lower.contains('rice')) {
      calories = 206; protein = 4; carbs = 45; fat = 0;
    } else if (lower.contains('pasta')) {
      calories = 220; protein = 8; carbs = 43; fat = 1;
    } else if (lower.contains('bread') || lower.contains('toast')) {
      calories = 79; protein = 3; carbs = 15; fat = 1;
    } else if (lower.contains('oatmeal') || lower.contains('oats') || lower.contains('porridge')) {
      calories = 158; protein = 6; carbs = 27; fat = 3;
    } else if (lower.contains('potato')) {
      calories = 163; protein = 4; carbs = 37; fat = 0;
    } else if (lower.contains('quinoa')) {
      calories = 222; protein = 8; carbs = 39; fat = 4;
    } else if (lower.contains('pizza')) {
      calories = 285; protein = 12; carbs = 36; fat = 10;
    } else if (lower.contains('burger') || lower.contains('hamburger')) {
      calories = 354; protein = 20; carbs = 29; fat = 17;
    
    // Fruits
    } else if (lower.contains('banana')) {
      calories = 105; protein = 1; carbs = 27; fat = 0;
    } else if (lower.contains('apple')) {
      calories = 95; protein = 0; carbs = 25; fat = 0;
    } else if (lower.contains('orange')) {
      calories = 62; protein = 1; carbs = 15; fat = 0;
    } else if (lower.contains('blueberry') || lower.contains('blueberries')) {
      calories = 84; protein = 1; carbs = 21; fat = 0;
    } else if (lower.contains('strawberry') || lower.contains('strawberries')) {
      calories = 32; protein = 1; carbs = 8; fat = 0;
    
    // Veggies
    } else if (lower.contains('salad')) {
      calories = 35; protein = 2; carbs = 7; fat = 0;
    } else if (lower.contains('avocado')) {
      calories = 160; protein = 2; carbs = 9; fat = 15;
    } else if (lower.contains('broccoli')) {
      calories = 55; protein = 4; carbs = 11; fat = 1;
    } else if (lower.contains('spinach')) {
      calories = 23; protein = 3; carbs = 4; fat = 0;
    
    // Dairy
    } else if (lower.contains('milk')) {
      calories = 42; protein = 3; carbs = 5; fat = 1;
    } else if (lower.contains('cheese')) {
      calories = 113; protein = 7; carbs = 0; fat = 9;
    } else if (lower.contains('butter')) {
      calories = 102; protein = 0; carbs = 0; fat = 12;
    
    // Drinks & others
    } else if (lower.contains('coffee')) {
      calories = 2; protein = 0; carbs = 0; fat = 0;
    } else if (lower.contains('juice')) {
      calories = 110; protein = 1; carbs = 26; fat = 0;
    } else if (lower.contains('soda') || lower.contains('coke')) {
      calories = 140; protein = 0; carbs = 39; fat = 0;
    } else if (lower.contains('beer') || lower.contains('wine')) {
      calories = 150; protein = 1; carbs = 13; fat = 0;
    } else if (lower.contains('sandwich')) {
      calories = 350; protein = 18; carbs = 35; fat = 14;
    } else if (lower.contains('soup')) {
      calories = 100; protein = 4; carbs = 15; fat = 3;
    } else if (lower.contains('sushi')) {
      calories = 200; protein = 9; carbs = 38; fat = 1;
    } else if (lower.contains('taco')) {
      calories = 226; protein = 9; carbs = 20; fat = 12;
    } else if (lower.contains('wrap')) {
      calories = 280; protein = 12; carbs = 35; fat = 10;
    }

    // Portion modifiers
    if (lower.contains('big') || lower.contains('large') || lower.contains('double')) {
      calories = (calories * 1.5).round();
      protein = (protein * 1.3).round();
      carbs = (carbs * 1.3).round();
      fat = (fat * 1.3).round();
    } else if (lower.contains('small') || lower.contains('mini') || lower.contains('half')) {
      calories = (calories * 0.6).round();
      protein = (protein * 0.6).round();
      carbs = (carbs * 0.6).round();
      fat = (fat * 0.6).round();
    } else if (lower.contains('single') || lower.contains('one')) {
      // Keep as is
    }

    // Cooking methods
    if (lower.contains('fried') || lower.contains('deep fried')) {
      fat = (fat * 2).round();
      calories = (calories * 1.3).round();
    } else if (lower.contains('grilled') || lower.contains('baked')) {
      calories = (calories * 0.9).round();
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}
