class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String category;
  final String difficulty;
  final String explanation;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.category,
    this.difficulty = 'medium',
    this.explanation = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'options': options,
      'correctIndex': correctIndex,
      'category': category,
      'difficulty': difficulty,
      'explanation': explanation,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correctIndex'] ?? 0,
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
      explanation: json['explanation'] ?? '',
    );
  }

  bool isCorrect(int selectedIndex) {
    return selectedIndex == correctIndex;
  }

  String get correctAnswer {
    if (correctIndex >= 0 && correctIndex < options.length) {
      return options[correctIndex];
    }
    return '';
  }
}

class QuizCategory {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final int totalQuestions;
  final List<String> colors; // Gradient colors

  QuizCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.totalQuestions,
    required this.colors,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'totalQuestions': totalQuestions,
      'colors': colors,
    };
  }

  factory QuizCategory.fromJson(Map<String, dynamic> json) {
    return QuizCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconName: json['iconName'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      colors: List<String>.from(json['colors'] ?? []),
    );
  }
}

class QuizResult {
  final String categoryId;
  final String categoryName;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int tokensStaked;
  final int tokensWon;
  final int tokensLost;
  final int finalTokens;
  final DateTime completedAt;
  final bool completed;
  final List<QuestionResult> questionResults;

  QuizResult({
    required this.categoryId,
    required this.categoryName,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.tokensStaked,
    required this.tokensWon,
    required this.tokensLost,
    required this.finalTokens,
    required this.completedAt,
    required this.completed,
    required this.questionResults,
  });

  double get accuracy {
    if (totalQuestions == 0) return 0.0;
    return (correctAnswers / totalQuestions) * 100;
  }

  int get netTokenChange {
    return finalTokens - tokensStaked;
  }

  bool get isProfit {
    return netTokenChange > 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'tokensStaked': tokensStaked,
      'tokensWon': tokensWon,
      'tokensLost': tokensLost,
      'finalTokens': finalTokens,
      'completedAt': completedAt.toIso8601String(),
      'completed': completed,
      'questionResults': questionResults.map((qr) => qr.toJson()).toList(),
    };
  }

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      wrongAnswers: json['wrongAnswers'] ?? 0,
      tokensStaked: json['tokensStaked'] ?? 0,
      tokensWon: json['tokensWon'] ?? 0,
      tokensLost: json['tokensLost'] ?? 0,
      finalTokens: json['finalTokens'] ?? 0,
      completedAt: DateTime.parse(json['completedAt'] ?? DateTime.now().toIso8601String()),
      completed: json['completed'] ?? false,
      questionResults: (json['questionResults'] as List<dynamic>? ?? [])
          .map((qr) => QuestionResult.fromJson(qr))
          .toList(),
    );
  }
}

class QuestionResult {
  final String questionId;
  final String questionText;
  final int selectedIndex;
  final int correctIndex;
  final bool isCorrect;
  final int timeSpent; // in seconds
  final int tokensChange;

  QuestionResult({
    required this.questionId,
    required this.questionText,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isCorrect,
    required this.timeSpent,
    required this.tokensChange,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'selectedIndex': selectedIndex,
      'correctIndex': correctIndex,
      'isCorrect': isCorrect,
      'timeSpent': timeSpent,
      'tokensChange': tokensChange,
    };
  }

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionId: json['questionId'] ?? '',
      questionText: json['questionText'] ?? '',
      selectedIndex: json['selectedIndex'] ?? -1,
      correctIndex: json['correctIndex'] ?? 0,
      isCorrect: json['isCorrect'] ?? false,
      timeSpent: json['timeSpent'] ?? 0,
      tokensChange: json['tokensChange'] ?? 0,
    );
  }
}

class QuizSession {
  final String id;
  final String categoryId;
  final String categoryName;
  final List<Question> questions;
  final int entryFee;
  int currentQuestionIndex;
  int currentTokens;
  List<QuestionResult> results;
  DateTime startTime;
  bool isActive;

  QuizSession({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.questions,
    required this.entryFee,
    this.currentQuestionIndex = 0,
    int? initialTokens,
    List<QuestionResult>? results,
    DateTime? startTime,
    this.isActive = true,
  }) : 
    currentTokens = initialTokens ?? entryFee,
    results = results ?? [],
    startTime = startTime ?? DateTime.now();

  Question? get currentQuestion {
    if (currentQuestionIndex < questions.length) {
      return questions[currentQuestionIndex];
    }
    return null;
  }

  bool get hasMoreQuestions {
    return currentQuestionIndex < questions.length;
  }

  bool get isGameOver {
    return currentTokens <= 0 || !hasMoreQuestions;
  }

  int get correctAnswers {
    return results.where((r) => r.isCorrect).length;
  }

  int get wrongAnswers {
    return results.where((r) => !r.isCorrect).length;
  }

  void answerCurrentQuestion(int selectedIndex, int timeSpent) {
    final question = currentQuestion;
    if (question == null) return;

    final isCorrect = question.isCorrect(selectedIndex);
    final tokensChange = isCorrect ? 1 : -1;
    
    currentTokens += tokensChange;
    
    results.add(QuestionResult(
      questionId: question.id,
      questionText: question.text,
      selectedIndex: selectedIndex,
      correctIndex: question.correctIndex,
      isCorrect: isCorrect,
      timeSpent: timeSpent,
      tokensChange: tokensChange,
    ));
    
    currentQuestionIndex++;
    
    if (currentTokens <= 0 || !hasMoreQuestions) {
      isActive = false;
    }
  }

  QuizResult generateResult() {
    return QuizResult(
      categoryId: categoryId,
      categoryName: categoryName,
      totalQuestions: questions.length,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      tokensStaked: entryFee,
      tokensWon: results.where((r) => r.tokensChange > 0).length,
      tokensLost: results.where((r) => r.tokensChange < 0).length,
      finalTokens: currentTokens,
      completedAt: DateTime.now(),
      completed: currentQuestionIndex >= questions.length,
      questionResults: results,
    );
  }
}
