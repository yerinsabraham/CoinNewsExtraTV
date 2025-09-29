import 'dart:math';
import '../models/quiz_models.dart';

class QuizDataService {
  static const int defaultEntryFee = 5;
  static const int questionsPerQuiz = 10;
  static const int questionTimeLimit = 15; // seconds

  // Quiz categories
  static final List<QuizCategory> categories = [
    QuizCategory(
      id: 'blockchain',
      name: 'Blockchain',
      description: 'Test your knowledge of blockchain technology',
      iconName: 'blockchain',
      totalQuestions: 20,
      colors: ['#1E3A8A', '#3B82F6'], // Blue gradient
    ),
    QuizCategory(
      id: 'fintech',
      name: 'FinTech',
      description: 'Financial technology and digital payments',
      iconName: 'fintech',
      totalQuestions: 18,
      colors: ['#059669', '#10B981'], // Green gradient
    ),
    QuizCategory(
      id: 'tech',
      name: 'Technology',
      description: 'General technology and programming',
      iconName: 'tech',
      totalQuestions: 25,
      colors: ['#7C3AED', '#A855F7'], // Purple gradient
    ),
    QuizCategory(
      id: 'healthtech',
      name: 'HealthTech',
      description: 'Healthcare technology and innovation',
      iconName: 'health',
      totalQuestions: 15,
      colors: ['#DC2626', '#EF4444'], // Red gradient
    ),
    QuizCategory(
      id: 'ai',
      name: 'Artificial Intelligence',
      description: 'AI, machine learning, and automation',
      iconName: 'ai',
      totalQuestions: 22,
      colors: ['#EA580C', '#F97316'], // Orange gradient
    ),
    QuizCategory(
      id: 'cybersecurity',
      name: 'Cybersecurity',
      description: 'Security, privacy, and data protection',
      iconName: 'security',
      totalQuestions: 16,
      colors: ['#BE185D', '#EC4899'], // Pink gradient
    ),
  ];

  // All quiz questions organized by category
  static final Map<String, List<Question>> _questionBank = {
    'blockchain': [
      Question(
        id: 'blockchain_001',
        text: 'What does "DeFi" stand for?',
        options: ['Decentralized Finance', 'Digital File', 'Deep Finance', 'Data Fidelity'],
        correctIndex: 0,
        category: 'blockchain',
        explanation: 'DeFi stands for Decentralized Finance, which refers to financial services built on blockchain technology.',
      ),
      Question(
        id: 'blockchain_002',
        text: 'Who is the pseudonymous creator of Bitcoin?',
        options: ['Vitalik Buterin', 'Satoshi Nakamoto', 'Elon Musk', 'Nick Szabo'],
        correctIndex: 1,
        category: 'blockchain',
        explanation: 'Satoshi Nakamoto is the pseudonymous person or group who created Bitcoin.',
      ),
      Question(
        id: 'blockchain_003',
        text: 'What is the maximum supply of Bitcoin?',
        options: ['21 million', '100 million', '50 million', 'Unlimited'],
        correctIndex: 0,
        category: 'blockchain',
        explanation: 'Bitcoin has a maximum supply cap of 21 million coins.',
      ),
      Question(
        id: 'blockchain_004',
        text: 'Which consensus mechanism does Ethereum 2.0 use?',
        options: ['Proof of Work', 'Proof of Stake', 'Proof of Authority', 'Proof of Burn'],
        correctIndex: 1,
        category: 'blockchain',
        explanation: 'Ethereum 2.0 uses Proof of Stake (PoS) consensus mechanism.',
      ),
      Question(
        id: 'blockchain_005',
        text: 'What does "HODL" mean in cryptocurrency culture?',
        options: ['Hold On for Dear Life', 'High Order Digital Ledger', 'Hold', 'Highly Optimized Data Link'],
        correctIndex: 0,
        category: 'blockchain',
        explanation: 'HODL stands for "Hold On for Dear Life" and means to hold cryptocurrency long-term.',
      ),
      Question(
        id: 'blockchain_006',
        text: 'What is a smart contract?',
        options: ['A legal document', 'Self-executing code on blockchain', 'A mining contract', 'A wallet agreement'],
        correctIndex: 1,
        category: 'blockchain',
        explanation: 'A smart contract is self-executing code that runs on a blockchain network.',
      ),
      Question(
        id: 'blockchain_007',
        text: 'Which blockchain platform is known for smart contracts?',
        options: ['Bitcoin', 'Ethereum', 'Litecoin', 'Dogecoin'],
        correctIndex: 1,
        category: 'blockchain',
        explanation: 'Ethereum is widely known as the leading platform for smart contracts.',
      ),
      Question(
        id: 'blockchain_008',
        text: 'What is an NFT?',
        options: ['Non-Fungible Token', 'New Financial Technology', 'Network File Transfer', 'Next Future Token'],
        correctIndex: 0,
        category: 'blockchain',
        explanation: 'NFT stands for Non-Fungible Token, representing unique digital assets.',
      ),
      Question(
        id: 'blockchain_009',
        text: 'What is gas in Ethereum?',
        options: ['A type of fuel', 'Transaction fee', 'Mining reward', 'Storage space'],
        correctIndex: 1,
        category: 'blockchain',
        explanation: 'Gas in Ethereum refers to the fee paid for executing transactions and smart contracts.',
      ),
      Question(
        id: 'blockchain_010',
        text: 'What is a blockchain fork?',
        options: ['A mining tool', 'A protocol upgrade or split', 'A wallet feature', 'A trading strategy'],
        correctIndex: 1,
        category: 'blockchain',
        explanation: 'A blockchain fork is a protocol upgrade or split that creates new rules or a new blockchain.',
      ),
      Question(
        id: 'blockchain_011',
        text: 'What does "mining" mean in blockchain?',
        options: ['Digging for coins', 'Validating transactions', 'Creating wallets', 'Trading tokens'],
        correctIndex: 1,
        category: 'blockchain',
        explanation: 'Mining in blockchain refers to the process of validating transactions and adding them to the blockchain.',
      ),
      Question(
        id: 'blockchain_012',
        text: 'What is a private key?',
        options: ['A secret password for your wallet', 'A public address', 'A mining algorithm', 'A smart contract'],
        correctIndex: 0,
        category: 'blockchain',
        explanation: 'A private key is a secret cryptographic key that allows you to access and control your cryptocurrency.',
      ),
      Question(
        id: 'blockchain_013',
        text: 'What is the first block in a blockchain called?',
        options: ['Origin block', 'Genesis block', 'Prime block', 'Alpha block'],
        correctIndex: 1,
        category: 'blockchain',
        explanation: 'The first block in a blockchain is called the Genesis block.',
      ),
      Question(
        id: 'blockchain_014',
        text: 'What is a wallet address?',
        options: ['Your home address', 'A public key for receiving crypto', 'A private key', 'A mining location'],
        correctIndex: 1,
        category: 'blockchain',
        explanation: 'A wallet address is a public key used to receive cryptocurrency transactions.',
      ),
      Question(
        id: 'blockchain_015',
        text: 'What does "DYOR" mean?',
        options: ['Do Your Own Research', 'Decentralized Yield Offering', 'Digital Year Over Ratio', 'Dynamic Yield Optimization'],
        correctIndex: 0,
        category: 'blockchain',
        explanation: 'DYOR stands for "Do Your Own Research" - advice to research before investing.',
      ),
    ],
    
    'fintech': [
      Question(
        id: 'fintech_001',
        text: 'What does API stand for in financial technology?',
        options: ['Application Programming Interface', 'Automated Payment Integration', 'Advanced Processing Intelligence', 'Asset Protection Insurance'],
        correctIndex: 0,
        category: 'fintech',
        explanation: 'API stands for Application Programming Interface, enabling software integration.',
      ),
      Question(
        id: 'fintech_002',
        text: 'Which payment method uses NFC technology?',
        options: ['Bank transfer', 'Contactless payments', 'Check payments', 'Wire transfer'],
        correctIndex: 1,
        category: 'fintech',
        explanation: 'Contactless payments use NFC (Near Field Communication) technology.',
      ),
      Question(
        id: 'fintech_003',
        text: 'What is KYC in financial services?',
        options: ['Keep Your Cash', 'Know Your Customer', 'Key Yield Calculation', 'Kinetic Yield Control'],
        correctIndex: 1,
        category: 'fintech',
        explanation: 'KYC stands for Know Your Customer, a compliance process to verify client identity.',
      ),
      Question(
        id: 'fintech_004',
        text: 'What is a digital wallet?',
        options: ['A physical wallet', 'Software for storing payment info', 'A bank account', 'A credit card'],
        correctIndex: 1,
        category: 'fintech',
        explanation: 'A digital wallet is software that stores payment information and passwords securely.',
      ),
      Question(
        id: 'fintech_005',
        text: 'What does P2P mean in payments?',
        options: ['Pay to Play', 'Peer-to-Peer', 'Public to Private', 'Point to Point'],
        correctIndex: 1,
        category: 'fintech',
        explanation: 'P2P stands for Peer-to-Peer, allowing direct transfers between users.',
      ),
      Question(
        id: 'fintech_006',
        text: 'What is robo-advising?',
        options: ['Robot banking', 'Automated investment management', 'AI customer service', 'Digital marketing'],
        correctIndex: 1,
        category: 'fintech',
        explanation: 'Robo-advising is automated investment management using algorithms.',
      ),
      Question(
        id: 'fintech_007',
        text: 'What is RegTech?',
        options: ['Regular Technology', 'Regulatory Technology', 'Registration Tech', 'Revenue Technology'],
        correctIndex: 1,
        category: 'fintech',
        explanation: 'RegTech refers to technology solutions for regulatory compliance.',
      ),
      Question(
        id: 'fintech_008',
        text: 'What is open banking?',
        options: ['24/7 banking', 'Sharing financial data via APIs', 'Free banking services', 'Public banking'],
        correctIndex: 1,
        category: 'fintech',
        explanation: 'Open banking allows third parties to access financial data through APIs.',
      ),
      Question(
        id: 'fintech_009',
        text: 'What is a neo bank?',
        options: ['A new bank branch', 'A digital-only bank', 'A cryptocurrency bank', 'A foreign bank'],
        correctIndex: 1,
        category: 'fintech',
        explanation: 'A neo bank is a digital-only bank without physical branches.',
      ),
      Question(
        id: 'fintech_010',
        text: 'What is PCI DSS?',
        options: ['Payment Card Industry Data Security Standard', 'Personal Credit Information System', 'Public Card Integration Service', 'Private Customer Data Standard'],
        correctIndex: 0,
        category: 'fintech',
        explanation: 'PCI DSS is the Payment Card Industry Data Security Standard for protecting card data.',
      ),
    ],
    
    'tech': [
      Question(
        id: 'tech_001',
        text: 'What does HTML stand for?',
        options: ['HyperText Markup Language', 'Home Tool Markup Language', 'Hyperlink Text Management Language', 'High Tech Modern Language'],
        correctIndex: 0,
        category: 'tech',
        explanation: 'HTML stands for HyperText Markup Language, used to create web pages.',
      ),
      Question(
        id: 'tech_002',
        text: 'Which programming language is known as the "language of the web"?',
        options: ['Python', 'JavaScript', 'Java', 'C++'],
        correctIndex: 1,
        category: 'tech',
        explanation: 'JavaScript is known as the "language of the web" for client-side scripting.',
      ),
      Question(
        id: 'tech_003',
        text: 'What does CPU stand for?',
        options: ['Central Processing Unit', 'Computer Personal Unit', 'Central Program Utility', 'Core Processing Unit'],
        correctIndex: 0,
        category: 'tech',
        explanation: 'CPU stands for Central Processing Unit, the main processor of a computer.',
      ),
      Question(
        id: 'tech_004',
        text: 'What is the purpose of DNS?',
        options: ['Data Network Security', 'Domain Name System', 'Digital Network Service', 'Data Navigation System'],
        correctIndex: 1,
        category: 'tech',
        explanation: 'DNS (Domain Name System) translates domain names to IP addresses.',
      ),
      Question(
        id: 'tech_005',
        text: 'What does SQL stand for?',
        options: ['Structured Query Language', 'System Query Language', 'Simple Query Language', 'Standard Query Language'],
        correctIndex: 0,
        category: 'tech',
        explanation: 'SQL stands for Structured Query Language, used for managing databases.',
      ),
      Question(
        id: 'tech_006',
        text: 'What is cloud computing?',
        options: ['Weather prediction', 'Internet-based computing services', 'Atmospheric computing', 'Sky-based storage'],
        correctIndex: 1,
        category: 'tech',
        explanation: 'Cloud computing delivers computing services over the internet.',
      ),
      Question(
        id: 'tech_007',
        text: 'What does API stand for?',
        options: ['Application Programming Interface', 'Automated Program Integration', 'Advanced Programming Intelligence', 'Application Process Integration'],
        correctIndex: 0,
        category: 'tech',
        explanation: 'API stands for Application Programming Interface, enabling software communication.',
      ),
      Question(
        id: 'tech_008',
        text: 'What is version control in software development?',
        options: ['Controlling software versions', 'Managing code changes over time', 'Version numbering system', 'Software licensing'],
        correctIndex: 1,
        category: 'tech',
        explanation: 'Version control manages and tracks changes to code over time.',
      ),
      Question(
        id: 'tech_009',
        text: 'What does HTTP stand for?',
        options: ['HyperText Transfer Protocol', 'High Tech Transfer Process', 'Home Text Transfer Protocol', 'HyperText Transport Process'],
        correctIndex: 0,
        category: 'tech',
        explanation: 'HTTP stands for HyperText Transfer Protocol, used for web communication.',
      ),
      Question(
        id: 'tech_010',
        text: 'What is a framework in programming?',
        options: ['A physical structure', 'A pre-built code structure', 'A testing tool', 'A design pattern'],
        correctIndex: 1,
        category: 'tech',
        explanation: 'A framework is a pre-built code structure that provides a foundation for development.',
      ),
    ],
    
    'healthtech': [
      Question(
        id: 'health_001',
        text: 'What does EHR stand for in healthcare?',
        options: ['Emergency Health Response', 'Electronic Health Record', 'Enhanced Health Recovery', 'Emergency Hospital Registration'],
        correctIndex: 1,
        category: 'healthtech',
        explanation: 'EHR stands for Electronic Health Record, digital patient information systems.',
      ),
      Question(
        id: 'health_002',
        text: 'What is telemedicine?',
        options: ['Television medicine', 'Remote healthcare delivery', 'Telephone consultations only', 'Medical TV shows'],
        correctIndex: 1,
        category: 'healthtech',
        explanation: 'Telemedicine is the remote delivery of healthcare services using technology.',
      ),
      Question(
        id: 'health_003',
        text: 'What does IoMT stand for?',
        options: ['Internet of Medical Things', 'International Medical Technology', 'Integrated Medical Tools', 'Internet of Modern Technology'],
        correctIndex: 0,
        category: 'healthtech',
        explanation: 'IoMT stands for Internet of Medical Things, connected medical devices.',
      ),
      Question(
        id: 'health_004',
        text: 'What is HIPAA in healthcare?',
        options: ['Health Insurance Portability and Accountability Act', 'Healthcare Information Privacy Act', 'Hospital Insurance Protection Act', 'Health Information Processing Act'],
        correctIndex: 0,
        category: 'healthtech',
        explanation: 'HIPAA is the Health Insurance Portability and Accountability Act, protecting patient data.',
      ),
      Question(
        id: 'health_005',
        text: 'What is AI used for in healthcare?',
        options: ['Only administrative tasks', 'Diagnosis, treatment, and drug discovery', 'Only scheduling appointments', 'Only billing processes'],
        correctIndex: 1,
        category: 'healthtech',
        explanation: 'AI in healthcare is used for diagnosis, treatment planning, drug discovery, and more.',
      ),
    ],
    
    'ai': [
      Question(
        id: 'ai_001',
        text: 'What does ML stand for in AI?',
        options: ['Machine Learning', 'Manual Logic', 'Multiple Languages', 'Modern Logic'],
        correctIndex: 0,
        category: 'ai',
        explanation: 'ML stands for Machine Learning, a subset of artificial intelligence.',
      ),
      Question(
        id: 'ai_002',
        text: 'What is a neural network?',
        options: ['A computer network', 'AI model inspired by the brain', 'A social network', 'A data network'],
        correctIndex: 1,
        category: 'ai',
        explanation: 'A neural network is an AI model inspired by biological neural networks in the brain.',
      ),
      Question(
        id: 'ai_003',
        text: 'What does NLP stand for?',
        options: ['Natural Language Processing', 'Network Learning Protocol', 'Neural Learning Process', 'New Logic Programming'],
        correctIndex: 0,
        category: 'ai',
        explanation: 'NLP stands for Natural Language Processing, enabling computers to understand human language.',
      ),
      Question(
        id: 'ai_004',
        text: 'What is deep learning?',
        options: ['Advanced study methods', 'ML with multiple neural network layers', 'Ocean exploration AI', 'Psychological learning'],
        correctIndex: 1,
        category: 'ai',
        explanation: 'Deep learning uses neural networks with multiple layers to learn complex patterns.',
      ),
      Question(
        id: 'ai_005',
        text: 'What is computer vision?',
        options: ['Computer screens', 'AI that interprets visual information', 'Eye care for computer users', 'Computer display technology'],
        correctIndex: 1,
        category: 'ai',
        explanation: 'Computer vision is AI technology that interprets and analyzes visual information.',
      ),
    ],
    
    'cybersecurity': [
      Question(
        id: 'cyber_001',
        text: 'What is phishing?',
        options: ['Catching fish online', 'Fraudulent attempt to obtain sensitive info', 'A fishing game', 'Network fishing protocol'],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation: 'Phishing is a fraudulent attempt to obtain sensitive information by disguising as trustworthy.',
      ),
      Question(
        id: 'cyber_002',
        text: 'What does VPN stand for?',
        options: ['Virtual Private Network', 'Very Private Network', 'Verified Public Network', 'Virtual Public Network'],
        correctIndex: 0,
        category: 'cybersecurity',
        explanation: 'VPN stands for Virtual Private Network, creating secure connections over the internet.',
      ),
      Question(
        id: 'cyber_003',
        text: 'What is malware?',
        options: ['Bad software', 'Malicious software', 'Male software', 'Manual software'],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation: 'Malware is malicious software designed to damage or gain unauthorized access to systems.',
      ),
      Question(
        id: 'cyber_004',
        text: 'What is two-factor authentication?',
        options: ['Two passwords', 'Additional security layer with second verification', 'Two user accounts', 'Double encryption'],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation: 'Two-factor authentication adds an extra security layer with a second form of verification.',
      ),
      Question(
        id: 'cyber_005',
        text: 'What is encryption?',
        options: ['Hiding files', 'Converting data into coded format', 'Compressing data', 'Backing up data'],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation: 'Encryption converts data into a coded format to prevent unauthorized access.',
      ),
    ],
  };

  // Get all categories
  static List<QuizCategory> getCategories() {
    return List.from(categories);
  }

  // Get category by ID
  static QuizCategory? getCategoryById(String categoryId) {
    try {
      return categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Get questions for a specific category
  static List<Question> getQuestionsByCategory(String categoryId) {
    return _questionBank[categoryId] ?? [];
  }

  // Get random questions for a quiz session
  static List<Question> getRandomQuestions(String categoryId, {int count = questionsPerQuiz}) {
    final allQuestions = getQuestionsByCategory(categoryId);
    if (allQuestions.isEmpty) return [];
    
    final shuffled = List<Question>.from(allQuestions);
    shuffled.shuffle();
    
    return shuffled.take(count).toList();
  }

  // Create a new quiz session
  static QuizSession createQuizSession(String categoryId) {
    final category = getCategoryById(categoryId);
    if (category == null) {
      throw Exception('Category not found: $categoryId');
    }

    final questions = getRandomQuestions(categoryId);
    if (questions.isEmpty) {
      throw Exception('No questions available for category: $categoryId');
    }

    return QuizSession(
      id: _generateSessionId(),
      categoryId: categoryId,
      categoryName: category.name,
      questions: questions,
      entryFee: defaultEntryFee,
    );
  }

  // Generate unique session ID
  static String _generateSessionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(9999).toString().padLeft(4, '0');
    return 'quiz_${timestamp}_$randomSuffix';
  }

  // Validate answer and calculate score
  static bool validateAnswer(Question question, int selectedIndex) {
    return question.isCorrect(selectedIndex);
  }

  // Get user statistics (mock implementation)
  static Map<String, dynamic> getUserStats() {
    return {
      'totalQuizzesPlayed': 0,
      'totalCorrectAnswers': 0,
      'totalWrongAnswers': 0,
      'totalTokensWon': 0,
      'totalTokensLost': 0,
      'favoriteCategory': 'blockchain',
      'averageAccuracy': 0.0,
      'bestStreak': 0,
      'currentStreak': 0,
    };
  }

  // Get leaderboard (mock implementation)
  static List<Map<String, dynamic>> getLeaderboard() {
    return [
      {'username': 'CryptoKing', 'score': 2580, 'accuracy': 89.5},
      {'username': 'BlockchainQueen', 'score': 2340, 'accuracy': 87.2},
      {'username': 'TechGuru', 'score': 2190, 'accuracy': 85.8},
      {'username': 'FinTechPro', 'score': 2050, 'accuracy': 84.1},
      {'username': 'AIExpert', 'score': 1980, 'accuracy': 82.7},
    ];
  }
}
