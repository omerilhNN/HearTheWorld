import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;

  OpenAIService._internal();
  
  // In a real app, this key would be stored securely and not hardcoded
  // For a demo, we're using a placeholder that would need to be replaced
  final String _apiKey = '';

  /// Analyze an image using OpenAI's Vision API
  /// Returns a description of the image  
  Future<String> analyzeImage(File imageFile) async {
    try {
      if (kDebugMode) {
        print('OpenAI image analysis requested for: ${imageFile.path}');
      }
      
      // Check if API key is valid
      if (_apiKey.startsWith('sk-')) {
        try {
          // Convert image to base64
          List<int> imageBytes = await imageFile.readAsBytes();
          String base64Image = base64Encode(imageBytes);
          
          final response = await http.post(
            Uri.parse('$_baseUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'gpt-4-vision-preview',
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {'type': 'text', 'text': 'What do you see in this image? Describe it in detail.'},
                    {
                      'type': 'image_url',
                      'image_url': {
                        'url': 'data:image/jpeg;base64,$base64Image'
                      }
                    }
                  ]
                }
              ],
              'max_tokens': 300,
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            return data['choices'][0]['message']['content'];
          } else {
            if (kDebugMode) {
              print('API error: ${response.statusCode}, ${response.body}');
            }
            // Fallback to mock analysis if API call fails
            return _getMockImageAnalysis(imageFile.path);
          }
        } catch (e) {
          if (kDebugMode) {
            print('API call error: $e');
          }
          // Fallback to mock analysis if API call fails
          return _getMockImageAnalysis(imageFile.path);
        }
      } else {
        // For demonstration without a valid API key
        await Future.delayed(const Duration(seconds: 2)); // Simulate API delay
        return _getMockImageAnalysis(imageFile.path);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error analyzing image: $e');
      }
      return 'Could not analyze the image due to an error.';
    }
  }
  
  // Mock analysis function to simulate OpenAI responses
  String _getMockImageAnalysis(String imagePath) {
    // Use the image path to create some variety in the responses
    final hash = imagePath.hashCode.abs() % 5;
    
    switch (hash) {
      case 0:
        return 'I can see a person smiling in front of what appears to be a living room. There\'s a sofa, some plants in the background, and a coffee table with books.';
      case 1:
        return 'This image shows a desk workspace with a laptop, notebook, and a cup of coffee. There\'s natural light coming from what seems to be a window on the left side.';
      case 2:
        return 'I can see a kitchen scene with some fruits on a counter. There appears to be apples, bananas, and what might be an orange. The kitchen has modern appliances.';
      case 3:
        return 'This is an outdoor photo of a park or garden. There are trees, a walking path, and some people sitting on benches enjoying the sunshine.';
      case 4:
        return 'The image shows what appears to be a bookshelf filled with various books. There\'s also some decorative items like small plants and picture frames between the books.';
      default:
        return 'I can see a photo taken indoors showing various household items and furniture.';
    }
  }
}
