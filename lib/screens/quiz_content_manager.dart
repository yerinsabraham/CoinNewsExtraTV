import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/quiz_models.dart';
import '../services/quiz_data_service.dart';

class QuizContentManager extends StatefulWidget {
  const QuizContentManager({super.key});

  @override
  State<QuizContentManager> createState() => _QuizContentManagerState();
}

class _QuizContentManagerState extends State<QuizContentManager> {
  bool _isGenerating = false;
  String _generationStatus = '';
  int _questionsGenerated = 0;
  final int _questionsToGenerate = 5;
  
  List<Question> _generatedQuestions = [];
  String _selectedCategory = 'blockchain';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quiz Content Manager',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006833), Color(0xFF005029)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        FeatherIcons.zap,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI-Powered Quiz Generation',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato',
                              ),
                            ),
                            Text(
                              'Keep your quiz content fresh with AI-generated questions',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          FeatherIcons.info,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Generate new questions using OpenAI or manage existing content',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content Refresh Options
            _buildSection(
              title: 'Content Refresh Options',
              children: [
                _buildOptionCard(
                  icon: FeatherIcons.zap,
                  title: 'AI-Generated Questions',
                  subtitle: 'Use OpenAI to generate fresh quiz content',
                  color: Colors.purple,
                  onTap: _showAIGenerationDialog,
                ),
                const SizedBox(height: 16),
                _buildOptionCard(
                  icon: FeatherIcons.edit,
                  title: 'Manual Content Update',
                  subtitle: 'Manually add and edit quiz questions',
                  color: Colors.blue,
                  onTap: _showManualUpdateDialog,
                ),
                const SizedBox(height: 16),
                _buildOptionCard(
                  icon: FeatherIcons.database,
                  title: 'Import from Database',
                  subtitle: 'Import questions from external sources',
                  color: Colors.orange,
                  onTap: _showImportDialog,
                ),
                const SizedBox(height: 16),
                _buildOptionCard(
                  icon: FeatherIcons.barChart2,
                  title: 'Content Analytics',
                  subtitle: 'View quiz performance and usage statistics',
                  color: Colors.green,
                  onTap: _showAnalyticsDialog,
                ),
              ],
            ),

            // Current Content Status
            const SizedBox(height: 24),
            _buildSection(
              title: 'Current Content Status',
              children: [
                _buildContentStatusCard(),
              ],
            ),

            // Generated Questions Preview
            if (_generatedQuestions.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSection(
                title: 'Generated Questions Preview',
                children: [
                  _buildGeneratedQuestionsPreview(),
                ],
              ),
            ],

            // Recommendations
            const SizedBox(height: 24),
            _buildSection(
              title: 'Recommendations',
              children: [
                _buildRecommendationCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF006833),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontFamily: 'Lato',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              FeatherIcons.chevronRight,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentStatusCard() {
    final categories = QuizDataService.getCategories();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quiz Categories Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 16),
          ...categories.map((category) {
            final questions = QuizDataService.getQuestionsByCategory(category.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(int.parse(category.colors[0].replaceAll('#', '0xFF'))),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                  Text(
                    '${questions.length} questions',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontFamily: 'Lato',
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGeneratedQuestionsPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FeatherIcons.checkCircle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_generatedQuestions.length} New Questions Generated',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(_generatedQuestions.take(3).map((question) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...question.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isCorrect = index == question.correctIndex;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isCorrect ? Colors.green : Colors.grey[600],
                              shape: BoxShape.circle,
                            ),
                            child: isCorrect
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 10,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 12,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList()),
          if (_generatedQuestions.length > 3) ...[
            const SizedBox(height: 8),
            Text(
              'And ${_generatedQuestions.length - 3} more questions...',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontFamily: 'Lato',
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // In a real app, this would save to database
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Questions would be saved to the database'),
                        backgroundColor: Color(0xFF006833),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006833),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add to Quiz Bank'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _generatedQuestions.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[400],
                  side: BorderSide(color: Colors.grey[600]!),
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF006833).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FeatherIcons.zap, color: const Color(0xFF006833), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Recommended Approach',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendationItem(
            '1. AI-Generated Content',
            'Use OpenAI GPT-4 to generate diverse, high-quality questions automatically. This ensures fresh content and reduces manual work.',
          ),
          _buildRecommendationItem(
            '2. Hybrid Approach',
            'Combine AI generation with manual review and editing to maintain quality while scaling content creation.',
          ),
          _buildRecommendationItem(
            '3. Scheduled Updates',
            'Set up automated content refresh cycles (weekly/monthly) to keep the quiz content engaging and current.',
          ),
          _buildRecommendationItem(
            '4. Analytics-Driven Updates',
            'Monitor question performance and difficulty levels to optimize user engagement and learning outcomes.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF006833).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF006833).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(FeatherIcons.star, color: const Color(0xFF006833), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Best Practice: Start with AI generation and gradually build your custom question bank based on user performance data.',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 12,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF006833),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAIGenerationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'AI Question Generation',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Generate new quiz questions using AI. Select a category and number of questions to create.',
              style: TextStyle(color: Colors.white70, fontFamily: 'Lato'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white, fontFamily: 'Lato'),
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF006833)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: QuizDataService.getCategories().map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateAIQuestions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006833),
            ),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showManualUpdateDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manual question editor would open here'),
        backgroundColor: Color(0xFF006833),
      ),
    );
  }

  void _showImportDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import dialog would open here'),
        backgroundColor: Color(0xFF006833),
      ),
    );
  }

  void _showAnalyticsDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics dashboard would open here'),
        backgroundColor: Color(0xFF006833),
      ),
    );
  }

  Future<void> _generateAIQuestions() async {
    setState(() {
      _isGenerating = true;
      _generationStatus = 'Initializing AI generation...';
      _questionsGenerated = 0;
      _generatedQuestions.clear();
    });

    try {
      // Simulate AI question generation
      for (int i = 0; i < _questionsToGenerate; i++) {
        setState(() {
          _generationStatus = 'Generating question ${i + 1} of $_questionsToGenerate...';
        });
        
        await Future.delayed(const Duration(seconds: 1));
        
        // Generate a sample question (in real implementation, this would call OpenAI API)
        final sampleQuestions = _generateSampleQuestions(_selectedCategory);
        if (i < sampleQuestions.length) {
          _generatedQuestions.add(sampleQuestions[i]);
        }
        
        setState(() {
          _questionsGenerated = i + 1;
        });
      }

      setState(() {
        _generationStatus = 'Generation complete!';
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generated ${_generatedQuestions.length} new questions!'),
          backgroundColor: const Color(0xFF006833),
        ),
      );

    } catch (e) {
      setState(() {
        _generationStatus = 'Generation failed: $e';
        _isGenerating = false;
      });
    }
  }

  List<Question> _generateSampleQuestions(String category) {
    // This is a sample implementation. In a real app, you would call OpenAI API
    final sampleQuestions = {
      'blockchain': [
        Question(
          id: 'ai_gen_001',
          text: 'What is the purpose of a blockchain consensus mechanism?',
          options: [
            'To encrypt data',
            'To validate transactions and maintain network integrity',
            'To store private keys',
            'To create user accounts'
          ],
          correctIndex: 1,
          category: category,
          explanation: 'Consensus mechanisms ensure all nodes agree on the valid state of the blockchain.',
        ),
        Question(
          id: 'ai_gen_002',
          text: 'Which of the following is NOT a characteristic of blockchain?',
          options: [
            'Immutability',
            'Decentralization',
            'Complete anonymity',
            'Transparency'
          ],
          correctIndex: 2,
          category: category,
          explanation: 'Blockchain provides pseudonymity, not complete anonymity.',
        ),
      ],
      'fintech': [
        Question(
          id: 'ai_gen_003',
          text: 'What does PCI DSS compliance ensure in fintech?',
          options: [
            'Data visualization',
            'Payment card data security',
            'User interface design',
            'Marketing effectiveness'
          ],
          correctIndex: 1,
          category: category,
          explanation: 'PCI DSS (Payment Card Industry Data Security Standard) ensures secure handling of card data.',
        ),
      ],
    };

    return sampleQuestions[category] ?? [];
  }
}