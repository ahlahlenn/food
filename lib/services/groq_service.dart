import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GroqService {
  static const String _apiKeyKey = 'groq_api_key';
  static String _apiKey = '';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyKey) ?? '';
  }

  static void setApiKey(String key) {
    _apiKey = key;
    // Save to SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_apiKeyKey, key);
    });
  }

  static Future<void> clearApiKey() async {
    _apiKey = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyKey);
  }

  static bool get hasApiKey => _apiKey.isNotEmpty;

  static String get apiKey => _apiKey;

  static Future<Map<String, dynamic>> parseFoodEntry(String text) async {
    // First try local estimation (fast, works offline)
    final localResult = _estimateFromLocal(text);
    
    // If no API key, return local estimation
    if (_apiKey.isEmpty) {
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
            if (parsed['calories'] != null) {
              return {
                'calories': (parsed['calories'] ?? 0).round(),
                'protein': (parsed['protein'] ?? 0).round(),
                'carbs': (parsed['carbs'] ?? 0).round(),
                'fat': (parsed['fat'] ?? 0).round(),
              };
            }
          } catch (e) {
            // Fall back to local
          }
        }
      }
    } catch (e) {
      // Fall back to local
    }
    
    return localResult;
  }

  static Map<String, dynamic> _estimateFromLocal(String text) {
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
    } else if (lower.contains('pork') || lower.contains('bacon') || lower.contains('ham')) {
      calories = 200; protein = 20; carbs = 0; fat = 12;
    } else if (lower.contains('duck')) {
      calories = 337; protein = 19; carbs = 0; fat = 28;
    
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
    } else if (lower.contains('fries') || lower.contains('chips')) {
      calories = 312; protein = 3; carbs = 41; fat = 15;
    
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
    } else if (lower.contains('grape') || lower.contains('grapes')) {
      calories = 62; protein = 1; carbs = 16; fat = 0;
    } else if (lower.contains('mango')) {
      calories = 99; protein = 1; carbs = 25; fat = 1;
    } else if (lower.contains('watermelon')) {
      calories = 46; protein = 1; carbs = 12; fat = 0;
    
    // Veggies
    } else if (lower.contains('salad')) {
      calories = 35; protein = 2; carbs = 7; fat = 0;
    } else if (lower.contains('avocado')) {
      calories = 160; protein = 2; carbs = 9; fat = 15;
    } else if (lower.contains('broccoli')) {
      calories = 55; protein = 4; carbs = 11; fat = 1;
    } else if (lower.contains('spinach')) {
      calories = 23; protein = 3; carbs = 4; fat = 0;
    } else if (lower.contains('carrot') || lower.contains('carrots')) {
      calories = 41; protein = 1; carbs = 10; fat = 0;
    } else if (lower.contains('tomato') || lower.contains('tomatoes')) {
      calories = 22; protein = 1; carbs = 5; fat = 0;
    } else if (lower.contains('onion')) {
      calories = 40; protein = 1; carbs = 9; fat = 0;
    } else if (lower.contains('mushroom') || lower.contains('mushrooms')) {
      calories = 22; protein = 3; carbs = 3; fat = 0;
    
    // Dairy
    } else if (lower.contains('milk')) {
      calories = 42; protein = 3; carbs = 5; fat = 1;
    } else if (lower.contains('cheese')) {
      calories = 113; protein = 7; carbs = 0; fat = 9;
    } else if (lower.contains('butter')) {
      calories = 102; protein = 0; carbs = 0; fat = 12;
    } else if (lower.contains('cream')) {
      calories = 340; protein = 2; carbs = 3; fat = 36;
    
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
    } else if (lower.contains('wrap') || lower.contains('burrito')) {
      calories = 280; protein = 12; carbs = 35; fat = 10;
    } else if (lower.contains('bagel')) {
      calories = 245; protein = 10; carbs = 48; fat = 1;
    } else if (lower.contains('muffin')) {
      calories = 377; protein = 6; carbs = 60; fat = 13;
    } else if (lower.contains('cookie') || lower.contains('cookies')) {
      calories = 148; protein = 2; carbs = 20; fat = 7;
    } else if (lower.contains('chocolate')) {
      calories = 546; protein = 5; carbs = 60; fat = 31;
    } else if (lower.contains('ice cream')) {
      calories = 207; protein = 3; carbs = 24; fat = 11;
    } else if (lower.contains('cereal')) {
      calories = 379; protein = 7; carbs = 84; fat = 1;
    } else if (lower.contains('granola')) {
      calories = 471; protein = 10; carbs = 64; fat = 20;
    } else if (lower.contains('pancake') || lower.contains('pancakes') || lower.contains('waffle')) {
      calories = 227; protein = 6; carbs = 28; fat = 10;
    }

    // Portion modifiers
    if (lower.contains('big') || lower.contains('large') || lower.contains('double') || lower.contains('jumbo')) {
      calories = (calories * 1.5).round();
      protein = (protein * 1.3).round();
      carbs = (carbs * 1.3).round();
      fat = (fat * 1.3).round();
    } else if (lower.contains('small') || lower.contains('mini') || lower.contains('half') || lower.contains('kid')) {
      calories = (calories * 0.6).round();
      protein = (protein * 0.6).round();
      carbs = (carbs * 0.6).round();
      fat = (fat * 0.6).round();
    }

    // Cooking methods
    if (lower.contains('fried') || lower.contains('deep fried') || lower.contains('crispy')) {
      fat = (fat * 2).round();
      calories = (calories * 1.3).round();
    } else if (lower.contains('grilled') || lower.contains('baked') || lower.contains('roasted')) {
      calories = (calories * 0.9).round();
    } else if (lower.contains('steamed') || lower.contains('boiled')) {
      calories = (calories * 0.85).round();
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}
