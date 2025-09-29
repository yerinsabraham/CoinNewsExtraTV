import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/quiz_models.dart';
import '../services/quiz_data_service.dart';
import '../provider/admin_provider.dart';
import '../widgets/chat_ad_carousel.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  // User wallet balance (mock - would come from actual wallet service)
  int userTokenBalance = 50;
  
  // Quiz session management
  QuizSession? currentSession;
  
  // Game state
  bool isInGame = false;
  bool showResult = false;
  
  // Question timer
  Timer? questionTimer;
  int timeRemaining = QuizDataService.questionTimeLimit;
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;
  
  // Answer feedback
  bool showAnswerFeedback = false;
  bool lastAnswerCorrect = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
  
  void _startGame(String categoryId) {
    try {
      if (userTokenBalance < QuizDataService.defaultEntryFee) {
        _showInsufficientTokensDialog();
        return;
      }
      
      final session = QuizDataService.createQuizSession(categoryId);
      
      setState(() {
        currentSession = session;
        isInGame = true;
        showResult = false;
        userTokenBalance -= QuizDataService.defaultEntryFee;
      });
      
      _slideController.forward();
      _startQuestionTimer();
      
    } catch (e) {
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
        _answerQuestion(-1); // Time's up - no answer selected
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
      
      // Show feedback animation
      _bounceController.forward().then((_) {
        _bounceController.reset();
      });
      
      // Answer the question in the session
      currentSession!.answerCurrentQuestion(selectedIndex, timeSpent);
      
      // Wait for feedback, then continue
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
  
  void _endGame() {
    questionTimer?.cancel();
    
    if (currentSession != null) {
      final result = currentSession!.generateResult();
      userTokenBalance += currentSession!.currentTokens;
      
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
  
  void _showInsufficientTokensDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Insufficient Tokens',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: Text(
          'You need ${QuizDataService.defaultEntryFee} CNE tokens to play. Your balance: $userTokenBalance CNE',
          style: TextStyle(color: Colors.grey[300], fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF006833), fontFamily: 'Lato'),
            ),
          ),
        ],
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
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.grey[300], fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF006833), fontFamily: 'Lato'),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Quiz Challenge',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (isInGame) {
              _showExitGameDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF006833).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF006833),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  FeatherIcons.award,
                  color: Color(0xFF006833),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$userTokenBalance CNE',
                  style: const TextStyle(
                    color: Color(0xFF006833),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _buildCurrentScreen(),
      floatingActionButton: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (!adminProvider.isAdmin || adminProvider.isLoading || isInGame) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton(
            onPressed: () => _showAdminMenu(context),
            backgroundColor: const Color(0xFF006833),
            foregroundColor: Colors.white,
            child: const Icon(FeatherIcons.plus),
          );
        },
      ),
    );
  }
  
  Widget _buildCurrentScreen() {
    if (showResult) {
      return _buildResultScreen();
    } else if (isInGame) {
      return _buildQuestionScreen();
    } else {
      return _buildCategoryScreen();
    }
  }
  
  Widget _buildCategoryScreen() {
    final categories = QuizDataService.getCategories();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ad Banner Carousel
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: ChatAdCarousel(),
          ),
          
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF006833).withOpacity(0.1),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF006833).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tech & Blockchain Trivia',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Test your knowledge and earn CNE tokens!',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Entry fee info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        FeatherIcons.info,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Entry Fee: 5 CNE tokens',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato',
                              ),
                            ),
                            Text(
                              'Correct answer: +1 CNE • Wrong answer: -1 CNE',
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
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Choose Your Category',
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
              childAspectRatio: 1.0,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(category);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryCard(QuizCategory category) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(int.parse(category.colors[0].replaceFirst('#', '0xFF'))),
            Color(int.parse(category.colors[1].replaceFirst('#', '0xFF'))),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _startGame(category.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getCategoryIcon(category.iconName),
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${category.totalQuestions} questions',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'blockchain':
        return FeatherIcons.link;
      case 'fintech':
        return FeatherIcons.dollarSign;
      case 'tech':
        return FeatherIcons.cpu;
      case 'health':
        return FeatherIcons.heart;
      case 'ai':
        return FeatherIcons.zap;
      case 'security':
        return FeatherIcons.shield;
      default:
        return FeatherIcons.helpCircle;
    }
  }
  
  Widget _buildQuestionScreen() {
    if (currentSession == null || currentSession!.currentQuestion == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final question = currentSession!.currentQuestion!;
    final progress = (currentSession!.currentQuestionIndex + 1) / currentSession!.questions.length;
    
    return Stack(
      children: [
        SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress and stats
                _buildQuestionHeader(progress),
                
                const SizedBox(height: 24),
                
                // Timer
                _buildTimer(),
                
                const SizedBox(height: 24),
                
                // Question
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF006833).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    question.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      fontFamily: 'Lato',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Answer options
                ...List.generate(question.options.length, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: _buildAnswerOption(
                      question.options[index],
                      index,
                      String.fromCharCode(65 + index), // A, B, C, D
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        
        // Answer feedback overlay
        if (showAnswerFeedback)
          _buildAnswerFeedback(),
      ],
    );
  }
  
  Widget _buildQuestionHeader(double progress) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question ${currentSession!.currentQuestionIndex + 1} of ${currentSession!.questions.length}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontFamily: 'Lato',
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF006833)),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF006833).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF006833),
              width: 1,
            ),
          ),
          child: Text(
            '${currentSession!.currentTokens} CNE',
            style: const TextStyle(
              color: Color(0xFF006833),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimer() {
    final progress = timeRemaining / QuizDataService.questionTimeLimit;
    final isLowTime = timeRemaining <= 5;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLowTime ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLowTime ? Colors.red.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            FeatherIcons.clock,
            color: isLowTime ? Colors.red : Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time Remaining: ${timeRemaining}s',
                  style: TextStyle(
                    color: isLowTime ? Colors.red : Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isLowTime ? Colors.red : Colors.blue,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnswerOption(String text, int index, String letter) {
    return Container(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: showAnswerFeedback ? null : () => _answerQuestion(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.grey[700]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF006833),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Lato',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnswerFeedback() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: ScaleTransition(
          scale: _bounceAnimation,
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: lastAnswerCorrect ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  lastAnswerCorrect ? FeatherIcons.check : FeatherIcons.x,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  lastAnswerCorrect ? 'Correct!' : 'Wrong!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lastAnswerCorrect ? '+1 CNE Token' : '-1 CNE Token',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildResultScreen() {
    if (currentSession == null) return const SizedBox();
    
    final result = currentSession!.generateResult();
    final isSuccess = result.completed;
    final netChange = result.netTokenChange;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Result icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: isSuccess ? Colors.green : Colors.red,
                width: 3,
              ),
            ),
            child: Icon(
              isSuccess ? FeatherIcons.award : FeatherIcons.alertCircle,
              color: isSuccess ? Colors.green : Colors.red,
              size: 60,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            isSuccess ? 'Quiz Complete!' : 'Game Over!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            result.categoryName,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontFamily: 'Lato',
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Correct',
                  '${result.correctAnswers}',
                  Colors.green,
                  FeatherIcons.check,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Wrong',
                  '${result.wrongAnswers}',
                  Colors.red,
                  FeatherIcons.x,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Accuracy',
                  '${result.accuracy.toStringAsFixed(1)}%',
                  Colors.blue,
                  FeatherIcons.target,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Net Change',
                  '${netChange >= 0 ? '+' : ''}$netChange CNE',
                  netChange >= 0 ? Colors.green : Colors.red,
                  FeatherIcons.trendingUp,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Final tokens
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF006833).withOpacity(0.2),
                  const Color(0xFF006833).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF006833).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Tokens Earned',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${result.finalTokens} CNE',
                  style: const TextStyle(
                    color: Color(0xFF006833),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _restartQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Choose Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _startGame(currentSession!.categoryId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006833),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
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
      ),
    );
  }
  
  void _showExitGameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Exit Quiz?',
          style: TextStyle(color: Colors.white, fontFamily: 'Lato'),
        ),
        content: const Text(
          'Are you sure you want to exit? You will lose your progress and staked tokens.',
          style: TextStyle(color: Colors.grey, fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Continue',
              style: TextStyle(color: Color(0xFF006833), fontFamily: 'Lato'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.red, fontFamily: 'Lato'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdminMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quiz Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildAdminMenuItem(
              icon: FeatherIcons.plus,
              title: 'Add Questions',
              subtitle: 'Create new quiz questions',
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Add Questions');
              },
            ),
            _buildAdminMenuItem(
              icon: FeatherIcons.edit,
              title: 'Edit Categories',
              subtitle: 'Modify quiz categories',
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Edit Categories');
              },
            ),
            _buildAdminMenuItem(
              icon: FeatherIcons.settings,
              title: 'Quiz Settings',
              subtitle: 'Configure rewards and difficulty',
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Quiz Settings');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF006833),
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: const Color(0xFF006833).withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: const Color(0xFF006833),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
