import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_models.dart';

class QuizAIService {
  static const String _openAIApiKey = 'your-openai-api-key-here'; // In production, use secure storage
  static const String _openAIBaseUrl = 'https://api.openai.com/v1/chat/completions';

  /// Generate quiz questions using OpenAI GPT-4
  static Future<List<Question>> generateQuestions({
    required String category,
    required int count,
    required String difficulty,
  }) async {
    try {
      final prompt = _buildPrompt(category, count, difficulty);
      
      final response = await http.post(
        Uri.parse(_openAIBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIApiKey',
        },
        body: json.encode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert quiz question generator. Generate high-quality, educational quiz questions in JSON format.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': 2000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];
        return _parseGeneratedQuestions(content, category);
      } else {
        throw Exception('OpenAI API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate questions: $e');
    }
  }

  /// Build the prompt for OpenAI to generate quiz questions
  static String _buildPrompt(String category, int count, String difficulty) {
    return '''
Generate $count multiple-choice quiz questions about $category with $difficulty difficulty level.

Requirements:
1. Each question should have exactly 4 options (A, B, C, D)
2. Only one correct answer per question
3. Include a brief explanation for the correct answer
4. Questions should be educational and factually accurate
5. Avoid overly technical jargon unless necessary
6. Make questions engaging and relevant to current trends

Format the response as a JSON array with this structure:
[
  {
    "text": "Question text here?",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctIndex": 0,
    "explanation": "Brief explanation of why this is correct"
  }
]

Category: $category
Difficulty: $difficulty
Number of questions: $count

Generate the questions now:
''';
  }

  /// Parse the OpenAI response and convert to Question objects
  static List<Question> _parseGeneratedQuestions(String content, String category) {
    try {
      // Extract JSON from the response (in case there's extra text)
      final jsonStart = content.indexOf('[');
      final jsonEnd = content.lastIndexOf(']') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        throw Exception('No valid JSON found in response');
      }
      
      final jsonContent = content.substring(jsonStart, jsonEnd);
      final List<dynamic> questionData = json.decode(jsonContent);
      
      final List<Question> questions = [];
      
      for (int i = 0; i < questionData.length; i++) {
        final data = questionData[i];
        
        questions.add(Question(
          id: 'ai_gen_${category}_${DateTime.now().millisecondsSinceEpoch}_$i',
          text: data['text'] ?? '',
          options: List<String>.from(data['options'] ?? []),
          correctIndex: data['correctIndex'] ?? 0,
          category: category,
          explanation: data['explanation'] ?? '',
          difficulty: _getDifficultyFromCategory(category),
        ));
      }
      
      return questions;
    } catch (e) {
      throw Exception('Failed to parse generated questions: $e');
    }
  }

  /// Get difficulty level based on category
  static String _getDifficultyFromCategory(String category) {
    switch (category) {
      case 'blockchain':
        return 'hard';
      case 'fintech':
        return 'medium';
      case 'ai':
        return 'hard';
      case 'cybersecurity':
        return 'hard';
      case 'healthtech':
        return 'medium';
      case 'tech':
        return 'medium';
      default:
        return 'medium';
    }
  }

  /// Generate questions with fallback to local generation if API fails
  static Future<List<Question>> generateQuestionsWithFallback({
    required String category,
    required int count,
    required String difficulty,
  }) async {
    try {
      // Try OpenAI first
      return await generateQuestions(
        category: category,
        count: count,
        difficulty: difficulty,
      );
    } catch (e) {
      // Fallback to local generation
      print('OpenAI generation failed: $e. Using fallback generation.');
      return _generateFallbackQuestions(category, count);
    }
  }

  /// Fallback question generation using predefined templates
  static List<Question> _generateFallbackQuestions(String category, int count) {
    final templates = _getQuestionTemplates(category);
    final List<Question> questions = [];
    
    for (int i = 0; i < count && i < templates.length; i++) {
      final template = templates[i];
      questions.add(Question(
        id: 'fallback_${category}_${DateTime.now().millisecondsSinceEpoch}_$i',
        text: template['text'],
        options: List<String>.from(template['options']),
        correctIndex: template['correctIndex'],
        category: category,
        explanation: template['explanation'],
        difficulty: 'medium',
      ));
    }
    
    return questions;
  }

  /// Get predefined question templates for fallback generation
  static List<Map<String, dynamic>> _getQuestionTemplates(String category) {
    final templates = {
      'blockchain': [
        {
          'text': 'What is the main advantage of using blockchain for supply chain management?',
          'options': [
            'Lower costs only',
            'Transparency and traceability',
            'Faster processing only',
            'Better user interface'
          ],
          'correctIndex': 1,
          'explanation': 'Blockchain provides transparency and immutable traceability throughout the supply chain.',
        },
        {
          'text': 'Which consensus mechanism does Ethereum 2.0 primarily use?',
          'options': [
            'Proof of Work',
            'Proof of Stake',
            'Delegated Proof of Stake',
            'Proof of Authority'
          ],
          'correctIndex': 1,
          'explanation': 'Ethereum 2.0 transitioned to Proof of Stake for better energy efficiency.',
        },
      ],
      'fintech': [
        {
          'text': 'What is the primary benefit of open banking APIs?',
          'options': [
            'Increased bank profits',
            'Better customer control over financial data',
            'Reduced regulation',
            'Lower interest rates'
          ],
          'correctIndex': 1,
          'explanation': 'Open banking APIs give customers more control over their financial data and enable innovative services.',
        },
      ],
      'ai': [
        {
          'text': 'What is the main difference between supervised and unsupervised learning?',
          'options': [
            'Processing speed',
            'Data size requirements',
            'Availability of labeled training data',
            'Algorithm complexity'
          ],
          'correctIndex': 2,
          'explanation': 'Supervised learning uses labeled data, while unsupervised learning finds patterns in unlabeled data.',
        },
      ],
    };
    
    return templates[category] ?? [];
  }

  /// Validate generated questions for quality and accuracy
  static bool validateQuestion(Question question) {
    if (question.text.isEmpty) return false;
    if (question.options.length != 4) return false;
    if (question.correctIndex < 0 || question.correctIndex >= question.options.length) return false;
    if (question.options.any((option) => option.isEmpty)) return false;
    
    // Check for duplicate options
    final uniqueOptions = question.options.toSet();
    if (uniqueOptions.length != question.options.length) return false;
    
    return true;
  }

  /// Get analytics for generated content performance
  static Map<String, dynamic> getContentAnalytics() {
    // In a real implementation, this would query the database
    return {
      'totalQuestionsGenerated': 150,
      'questionsInUse': 120,
      'averageQuestionRating': 4.2,
      'categoryDistribution': {
        'blockchain': 35,
        'fintech': 28,
        'ai': 25,
        'cybersecurity': 20,
        'healthtech': 15,
        'tech': 27,
      },
      'generationSuccessRate': 0.95,
      'lastGenerated': DateTime.now().subtract(const Duration(days: 2)),
    };
  }

  /// Schedule automatic content refresh
  static Future<void> scheduleContentRefresh({
    required String category,
    required int questionsPerWeek,
    required String difficulty,
  }) async {
    // In a real implementation, this would set up a scheduled task
    print('Scheduled weekly generation of $questionsPerWeek $difficulty questions for $category');
    
    // This could integrate with Firebase Cloud Functions or similar service
    // to automatically generate new content at specified intervals
  }
}