import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:calotrack/services/local_ml_service.dart';
import '../data/ml_food_database.dart';

class ImageAnalysisService {
  static final LocalMLService _localML = LocalMLService();

  static const List<String> _visionModels = [
    'openai/gpt-4o-mini',
    'google/gemini-1.5-flash',
    'anthropic/claude-3-haiku',
    'meta-llama/llama-3.2-90b-vision-instruct',
    'qwen/qwen-2-vl-72b-instruct',
    'google/gemini-1.5-pro',
    'openai/gpt-4o',
  ];

  static Future<Map<String, String>> analyzeFood(Uint8List bytes, {String healthCondition = 'none'}) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_openrouter_api_key_here') {
      if (kDebugMode) {
        print('OpenRouter API Key is missing.');
      }
      return _getFallbackData('Missing API Key');
    }

    try {
      // 1. **HYBRID ML LAYER: PRIMARY** 
      // Try to identify locally first (no internet required)
      await _localML.initialize();
      final localResults = await _localML.analyzeImageLocal(bytes);
      
      // If the local model found something, use the top result!
      if (localResults.isNotEmpty) {
        if (kDebugMode) {
          print('Successfully analyzed food using LOCAL DETECTION MODEL');
        }
        // Return the first (highest confidence) detection
        final topResult = localResults.first;
        return {
          'name': topResult['name'].toString(),
          'calories': topResult['calories'].toString(),
          'carbs': topResult['carbs'].toString(),
          'protein': topResult['protein'].toString(),
          'fat': topResult['fat'].toString(),
          'isGoodForCondition': 'true',
          'healthAlert': topResult['healthAlert'].toString(),
        };
      }

      // 2. **FALLBACK LAYER: SECONDARY**
      // Local model failed or lacked confidence. Falling back to OpenRouter.
      final base64Image = base64Encode(bytes);

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'HTTP-Referer': 'http://localhost', // Required by OpenRouter
        'X-Title': 'CaloTrack' // Optional but good for OpenRouter
      };

      for (int i = 0; i < _visionModels.length; i++) {
        final model = _visionModels[i];
        if (kDebugMode) {
          print('Trying model ($i/7): $model');
        }

        try {
          final body = jsonEncode({
            "model": model,
            "messages": [
              {
                "role": "user",
                "content": [
                  {
                    "type": "text",
                    "text": "Analyze this image. If the image does NOT contain food (e.g., it is a person's face, a room, or scenery), reply ONLY with: {\"name\": \"Not Food\", \"calories\": \"0\", \"carbs\": \"0\", \"protein\": \"0\", \"fat\": \"0\", \"isGoodForCondition\": false, \"healthAlert\": \"Please upload a clear image of food.\"}. \n\nIf it IS food: You are a nutrition expert. The user has $healthCondition. Provide a valid JSON with: 'name', 'calories', 'carbs', 'protein', 'fat', 'isGoodForCondition' (bool), and 'healthAlert'. For 'healthAlert', be specific about $healthCondition (e.g., if sugar is high, warn about high carbs; if pressure is high, warn about salt). No other text."
                  },
                  {
                    "type": "image_url",
                    "image_url": {
                      "url": "data:image/jpeg;base64,$base64Image"
                    }
                  }
                ]
              }
            ]
          });

          final response = await http.post(
            Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
            headers: headers,
            body: body,
          );

          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            final String content = responseData['choices'][0]['message']['content'];
            
            String cleanedContent = content.trim();
            if (cleanedContent.startsWith('```json')) {
              cleanedContent = cleanedContent.substring(7);
            } else if (cleanedContent.startsWith('```')) {
              cleanedContent = cleanedContent.substring(3);
            }
            if (cleanedContent.endsWith('```')) {
              cleanedContent = cleanedContent.substring(0, cleanedContent.length - 3);
            }
            cleanedContent = cleanedContent.trim();
            
            final Map<String, dynamic> jsonResult = jsonDecode(cleanedContent);

            if (kDebugMode) {
              print('Successfully analyzed food using $model');
            }

            return {
              'name': jsonResult['name']?.toString() ?? 'Unknown Food',
              'calories': jsonResult['calories']?.toString() ?? '0',
              'carbs': jsonResult['carbs']?.toString() ?? '0',
              'protein': jsonResult['protein']?.toString() ?? '0',
              'fat': jsonResult['fat']?.toString() ?? '0',
              'isGoodForCondition': jsonResult['isGoodForCondition']?.toString() ?? 'true',
              'healthAlert': jsonResult['healthAlert']?.toString() ?? '',
            };
          } else {
            if (kDebugMode) {
              print('Model $model failed with status: ${response.statusCode} - ${response.body}');
            }
            // If it's the last model or a hard error like unauthorized, we might break, 
            // but we'll let it naturally continue to the next model for rate limits (429) or busy (502).
          }
        } catch (e) {
          if (kDebugMode) {
            print('Exception with model $model: $e');
          }
        }
      }
      
      // If loop finishes, all 7 models failed
      if (kDebugMode) {
        print('All 7 fallback models are busy or failed.');
      }
      return _getFallbackData('All Models Busy');
    } catch (e) {
      if (kDebugMode) {
        print('Exception in analyzeFood: $e');
      }
      return _getFallbackData('Error Occurred');
    }
  }

  static Map<String, String> _getFallbackData(String name) {
    return {
      'name': name,
      'calories': '0',
      'carbs': '0',
      'protein': '0',
      'fat': '0',
      'isGoodForCondition': 'true',
      'healthAlert': '',
    };
  }

  static Future<Map<String, String>> analyzeFoodText(String foodName, {String healthCondition = 'none'}) async {
    // 1. FIRST check the local dataset (MLFoodDatabase)
    final localMatch = MLFoodDatabase.getDetails(foodName);
    if (localMatch != null) {
      if (kDebugMode) {
        print('Found text correction in Local Dataset!');
      }
      return {
        'name': foodName,
        'calories': localMatch['calories']?.toString() ?? '0',
        'carbs': localMatch['carbs']?.toString() ?? '0',
        'protein': localMatch['protein']?.toString() ?? '0',
        'fat': localMatch['fat']?.toString() ?? '0',
        'isGoodForCondition': 'true',
        'healthAlert': '',
      };
    }

    // 2. If not found locally, fallback to OpenRouter API
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_openrouter_api_key_here') {
      if (kDebugMode) {
        print('OpenRouter API Key is missing.');
      }
      return _getFallbackData(foodName);
    }

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'HTTP-Referer': 'http://localhost',
        'X-Title': 'CaloTrack'
      };

      for (int i = 0; i < _visionModels.length; i++) {
        final model = _visionModels[i];
        if (kDebugMode) {
          print('Trying text analysis model ($i/7): $model');
        }

        try {
          final body = jsonEncode({
            "model": model,
            "messages": [
              {
                "role": "user",
                "content": "You are a nutrition expert. The user is asking about the food: '$foodName'. The user has $healthCondition. Provide a valid JSON with: 'name' (use the name '$foodName'), 'calories', 'carbs', 'protein', 'fat', 'isGoodForCondition' (bool), and 'healthAlert'. For 'healthAlert', be specific about $healthCondition. No other text."
              }
            ]
          });

          final response = await http.post(
            Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
            headers: headers,
            body: body,
          );

          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            final String content = responseData['choices'][0]['message']['content'];
            
            String cleanedContent = content.trim();
            if (cleanedContent.startsWith('```json')) {
              cleanedContent = cleanedContent.substring(7);
            } else if (cleanedContent.startsWith('```')) {
              cleanedContent = cleanedContent.substring(3);
            }
            if (cleanedContent.endsWith('```')) {
              cleanedContent = cleanedContent.substring(0, cleanedContent.length - 3);
            }
            cleanedContent = cleanedContent.trim();
            
            final Map<String, dynamic> jsonResult = jsonDecode(cleanedContent);

            if (kDebugMode) {
              print('Successfully analyzed text food using $model');
            }

            return {
              'name': jsonResult['name']?.toString() ?? foodName,
              'calories': jsonResult['calories']?.toString() ?? '0',
              'carbs': jsonResult['carbs']?.toString() ?? '0',
              'protein': jsonResult['protein']?.toString() ?? '0',
              'fat': jsonResult['fat']?.toString() ?? '0',
              'isGoodForCondition': jsonResult['isGoodForCondition']?.toString() ?? 'true',
              'healthAlert': jsonResult['healthAlert']?.toString() ?? '',
            };
          }
        } catch (e) {
          if (kDebugMode) {
            print('Exception with text model $model: $e');
          }
        }
      }
      return _getFallbackData(foodName);
    } catch (e) {
      if (kDebugMode) {
        print('Exception in analyzeFoodText: $e');
      }
      return _getFallbackData(foodName);
    }
  }

  static void dispose() {
    // No manual disposal required for API Service
  }
}
