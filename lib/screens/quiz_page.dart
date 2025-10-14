import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/quiz_models.dart';
import '../services/quiz_data_service.dart';
import '../services/quiz_progress_service.dart';
import '../services/user_balance_service.dart';
import '../widgets/ads_carousel.dart';
import 'quiz_content_manager.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  QuizSession? currentSession;
  
  bool isInGame = false;
  bool showResult = false;
  
  Timer? questionTimer;
  int timeRemaining = QuizDataService.questionTimeLimit;
  
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;
  
  bool showAnswerFeedback = false;
  bool lastAnswerCorrect = false;
  
  // Category availability tracking
  Map<String, bool> categoryAvailability = {};
  bool loadingAvailability = true;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCategoryAvailability();
  }

  Future<void> _loadCategoryAvailability() async {
    setState(() => loadingAvailability = true);
    
    // Check if user has played any category today
    final hasPlayedToday = await QuizProgressService.hasPlayedToday();
    final playedCategory = await QuizProgressService.getTodayPlayedCategory();
    
    final availability = <String, bool>{};
    for (final category in QuizDataService.categories) {
      // If user hasn't played today, all categories are available
      // If user has played today, all categories are locked
      availability[category.id] = !hasPlayedToday;
    }
    
    if (mounted) {
      setState(() {
        categoryAvailability = availability;
        loadingAvailability = false;
      });
    }
  }
  
  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
  }
  
  @override
  void dispose() {
    questionTimer?.cancel();
    _slideController.dispose();
    _bounceController.dispose();
    super.dispose();
  }
  
  void _startGame(String categoryId) async {
    try {
      // Check if category is available today
      final canPlay = categoryAvailability[categoryId] ?? false;
      if (!canPlay) {
        _showCategoryUnavailableDialog(categoryId);
        return;
      }

      final balanceService = Provider.of<UserBalanceService>(context, listen: false);
      // No entry fee required. Start quiz directly.
      
      final session = QuizDataService.createQuizSession(categoryId);
      
      setState(() {
        currentSession = session;
        isInGame = true;
        showResult = false;
      });
      
      _slideController.forward();
      _startQuestionTimer();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz started — no entry fee required. Earn rewards for correct answers!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog('Failed to start quiz: $e');
    }
  }
  
  void _startQuestionTimer() {
    questionTimer?.cancel();
    timeRemaining = QuizDataService.questionTimeLimit;
    
    questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        timeRemaining--;
      });
      
      if (timeRemaining <= 0) {
        timer.cancel();
        _answerQuestion(-1);
      }
    });
  }
  
  void _answerQuestion(int selectedIndex) {
    questionTimer?.cancel();
    
    if (currentSession == null) return;
    
    final timeSpent = QuizDataService.questionTimeLimit - timeRemaining;
  final question = currentSession!.currentQuestion;
    
    if (question != null) {
  final isCorrect = selectedIndex >= 0 ? question.isCorrect(selectedIndex) : false;
      
      setState(() {
        lastAnswerCorrect = isCorrect;
        showAnswerFeedback = true;
      });
      
      _bounceController.forward().then((_) {
        _bounceController.reset();
      });
      
      // Apply token changes: only reward correct answers (+1), do not deduct on wrong answers
      final wasCorrect = isCorrect;
      if (wasCorrect) {
        currentSession!.currentTokens += 1; // reward
      }

      currentSession!.answerCurrentQuestion(selectedIndex, timeSpent);
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        setState(() {
          showAnswerFeedback = false;
        });
        
        if (currentSession!.isGameOver) {
          _endGame();
        } else {
          _nextQuestion();
        }
      });
    }
  }
  
  void _nextQuestion() {
    _slideController.reset();
    _slideController.forward();
    _startQuestionTimer();
    setState(() {});
  }
  
  Future<void> _endGame() async {
    questionTimer?.cancel();
    
    if (currentSession != null) {
      final balanceService = Provider.of<UserBalanceService>(context, listen: false);
      
  // Since there is no entry fee, net token change equals currentTokens (rewards earned)
  final netTokenChange = currentSession!.currentTokens;
      
      try {
        if (netTokenChange > 0) {
          debugPrint('Quiz completed: Awarding ${netTokenChange} CNE tokens');
          await balanceService.addBalance(netTokenChange.toDouble(), 'Quiz reward');
        } else {
          debugPrint('Quiz completed: No tokens earned');
        }

        // Record that this category was played today
        await QuizProgressService.recordCategoryPlay(
          currentSession!.categoryId,
          currentSession!.generateResult().toJson(),
        );

        // Update availability - once any category is played, all become unavailable
        setState(() {
          for (final category in QuizDataService.categories) {
            categoryAvailability[category.id] = false;
          }
        });
        
        await Future.delayed(const Duration(milliseconds: 300));
        
      } catch (e) {
        debugPrint('Error processing quiz result: $e');
      }
      
      setState(() {
        isInGame = false;
        showResult = true;
      });
    }
  }
  
  void _restartQuiz() {
    setState(() {
      currentSession = null;
      isInGame = false;
      showResult = false;
    });
    _slideController.reset();
  }
  
  void _showInsufficientTokensDialog(double availableBalance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Insufficient CNE Tokens',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: Text(
          'You need ${QuizDataService.defaultEntryFee} CNE to play this quiz.\n\nYour current balance: ${availableBalance.toStringAsFixed(2)} CNE\n\nEarn more tokens by watching videos, daily check-ins, or spin games.',
          style: const TextStyle(color: Colors.white70, fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF006833)),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Colors.white, fontFamily: 'Lato')),
          ],
        ),
      ),
    );
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.red, fontFamily: 'Lato'),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70, fontFamily: 'Lato')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategoryUnavailableDialog(String categoryId) async {
    final nextPlayTime = await QuizProgressService.getNextPlayTime(categoryId);
    final playedCategory = await QuizProgressService.getTodayPlayedCategory();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Already Played Today',
          style: TextStyle(color: Colors.orange, fontFamily: 'Lato'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              playedCategory != null
                  ? 'You have already played "${playedCategory.toUpperCase()}" today.'
                  : 'You have already played a quiz today.',
              style: const TextStyle(color: Colors.white70, fontFamily: 'Lato'),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can only play one category per day. Come back tomorrow to play again!',
              style: TextStyle(color: Colors.white70, fontFamily: 'Lato'),
            ),
            if (nextPlayTime != null) ...[
              const SizedBox(height: 12),
              Text(
                'Next play available: ${_formatNextPlayTime(nextPlayTime)}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatNextPlayTime(DateTime nextTime) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    if (nextTime.isBefore(tomorrow.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    } else {
      return '${nextTime.day}/${nextTime.month}/${nextTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          isInGame ? 'Quiz Game' : 'Choose Category',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (isInGame) {
              _showExitConfirmDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (isInGame) ...[
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${currentSession?.currentTokens ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              if (!isInGame && !showResult) _buildCategorySelection(),
              if (isInGame) _buildGameInterface(),
              if (showResult) _buildResultInterface(),
              
              const SizedBox(height: 16),
              const AdsCarousel(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: !isInGame && !showResult ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QuizContentManager(),
            ),
          );
        },
        backgroundColor: const Color(0xFF006833),
        child: const Icon(Icons.settings, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildCategorySelection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entry fee info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                const Row(
                  children: [
                    Icon(FeatherIcons.helpCircle, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'How It Works',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '• Entry Fee: Free (no tokens required)\n• Only ONE category can be played every 24 hours\n• Questions: ${QuizDataService.questionsPerQuiz} per quiz\n• Time Limit: ${QuizDataService.questionTimeLimit}s per question\n• Correct Answer: +1 CNE\n• Wrong Answer: No penalty\n• Game ends when all questions are answered',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Choose a Category',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Categories grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.15,
            ),
            itemCount: QuizDataService.categories.length,
            itemBuilder: (context, index) {
              final category = QuizDataService.categories[index];
              return _buildCategoryCard(category);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(QuizCategory category) {
    final isAvailable = categoryAvailability[category.id] ?? true;
    final colors = category.colors.map((c) => Color(int.parse('0xFF${c.substring(1)}'))).toList();
    
    return GestureDetector(
      onTap: isAvailable ? () => _startGame(category.id) : () => _showCategoryUnavailableDialog(category.id),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isAvailable 
                ? colors
                : colors.map((c) => c.withOpacity(0.3)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: !isAvailable 
              ? Border.all(color: Colors.grey[600]!, width: 1)
              : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _getCategoryIcon(category.iconName),
                const SizedBox(height: 4),
                Text(
                  category.name,
                  style: TextStyle(
                    color: isAvailable ? Colors.white : Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  category.description,
                  style: TextStyle(
                    color: isAvailable ? Colors.white70 : Colors.white.withOpacity(0.3),
                    fontSize: 9,
                    fontFamily: 'Lato',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAvailable 
                        ? Colors.green.withOpacity(0.8) 
                        : Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'Locked Today',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
              ],
            ),
            if (!isAvailable)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String iconName) {
    IconData iconData;
    switch (iconName) {
      case 'blockchain':
        iconData = Icons.link;
        break;
      case 'fintech':
        iconData = Icons.account_balance;
        break;
      case 'tech':
        iconData = Icons.computer;
        break;
      case 'health':
        iconData = Icons.local_hospital;
        break;
      case 'ai':
        iconData = Icons.smart_toy;
        break;
      case 'security':
        iconData = Icons.security;
        break;
      default:
        iconData = Icons.quiz;
    }
    
    return Icon(iconData, color: Colors.white, size: 22);
  }

  Widget _buildGameInterface() {
    if (currentSession == null) return Container();
    
    final question = currentSession!.currentQuestion;
    if (question == null) return Container();
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Progress and timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${currentSession!.currentQuestionIndex + 1}/${currentSession!.questions.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: timeRemaining <= 5 ? Colors.red : const Color(0xFF006833),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${timeRemaining}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Progress bar
          LinearProgressIndicator(
            value: (currentSession!.currentQuestionIndex + 1) / currentSession!.questions.length,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF006833)),
          ),
          
          const SizedBox(height: 32),
          
          // Question
          SlideTransition(
            position: _slideAnimation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!, width: 1),
              ),
              child: Text(
                question.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lato',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Answer options
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: showAnswerFeedback ? null : () => _answerQuestion(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '${String.fromCharCode(65 + index)}. $option',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            );
          }).toList(),
          
          // Answer feedback
          if (showAnswerFeedback) ...[
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _bounceAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lastAnswerCorrect ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          lastAnswerCorrect ? Icons.check_circle : Icons.cancel,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lastAnswerCorrect ? 'Correct! +1 CNE' : 'Wrong! No penalty',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultInterface() {
    if (currentSession == null) return Container();
    
    final result = currentSession!.generateResult();
    final netChange = result.netTokenChange;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Result header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: netChange > 0 
                  ? [const Color(0xFF006833), const Color(0xFF005029)]
                  : [Colors.red[700]!, Colors.red[900]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  netChange > 0 ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  netChange > 0 ? 'Congratulations!' : 'Better Luck Next Time!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${netChange > 0 ? '+' : ''}${netChange} CNE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[700]!, width: 1),
            ),
            child: Column(
              children: [
                const Text(
                  'Quiz Results',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('Correct', '${result.correctAnswers}', Colors.green),
                    _buildStatItem('Wrong', '${result.wrongAnswers}', Colors.red),
                    _buildStatItem('Accuracy', '${result.accuracy.toStringAsFixed(1)}%', Colors.blue),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _restartQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Lato'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006833),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Lato'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontFamily: 'Lato',
          ),
        ),
      ],
    );
  }

  void _showExitConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Exit Quiz?',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: const Text(
          'Are you sure you want to exit? Your progress will be lost and entry fee will not be refunded.',
          style: TextStyle(color: Colors.white70, fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Quiz'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
