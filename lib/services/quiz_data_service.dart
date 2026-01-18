import 'dart:math';
import '../models/quiz_models.dart';

class QuizDataService {
  // Entry fee removed — quizzes are free to enter
  static const int defaultEntryFee = 0;
  static const int questionsPerQuiz = 10;
  static const int questionTimeLimit = 15; // seconds

  // Quiz categories
  static final List<QuizCategory> categories = [
    QuizCategory(
      id: 'blockchain',
      name: 'Blockchain',
      description: 'Test your knowledge of blockchain technology',
      iconName: 'blockchain',
      totalQuestions: 35,
      colors: ['#1E3A8A', '#3B82F6'], // Blue gradient
    ),
    QuizCategory(
      id: 'fintech',
      name: 'FinTech',
      description: 'Financial technology and digital payments',
      iconName: 'fintech',
      totalQuestions: 25,
      colors: ['#059669', '#10B981'], // Green gradient
    ),
    QuizCategory(
      id: 'tech',
      name: 'Technology',
      description: 'General technology and programming',
      iconName: 'tech',
      totalQuestions: 30,
      colors: ['#7C3AED', '#A855F7'], // Purple gradient
    ),
    QuizCategory(
      id: 'healthtech',
      name: 'HealthTech',
      description: 'Healthcare technology and innovation',
      iconName: 'health',
      totalQuestions: 20,
      colors: ['#DC2626', '#EF4444'], // Red gradient
    ),
    QuizCategory(
      id: 'ai',
      name: 'Artificial Intelligence',
      description: 'AI, machine learning, and automation',
      iconName: 'ai',
      totalQuestions: 25,
      colors: ['#EA580C', '#F97316'], // Orange gradient
    ),
    QuizCategory(
      id: 'cybersecurity',
      name: 'Cybersecurity',
      description: 'Security, privacy, and data protection',
      iconName: 'security',
      totalQuestions: 25,
      colors: ['#BE185D', '#EC4899'], // Pink gradient
    ),
  ];

  // All quiz questions organized by category
  static final Map<String, List<Question>> _questionBank = {
    'blockchain': [
      Question(
        id: 'blockchain_001',
        text: 'What does "DeFi" stand for?',
        options: [
          'Decentralized Finance',
          'Digital File',
          'Deep Finance',
          'Data Fidelity'
        ],
        correctIndex: 0,
        category: 'blockchain',
        explanation:
            'DeFi stands for Decentralized Finance, which refers to financial services built on blockchain technology.',
      ),
      Question(
        id: 'blockchain_002',
        text: 'Who is the pseudonymous creator of Bitcoin?',
        options: [
          'Vitalik Buterin',
          'Satoshi Nakamoto',
          'Elon Musk',
          'Nick Szabo'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'Satoshi Nakamoto is the pseudonymous person or group who created Bitcoin.',
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
        options: [
          'Proof of Work',
          'Proof of Stake',
          'Proof of Authority',
          'Proof of Burn'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'Ethereum 2.0 uses Proof of Stake (PoS) consensus mechanism.',
      ),
      Question(
        id: 'blockchain_005',
        text: 'What does "HODL" mean in cryptocurrency culture?',
        options: [
          'Hold On for Dear Life',
          'High Order Digital Ledger',
          'Hold',
          'Highly Optimized Data Link'
        ],
        correctIndex: 0,
        category: 'blockchain',
        explanation:
            'HODL stands for "Hold On for Dear Life" and means to hold cryptocurrency long-term.',
      ),
      Question(
        id: 'blockchain_006',
        text: 'What is a smart contract?',
        options: [
          'A legal document',
          'Self-executing code on blockchain',
          'A mining contract',
          'A wallet agreement'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'A smart contract is self-executing code that runs on a blockchain network.',
      ),
      Question(
        id: 'blockchain_007',
        text: 'Which blockchain platform is known for smart contracts?',
        options: ['Bitcoin', 'Ethereum', 'Litecoin', 'Dogecoin'],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'Ethereum is widely known as the leading platform for smart contracts.',
      ),
      Question(
        id: 'blockchain_008',
        text: 'What is an NFT?',
        options: [
          'Non-Fungible Token',
          'New Financial Technology',
          'Network File Transfer',
          'Next Future Token'
        ],
        correctIndex: 0,
        category: 'blockchain',
        explanation:
            'NFT stands for Non-Fungible Token, representing unique digital assets.',
      ),
      Question(
        id: 'blockchain_009',
        text: 'What is gas in Ethereum?',
        options: [
          'A type of fuel',
          'Transaction fee',
          'Mining reward',
          'Storage space'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'Gas in Ethereum refers to the fee paid for executing transactions and smart contracts.',
      ),
      Question(
        id: 'blockchain_010',
        text: 'What is a blockchain fork?',
        options: [
          'A mining tool',
          'A protocol upgrade or split',
          'A wallet feature',
          'A trading strategy'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'A blockchain fork is a protocol upgrade or split that creates new rules or a new blockchain.',
      ),
      Question(
        id: 'blockchain_011',
        text: 'What does "mining" mean in blockchain?',
        options: [
          'Digging for coins',
          'Validating transactions',
          'Creating wallets',
          'Trading tokens'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'Mining in blockchain refers to the process of validating transactions and adding them to the blockchain.',
      ),
      Question(
        id: 'blockchain_012',
        text: 'What is a private key?',
        options: [
          'A secret password for your wallet',
          'A public address',
          'A mining algorithm',
          'A smart contract'
        ],
        correctIndex: 0,
        category: 'blockchain',
        explanation:
            'A private key is a secret cryptographic key that allows you to access and control your cryptocurrency.',
      ),
      Question(
        id: 'blockchain_013',
        text: 'What is the first block in a blockchain called?',
        options: [
          'Origin block',
          'Genesis block',
          'Prime block',
          'Alpha block'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'The first block in a blockchain is called the Genesis block.',
      ),
      Question(
        id: 'blockchain_014',
        text: 'What is a wallet address?',
        options: [
          'Your home address',
          'A public key for receiving crypto',
          'A private key',
          'A mining location'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'A wallet address is a public key used to receive cryptocurrency transactions.',
      ),
      Question(
        id: 'blockchain_015',
        text: 'What does "DYOR" mean?',
        options: [
          'Do Your Own Research',
          'Decentralized Yield Offering',
          'Digital Year Over Ratio',
          'Dynamic Yield Optimization'
        ],
        correctIndex: 0,
        category: 'blockchain',
        explanation:
            'DYOR stands for "Do Your Own Research" - advice to research before investing.',
      ),
      Question(
        id: 'blockchain_016',
        text: 'What is a DAO?',
        options: [
          'Decentralized Autonomous Organization',
          'Digital Asset Operation',
          'Data Access Object',
          'Distributed Application Organization'
        ],
        correctIndex: 0,
        category: 'blockchain',
        explanation:
            'DAO stands for Decentralized Autonomous Organization, governed by smart contracts.',
      ),
      Question(
        id: 'blockchain_017',
        text: 'What is a blockchain oracle?',
        options: [
          'A prediction service',
          'A data feed to smart contracts',
          'A fortune teller',
          'A mining algorithm'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'Oracles provide external data to smart contracts on the blockchain.',
      ),
      Question(
        id: 'blockchain_018',
        text: 'What does "staking" mean in crypto?',
        options: [
          'Gambling',
          'Locking tokens to support network operations',
          'Selling tokens',
          'Mining'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'Staking involves locking cryptocurrency to support network operations and earn rewards.',
      ),
      Question(
        id: 'blockchain_019',
        text: 'What is a Layer 2 solution?',
        options: [
          'A second blockchain',
          'A scaling solution built on top of a blockchain',
          'A backup system',
          'A security layer'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'Layer 2 solutions are built on top of blockchains to improve scalability.',
      ),
      Question(
        id: 'blockchain_020',
        text: 'What is the Lightning Network?',
        options: [
          'A fast internet service',
          'A Bitcoin Layer 2 scaling solution',
          'An Ethereum upgrade',
          'A mining pool'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'Lightning Network is a Layer 2 solution for faster Bitcoin transactions.',
      ),
      Question(
        id: 'blockchain_021',
        text: 'What is a hash rate?',
        options: [
          'Internet speed',
          'Mining computational power',
          'Transaction speed',
          'Storage capacity'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'Hash rate measures the computational power used in mining and processing transactions.',
      ),
      Question(
        id: 'blockchain_022',
        text: 'What is sharding in blockchain?',
        options: [
          'Breaking glass',
          'Splitting the blockchain into smaller parts',
          'Mining technique',
          'Token burning'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'Sharding splits the blockchain into smaller parts to improve scalability.',
      ),
      Question(
        id: 'blockchain_023',
        text: 'What is a mempool?',
        options: [
          'Memory pool of unconfirmed transactions',
          'A storage device',
          'A mining pool',
          'A wallet type'
        ],
        correctIndex: 0,
        category: 'blockchain',
        explanation:
            'Mempool is a waiting area for unconfirmed transactions before they are added to blocks.',
      ),
      Question(
        id: 'blockchain_024',
        text: 'What is ERC-20?',
        options: [
          'A Bitcoin standard',
          'An Ethereum token standard',
          'A mining algorithm',
          'A wallet type'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'ERC-20 is a technical standard for fungible tokens on Ethereum.',
      ),
      Question(
        id: 'blockchain_025',
        text: 'What does "burn" mean in crypto?',
        options: [
          'Losing money',
          'Permanently removing tokens from circulation',
          'Hot storage',
          'Energy usage'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'Burning crypto means permanently removing tokens from circulation.',
      ),
      Question(
        id: 'blockchain_026',
        text: 'What is a 51% attack?',
        options: [
          'Tax attack',
          'Gaining majority control of network mining power',
          'Price manipulation',
          'Wallet hack'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'A 51% attack occurs when an entity controls majority of network mining power.',
      ),
      Question(
        id: 'blockchain_027',
        text: 'What is cross-chain technology?',
        options: [
          'Multiple necklaces',
          'Interoperability between different blockchains',
          'Chain manufacturing',
          'Security feature'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'Cross-chain tech enables interaction and value transfer between different blockchains.',
      ),
      Question(
        id: 'blockchain_028',
        text: 'What is tokenomics?',
        options: [
          'Token economics and distribution',
          'Token mining',
          'Token storage',
          'Token trading'
        ],
        correctIndex: 0,
        category: 'blockchain',
        explanation:
            'Tokenomics refers to the economic model and distribution strategy of a token.',
      ),
      Question(
        id: 'blockchain_029',
        text: 'What is a whitepaper in crypto?',
        options: [
          'A white document',
          'Technical document explaining a project',
          'A blank paper',
          'A legal contract'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'A whitepaper is a detailed document explaining a crypto project\'s technology and vision.',
      ),
      Question(
        id: 'blockchain_030',
        text: 'What is yield farming?',
        options: [
          'Agricultural investment',
          'Earning crypto by providing liquidity',
          'Mining rewards',
          'Staking rewards'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'Yield farming involves earning rewards by providing liquidity to DeFi protocols.',
      ),
      Question(
        id: 'blockchain_031',
        text: 'What is slippage in crypto trading?',
        options: [
          'Price difference between expected and executed trade',
          'A trading mistake',
          'Network delay',
          'Fee structure'
        ],
        correctIndex: 0,
        category: 'blockchain',
        explanation:
            'Slippage is the difference between expected and actual trade execution price.',
      ),
      Question(
        id: 'blockchain_032',
        text: 'What is TVL in DeFi?',
        options: [
          'Total Value Locked',
          'Transaction Validation Level',
          'Token Velocity Limit',
          'Transfer Volume Log'
        ],
        correctIndex: 0,
        category: 'blockchain',
        explanation:
            'TVL (Total Value Locked) measures the total value of assets locked in DeFi protocols.',
      ),
      Question(
        id: 'blockchain_033',
        text: 'What is an airdrop?',
        options: [
          'Dropping packages',
          'Free distribution of tokens',
          'A trading strategy',
          'A wallet feature'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'An airdrop is a free distribution of tokens to wallet addresses, often for marketing.',
      ),
      Question(
        id: 'blockchain_034',
        text: 'What is impermanent loss?',
        options: [
          'Temporary memory loss',
          'Loss from providing liquidity to pools',
          'Network downtime',
          'Price volatility'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'Impermanent loss occurs when providing liquidity and prices change.',
      ),
      Question(
        id: 'blockchain_035',
        text: 'What is a rugpull?',
        options: [
          'Removing carpet',
          'Scam where developers abandon project with funds',
          'A trading technique',
          'A mining error'
        ],
        correctIndex: 1,
        category: 'blockchain',
        explanation:
            'A rugpull is a scam where developers abandon a project and take investor funds.',
      ),
    ],
    'fintech': [
      Question(
        id: 'fintech_001',
        text: 'What does API stand for in financial technology?',
        options: [
          'Application Programming Interface',
          'Automated Payment Integration',
          'Advanced Processing Intelligence',
          'Asset Protection Insurance'
        ],
        correctIndex: 0,
        category: 'fintech',
        explanation:
            'API stands for Application Programming Interface, enabling software integration.',
      ),
      Question(
        id: 'fintech_002',
        text: 'Which payment method uses NFC technology?',
        options: [
          'Bank transfer',
          'Contactless payments',
          'Check payments',
          'Wire transfer'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'Contactless payments use NFC (Near Field Communication) technology.',
      ),
      Question(
        id: 'fintech_003',
        text: 'What is KYC in financial services?',
        options: [
          'Keep Your Cash',
          'Know Your Customer',
          'Key Yield Calculation',
          'Kinetic Yield Control'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'KYC stands for Know Your Customer, a compliance process to verify client identity.',
      ),
      Question(
        id: 'fintech_004',
        text: 'What is a digital wallet?',
        options: [
          'A physical wallet',
          'Software for storing payment info',
          'A bank account',
          'A credit card'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'A digital wallet is software that stores payment information and passwords securely.',
      ),
      Question(
        id: 'fintech_005',
        text: 'What does P2P mean in payments?',
        options: [
          'Pay to Play',
          'Peer-to-Peer',
          'Public to Private',
          'Point to Point'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'P2P stands for Peer-to-Peer, allowing direct transfers between users.',
      ),
      Question(
        id: 'fintech_006',
        text: 'What is robo-advising?',
        options: [
          'Robot banking',
          'Automated investment management',
          'AI customer service',
          'Digital marketing'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'Robo-advising is automated investment management using algorithms.',
      ),
      Question(
        id: 'fintech_007',
        text: 'What is RegTech?',
        options: [
          'Regular Technology',
          'Regulatory Technology',
          'Registration Tech',
          'Revenue Technology'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'RegTech refers to technology solutions for regulatory compliance.',
      ),
      Question(
        id: 'fintech_008',
        text: 'What is open banking?',
        options: [
          '24/7 banking',
          'Sharing financial data via APIs',
          'Free banking services',
          'Public banking'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'Open banking allows third parties to access financial data through APIs.',
      ),
      Question(
        id: 'fintech_009',
        text: 'What is a neo bank?',
        options: [
          'A new bank branch',
          'A digital-only bank',
          'A cryptocurrency bank',
          'A foreign bank'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'A neo bank is a digital-only bank without physical branches.',
      ),
      Question(
        id: 'fintech_010',
        text: 'What is PCI DSS?',
        options: [
          'Payment Card Industry Data Security Standard',
          'Personal Credit Information System',
          'Public Card Integration Service',
          'Private Customer Data Standard'
        ],
        correctIndex: 0,
        category: 'fintech',
        explanation:
            'PCI DSS is the Payment Card Industry Data Security Standard for protecting card data.',
      ),
      Question(
        id: 'fintech_011',
        text: 'What is InsurTech?',
        options: [
          'Insurance Technology',
          'Internet Technology',
          'Instant Technology',
          'Integrated Technology'
        ],
        correctIndex: 0,
        category: 'fintech',
        explanation:
            'InsurTech refers to technology innovations in the insurance industry.',
      ),
      Question(
        id: 'fintech_012',
        text: 'What is a CBDC?',
        options: [
          'Central Bank Digital Currency',
          'Corporate Banking Data Center',
          'Cross Border Digital Coin',
          'Crypto Bank Debit Card'
        ],
        correctIndex: 0,
        category: 'fintech',
        explanation:
            'CBDC is a Central Bank Digital Currency, digital form of fiat money.',
      ),
      Question(
        id: 'fintech_013',
        text: 'What is embedded finance?',
        options: [
          'Hidden fees',
          'Financial services integrated into non-financial platforms',
          'Banking infrastructure',
          'Mobile banking'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'Embedded finance integrates financial services into non-financial platforms.',
      ),
      Question(
        id: 'fintech_014',
        text: 'What is BNPL?',
        options: [
          'Bank Network Payment Link',
          'Buy Now Pay Later',
          'Business Network Protocol',
          'Banking Notification Process'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'BNPL stands for Buy Now Pay Later, a payment method allowing deferred payments.',
      ),
      Question(
        id: 'fintech_015',
        text: 'What is AML in finance?',
        options: [
          'Advanced Money Lending',
          'Anti-Money Laundering',
          'Automated Money Logic',
          'Asset Management Law'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'AML stands for Anti-Money Laundering, regulations to prevent illegal money transfers.',
      ),
      Question(
        id: 'fintech_016',
        text: 'What is a stablecoin?',
        options: [
          'A very stable coin',
          'Cryptocurrency pegged to stable assets',
          'A physical coin',
          'A government currency'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'A stablecoin is a cryptocurrency designed to maintain stable value, often pegged to fiat.',
      ),
      Question(
        id: 'fintech_017',
        text: 'What is PayTech?',
        options: [
          'Payment Technology',
          'Pay Television',
          'Payroll Technology',
          'Partner Technology'
        ],
        correctIndex: 0,
        category: 'fintech',
        explanation:
            'PayTech refers to technology innovations in payment systems.',
      ),
      Question(
        id: 'fintech_018',
        text: 'What is a challenger bank?',
        options: [
          'A competitive bank',
          'Digital bank competing with traditional banks',
          'A sports bank',
          'A foreign bank'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'Challenger banks are digital banks that compete with traditional banks.',
      ),
      Question(
        id: 'fintech_019',
        text: 'What is biometric authentication?',
        options: [
          'Biology study',
          'Identity verification using biological characteristics',
          'Medical authentication',
          'DNA testing'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'Biometric authentication uses biological characteristics like fingerprints for verification.',
      ),
      Question(
        id: 'fintech_020',
        text: 'What is WealthTech?',
        options: [
          'Wealth Management Technology',
          'Website Technology',
          'Wireless Technology',
          'World Technology'
        ],
        correctIndex: 0,
        category: 'fintech',
        explanation:
            'WealthTech refers to technology solutions for wealth and investment management.',
      ),
      Question(
        id: 'fintech_021',
        text: 'What is a PSP in payments?',
        options: [
          'Public Service Platform',
          'Payment Service Provider',
          'Personal Security Protocol',
          'Primary Service Provider'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'PSP stands for Payment Service Provider, enabling online payment processing.',
      ),
      Question(
        id: 'fintech_022',
        text: 'What is account aggregation?',
        options: [
          'Adding bank accounts',
          'Combining multiple financial accounts in one view',
          'Collecting fees',
          'Grouping transactions'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'Account aggregation consolidates multiple financial accounts into a single view.',
      ),
      Question(
        id: 'fintech_023',
        text: 'What is microfinance?',
        options: [
          'Small fees',
          'Financial services for low-income individuals',
          'Micro transactions',
          'Small investments'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'Microfinance provides financial services to low-income individuals or small businesses.',
      ),
      Question(
        id: 'fintech_024',
        text: 'What is instant payment?',
        options: [
          'Immediate money transfer',
          'Fast approval',
          'Quick login',
          'Instant refund'
        ],
        correctIndex: 0,
        category: 'fintech',
        explanation:
            'Instant payment enables real-time money transfers between accounts.',
      ),
      Question(
        id: 'fintech_025',
        text: 'What is a merchant acquirer?',
        options: [
          'Someone who buys merchants',
          'Bank processing merchant card payments',
          'Merchant finder',
          'Store owner'
        ],
        correctIndex: 1,
        category: 'fintech',
        explanation:
            'A merchant acquirer is a bank that processes card payments for merchants.',
      ),
    ],
    'tech': [
      Question(
        id: 'tech_001',
        text: 'What does HTML stand for?',
        options: [
          'HyperText Markup Language',
          'Home Tool Markup Language',
          'Hyperlink Text Management Language',
          'High Tech Modern Language'
        ],
        correctIndex: 0,
        category: 'tech',
        explanation:
            'HTML stands for HyperText Markup Language, used to create web pages.',
      ),
      Question(
        id: 'tech_002',
        text:
            'Which programming language is known as the "language of the web"?',
        options: ['Python', 'JavaScript', 'Java', 'C++'],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'JavaScript is known as the "language of the web" for client-side scripting.',
      ),
      Question(
        id: 'tech_003',
        text: 'What does CPU stand for?',
        options: [
          'Central Processing Unit',
          'Computer Personal Unit',
          'Central Program Utility',
          'Core Processing Unit'
        ],
        correctIndex: 0,
        category: 'tech',
        explanation:
            'CPU stands for Central Processing Unit, the main processor of a computer.',
      ),
      Question(
        id: 'tech_004',
        text: 'What is the purpose of DNS?',
        options: [
          'Data Network Security',
          'Domain Name System',
          'Digital Network Service',
          'Data Navigation System'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'DNS (Domain Name System) translates domain names to IP addresses.',
      ),
      Question(
        id: 'tech_005',
        text: 'What does SQL stand for?',
        options: [
          'Structured Query Language',
          'System Query Language',
          'Simple Query Language',
          'Standard Query Language'
        ],
        correctIndex: 0,
        category: 'tech',
        explanation:
            'SQL stands for Structured Query Language, used for managing databases.',
      ),
      Question(
        id: 'tech_006',
        text: 'What is cloud computing?',
        options: [
          'Weather prediction',
          'Internet-based computing services',
          'Atmospheric computing',
          'Sky-based storage'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'Cloud computing delivers computing services over the internet.',
      ),
      Question(
        id: 'tech_007',
        text: 'What does API stand for?',
        options: [
          'Application Programming Interface',
          'Automated Program Integration',
          'Advanced Programming Intelligence',
          'Application Process Integration'
        ],
        correctIndex: 0,
        category: 'tech',
        explanation:
            'API stands for Application Programming Interface, enabling software communication.',
      ),
      Question(
        id: 'tech_008',
        text: 'What is version control in software development?',
        options: [
          'Controlling software versions',
          'Managing code changes over time',
          'Version numbering system',
          'Software licensing'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'Version control manages and tracks changes to code over time.',
      ),
      Question(
        id: 'tech_009',
        text: 'What does HTTP stand for?',
        options: [
          'HyperText Transfer Protocol',
          'High Tech Transfer Process',
          'Home Text Transfer Protocol',
          'HyperText Transport Process'
        ],
        correctIndex: 0,
        category: 'tech',
        explanation:
            'HTTP stands for HyperText Transfer Protocol, used for web communication.',
      ),
      Question(
        id: 'tech_010',
        text: 'What is a framework in programming?',
        options: [
          'A physical structure',
          'A pre-built code structure',
          'A testing tool',
          'A design pattern'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'A framework is a pre-built code structure that provides a foundation for development.',
      ),
      Question(
        id: 'tech_011',
        text: 'What is Git?',
        options: [
          'A programming language',
          'A version control system',
          'A code editor',
          'A database'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'Git is a distributed version control system for tracking code changes.',
      ),
      Question(
        id: 'tech_012',
        text: 'What does IDE stand for?',
        options: [
          'Internet Development Environment',
          'Integrated Development Environment',
          'Internal Data Engine',
          'Interactive Design Editor'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'IDE stands for Integrated Development Environment, software for writing code.',
      ),
      Question(
        id: 'tech_013',
        text: 'What is Docker?',
        options: [
          'A shipping container',
          'A containerization platform',
          'A database tool',
          'A programming language'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'Docker is a platform for developing and running applications in containers.',
      ),
      Question(
        id: 'tech_014',
        text: 'What is DevOps?',
        options: [
          'Developer Operations combining dev and ops',
          'Device Operations',
          'Development Optimization',
          'Desktop Operations'
        ],
        correctIndex: 0,
        category: 'tech',
        explanation:
            'DevOps combines software development and IT operations for faster delivery.',
      ),
      Question(
        id: 'tech_015',
        text: 'What is NoSQL?',
        options: [
          'No database',
          'Non-relational database',
          'Not SQL language',
          'New SQL'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'NoSQL databases are non-relational, designed for specific data models.',
      ),
      Question(
        id: 'tech_016',
        text: 'What is REST API?',
        options: [
          'Relaxing API',
          'Representational State Transfer API',
          'Remote System Transfer',
          'Rapid Execution System'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'REST API is an architectural style for designing networked applications.',
      ),
      Question(
        id: 'tech_017',
        text: 'What is Kubernetes?',
        options: [
          'A Greek food',
          'Container orchestration platform',
          'A programming language',
          'A database'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'Kubernetes is a platform for automating deployment of containerized applications.',
      ),
      Question(
        id: 'tech_018',
        text: 'What is agile development?',
        options: [
          'Fast programming',
          'Iterative development methodology',
          'Flexible coding',
          'Quick deployment'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'Agile is an iterative approach to software development focusing on collaboration.',
      ),
      Question(
        id: 'tech_019',
        text: 'What is CI/CD?',
        options: [
          'Computer Integration',
          'Continuous Integration/Continuous Deployment',
          'Code Inspection',
          'Central Intelligence'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'CI/CD automates building, testing, and deploying code changes.',
      ),
      Question(
        id: 'tech_020',
        text: 'What is a microservice?',
        options: [
          'A small service',
          'Architectural approach with small independent services',
          'Micro computing',
          'Mini software'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'Microservices architecture structures applications as independent services.',
      ),
      Question(
        id: 'tech_021',
        text: 'What is JSON?',
        options: [
          'JavaScript Object Notation',
          'Java Standard Object Network',
          'Just Simple Object Naming',
          'Joint System Object Node'
        ],
        correctIndex: 0,
        category: 'tech',
        explanation:
            'JSON is a lightweight data interchange format using JavaScript syntax.',
      ),
      Question(
        id: 'tech_022',
        text: 'What is machine code?',
        options: [
          'Code for machines',
          'Binary code executed by CPU',
          'Manufacturing code',
          'Mechanical instructions'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'Machine code is binary instructions directly executed by a computer CPU.',
      ),
      Question(
        id: 'tech_023',
        text: 'What is open source software?',
        options: [
          'Free software',
          'Software with publicly accessible source code',
          'Opened applications',
          'Operating system'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'Open source software has source code that anyone can inspect and modify.',
      ),
      Question(
        id: 'tech_024',
        text: 'What is a cache?',
        options: [
          'Money storage',
          'Temporary data storage',
          'Security feature',
          'Backup system'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'Cache is temporary storage for frequently accessed data to improve performance.',
      ),
      Question(
        id: 'tech_025',
        text: 'What is a compiler?',
        options: [
          'A collection tool',
          'Program converting source code to machine code',
          'A code editor',
          'A debugger'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'A compiler translates source code into machine code for execution.',
      ),
      Question(
        id: 'tech_026',
        text: 'What is debugging?',
        options: [
          'Removing insects',
          'Finding and fixing code errors',
          'Cleaning code',
          'Testing software'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'Debugging is the process of finding and fixing errors in code.',
      ),
      Question(
        id: 'tech_027',
        text: 'What is RAM?',
        options: [
          'Random Access Memory',
          'Read And Modify',
          'Rapid Application Memory',
          'Remote Access Module'
        ],
        correctIndex: 0,
        category: 'tech',
        explanation:
            'RAM is Random Access Memory used for temporary data storage while running.',
      ),
      Question(
        id: 'tech_028',
        text: 'What is SaaS?',
        options: [
          'Software as a Service',
          'System as a Service',
          'Server and Storage',
          'Security as a Standard'
        ],
        correctIndex: 0,
        category: 'tech',
        explanation:
            'SaaS delivers software applications over the internet on a subscription basis.',
      ),
      Question(
        id: 'tech_029',
        text: 'What is bandwidth?',
        options: [
          'Band width',
          'Data transfer capacity',
          'Network range',
          'Connection speed'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'Bandwidth is the maximum data transfer capacity of a network connection.',
      ),
      Question(
        id: 'tech_030',
        text: 'What is a VPN?',
        options: [
          'Very Private Network',
          'Virtual Private Network',
          'Verified Public Network',
          'Visual Protocol Network'
        ],
        correctIndex: 1,
        category: 'tech',
        explanation:
            'VPN creates a secure encrypted connection over a public network.',
      ),
    ],
    'healthtech': [
      Question(
        id: 'health_001',
        text: 'What does EHR stand for in healthcare?',
        options: [
          'Emergency Health Response',
          'Electronic Health Record',
          'Enhanced Health Recovery',
          'Emergency Hospital Registration'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'EHR stands for Electronic Health Record, digital patient information systems.',
      ),
      Question(
        id: 'health_002',
        text: 'What is telemedicine?',
        options: [
          'Television medicine',
          'Remote healthcare delivery',
          'Telephone consultations only',
          'Medical TV shows'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'Telemedicine is the remote delivery of healthcare services using technology.',
      ),
      Question(
        id: 'health_003',
        text: 'What does IoMT stand for?',
        options: [
          'Internet of Medical Things',
          'International Medical Technology',
          'Integrated Medical Tools',
          'Internet of Modern Technology'
        ],
        correctIndex: 0,
        category: 'healthtech',
        explanation:
            'IoMT stands for Internet of Medical Things, connected medical devices.',
      ),
      Question(
        id: 'health_004',
        text: 'What is HIPAA in healthcare?',
        options: [
          'Health Insurance Portability and Accountability Act',
          'Healthcare Information Privacy Act',
          'Hospital Insurance Protection Act',
          'Health Information Processing Act'
        ],
        correctIndex: 0,
        category: 'healthtech',
        explanation:
            'HIPAA is the Health Insurance Portability and Accountability Act, protecting patient data.',
      ),
      Question(
        id: 'health_005',
        text: 'What is AI used for in healthcare?',
        options: [
          'Only administrative tasks',
          'Diagnosis, treatment, and drug discovery',
          'Only scheduling appointments',
          'Only billing processes'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'AI in healthcare is used for diagnosis, treatment planning, drug discovery, and more.',
      ),
      Question(
        id: 'health_006',
        text: 'What is wearable health technology?',
        options: [
          'Fashionable medical devices',
          'Devices monitoring health metrics',
          'Hospital equipment',
          'Medical uniforms'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'Wearable health tech includes devices like smartwatches monitoring vital signs.',
      ),
      Question(
        id: 'health_007',
        text: 'What is precision medicine?',
        options: [
          'Exact measurements',
          'Personalized treatment based on genetics',
          'Surgical precision',
          'Accurate diagnosis'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'Precision medicine tailors treatment to individual genetic profiles.',
      ),
      Question(
        id: 'health_008',
        text: 'What is remote patient monitoring?',
        options: [
          'Watching patients from afar',
          'Using tech to track patient health remotely',
          'Telemedicine',
          'Long distance care'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'Remote patient monitoring uses technology to track health data outside clinical settings.',
      ),
      Question(
        id: 'health_009',
        text: 'What is genomic medicine?',
        options: [
          'Gene therapy',
          'Using genetic information for healthcare',
          'DNA testing',
          'Genetic counseling'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'Genomic medicine uses an individual\'s genetic information to guide healthcare.',
      ),
      Question(
        id: 'health_010',
        text: 'What is digital therapeutics?',
        options: [
          'Online therapy',
          'Software-based treatments for medical conditions',
          'Digital medicine delivery',
          'Virtual reality therapy'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'Digital therapeutics use software to prevent, manage, or treat medical conditions.',
      ),
      Question(
        id: 'health_011',
        text: 'What is clinical decision support?',
        options: [
          'Doctor assistance',
          'Technology helping healthcare decisions',
          'Medical advice',
          'Patient support'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'Clinical decision support systems help healthcare providers make informed decisions.',
      ),
      Question(
        id: 'health_012',
        text: 'What is health informatics?',
        options: [
          'Medical information',
          'Managing health data with IT',
          'Health education',
          'Medical research'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'Health informatics combines healthcare, information technology, and data management.',
      ),
      Question(
        id: 'health_013',
        text: 'What is a patient portal?',
        options: [
          'Hospital entrance',
          'Online platform for patient health records',
          'Medical gateway',
          'Treatment center'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'Patient portals provide online access to personal health information and services.',
      ),
      Question(
        id: 'health_014',
        text: 'What is robotic surgery?',
        options: [
          'Robots replacing surgeons',
          'Computer-assisted surgical systems',
          'Automated operations',
          'AI surgery'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'Robotic surgery uses computer-controlled systems to assist surgeons.',
      ),
      Question(
        id: 'health_015',
        text: 'What is 3D bioprinting?',
        options: [
          'Printing medical images',
          'Creating biological tissues with 3D printers',
          'Medical documentation',
          'DNA printing'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            '3D bioprinting uses 3D printing technology to create biological tissues and organs.',
      ),
      Question(
        id: 'health_016',
        text: 'What is m-health?',
        options: [
          'Mental health',
          'Mobile health technology',
          'Medical health',
          'Modern health'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'M-health refers to medical and public health practice supported by mobile devices.',
      ),
      Question(
        id: 'health_017',
        text: 'What is blockchain used for in healthcare?',
        options: [
          'Building blocks',
          'Securing patient data and medical records',
          'Hospital construction',
          'Drug manufacturing'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'Blockchain secures patient data, tracks medical records, and manages drug supply chains.',
      ),
      Question(
        id: 'health_018',
        text: 'What is virtual care?',
        options: [
          'Virtual reality games',
          'Remote healthcare services',
          'Imaginary treatment',
          'Computer simulations'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'Virtual care delivers healthcare services remotely through digital platforms.',
      ),
      Question(
        id: 'health_019',
        text: 'What is predictive analytics in healthcare?',
        options: [
          'Weather prediction',
          'Using data to forecast health outcomes',
          'Future planning',
          'Diagnosis prediction'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'Predictive analytics uses data to forecast patient outcomes and health trends.',
      ),
      Question(
        id: 'health_020',
        text: 'What is care coordination technology?',
        options: [
          'Appointment scheduling',
          'Tools managing patient care across providers',
          'Hospital coordination',
          'Medical teamwork'
        ],
        correctIndex: 1,
        category: 'healthtech',
        explanation:
            'Care coordination technology helps manage patient care across multiple providers.',
      ),
    ],
    'ai': [
      Question(
        id: 'ai_001',
        text: 'What does ML stand for in AI?',
        options: [
          'Machine Learning',
          'Manual Logic',
          'Multiple Languages',
          'Modern Logic'
        ],
        correctIndex: 0,
        category: 'ai',
        explanation:
            'ML stands for Machine Learning, a subset of artificial intelligence.',
      ),
      Question(
        id: 'ai_002',
        text: 'What is a neural network?',
        options: [
          'A computer network',
          'AI model inspired by the brain',
          'A social network',
          'A data network'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'A neural network is an AI model inspired by biological neural networks in the brain.',
      ),
      Question(
        id: 'ai_003',
        text: 'What does NLP stand for?',
        options: [
          'Natural Language Processing',
          'Network Learning Protocol',
          'Neural Learning Process',
          'New Logic Programming'
        ],
        correctIndex: 0,
        category: 'ai',
        explanation:
            'NLP stands for Natural Language Processing, enabling computers to understand human language.',
      ),
      Question(
        id: 'ai_004',
        text: 'What is deep learning?',
        options: [
          'Advanced study methods',
          'ML with multiple neural network layers',
          'Ocean exploration AI',
          'Psychological learning'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'Deep learning uses neural networks with multiple layers to learn complex patterns.',
      ),
      Question(
        id: 'ai_005',
        text: 'What is computer vision?',
        options: [
          'Computer screens',
          'AI that interprets visual information',
          'Eye care for computer users',
          'Computer display technology'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'Computer vision is AI technology that interprets and analyzes visual information.',
      ),
      Question(
        id: 'ai_006',
        text: 'What is supervised learning?',
        options: [
          'Learning with supervision',
          'Training AI with labeled data',
          'Monitoring learning',
          'Controlled education'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'Supervised learning trains AI models using labeled input-output pairs.',
      ),
      Question(
        id: 'ai_007',
        text: 'What is unsupervised learning?',
        options: [
          'Learning without teachers',
          'AI finding patterns in unlabeled data',
          'Independent study',
          'Unmonitored training'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'Unsupervised learning finds patterns in data without labeled examples.',
      ),
      Question(
        id: 'ai_008',
        text: 'What is reinforcement learning?',
        options: [
          'Strengthening knowledge',
          'Learning through rewards and penalties',
          'Repeated practice',
          'Building confidence'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'Reinforcement learning trains AI through trial and error with rewards.',
      ),
      Question(
        id: 'ai_009',
        text: 'What is a chatbot?',
        options: [
          'A talking robot',
          'AI program simulating conversation',
          'Chat application',
          'Social media bot'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'Chatbots are AI programs designed to simulate human conversation.',
      ),
      Question(
        id: 'ai_010',
        text: 'What is sentiment analysis?',
        options: [
          'Analyzing feelings',
          'AI determining emotional tone of text',
          'Mood tracking',
          'Opinion polling'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'Sentiment analysis uses AI to determine emotional tone in text data.',
      ),
      Question(
        id: 'ai_011',
        text: 'What is generative AI?',
        options: [
          'General AI',
          'AI creating new content',
          'AI generation',
          'Generic algorithms'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'Generative AI creates new content like text, images, or music.',
      ),
      Question(
        id: 'ai_012',
        text: 'What is transfer learning?',
        options: [
          'Transferring data',
          'Using knowledge from one task for another',
          'Moving files',
          'Knowledge sharing'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'Transfer learning applies knowledge from one AI task to a different but related task.',
      ),
      Question(
        id: 'ai_013',
        text: 'What is a recommendation system?',
        options: [
          'Advice platform',
          'AI suggesting personalized content',
          'Review system',
          'Rating algorithm'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'Recommendation systems use AI to suggest personalized content to users.',
      ),
      Question(
        id: 'ai_014',
        text: 'What is AI bias?',
        options: [
          'AI opinions',
          'Unfair preferences in AI decisions',
          'AI mistakes',
          'System errors'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'AI bias occurs when algorithms show systematic unfair preferences.',
      ),
      Question(
        id: 'ai_015',
        text: 'What is edge AI?',
        options: [
          'Cutting-edge AI',
          'AI running on local devices',
          'Advanced AI',
          'AI at boundaries'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'Edge AI runs AI algorithms locally on devices instead of in the cloud.',
      ),
      Question(
        id: 'ai_016',
        text: 'What is GPT?',
        options: [
          'General Purpose Technology',
          'Generative Pre-trained Transformer',
          'Global Processing Tool',
          'Graphics Processing Tech'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'GPT is a Generative Pre-trained Transformer, a type of language AI model.',
      ),
      Question(
        id: 'ai_017',
        text: 'What is the Turing Test?',
        options: [
          'Computer test',
          'Test of machine intelligence',
          'Programming exam',
          'AI certification'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'The Turing Test evaluates a machine\'s ability to exhibit human-like intelligence.',
      ),
      Question(
        id: 'ai_018',
        text: 'What is overfitting in ML?',
        options: [
          'Too much data',
          'Model memorizing training data too well',
          'Excessive training',
          'Data overflow'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'Overfitting occurs when a model learns training data too well, hurting generalization.',
      ),
      Question(
        id: 'ai_019',
        text: 'What is feature engineering?',
        options: [
          'Building features',
          'Creating useful input variables for ML',
          'Software features',
          'Design process'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'Feature engineering creates useful input variables to improve ML model performance.',
      ),
      Question(
        id: 'ai_020',
        text: 'What is AGI?',
        options: [
          'Advanced General Intelligence',
          'Artificial General Intelligence',
          'Automated Group Intelligence',
          'Adaptive Game Intelligence'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'AGI (Artificial General Intelligence) refers to AI with human-level intelligence.',
      ),
      Question(
        id: 'ai_021',
        text: 'What is a training dataset?',
        options: [
          'Exercise data',
          'Data used to train AI models',
          'Workout information',
          'Training schedule'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'A training dataset is data used to teach AI models to make predictions.',
      ),
      Question(
        id: 'ai_022',
        text: 'What is model accuracy?',
        options: [
          'Precise models',
          'Percentage of correct predictions',
          'Model precision',
          'Exactness measure'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'Model accuracy measures the percentage of correct predictions made by an AI model.',
      ),
      Question(
        id: 'ai_023',
        text: 'What is neural architecture?',
        options: [
          'Brain structure',
          'Design of neural network layers',
          'Nervous system',
          'Network design'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'Neural architecture refers to the design and structure of neural network layers.',
      ),
      Question(
        id: 'ai_024',
        text: 'What is data augmentation?',
        options: [
          'Adding more data',
          'Creating variations of training data',
          'Data expansion',
          'Increasing size'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'Data augmentation creates modified versions of data to expand training datasets.',
      ),
      Question(
        id: 'ai_025',
        text: 'What is a loss function?',
        options: [
          'Function that loses data',
          'Measures model prediction error',
          'Lost calculations',
          'Error function'
        ],
        correctIndex: 1,
        category: 'ai',
        explanation:
            'A loss function measures how far model predictions are from actual values.',
      ),
    ],
    'cybersecurity': [
      Question(
        id: 'cyber_001',
        text: 'What is phishing?',
        options: [
          'Catching fish online',
          'Fraudulent attempt to obtain sensitive info',
          'A fishing game',
          'Network fishing protocol'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'Phishing is a fraudulent attempt to obtain sensitive information by disguising as trustworthy.',
      ),
      Question(
        id: 'cyber_002',
        text: 'What does VPN stand for?',
        options: [
          'Virtual Private Network',
          'Very Private Network',
          'Verified Public Network',
          'Virtual Public Network'
        ],
        correctIndex: 0,
        category: 'cybersecurity',
        explanation:
            'VPN stands for Virtual Private Network, creating secure connections over the internet.',
      ),
      Question(
        id: 'cyber_003',
        text: 'What is malware?',
        options: [
          'Bad software',
          'Malicious software',
          'Male software',
          'Manual software'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'Malware is malicious software designed to damage or gain unauthorized access to systems.',
      ),
      Question(
        id: 'cyber_004',
        text: 'What is two-factor authentication?',
        options: [
          'Two passwords',
          'Additional security layer with second verification',
          'Two user accounts',
          'Double encryption'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'Two-factor authentication adds an extra security layer with a second form of verification.',
      ),
      Question(
        id: 'cyber_005',
        text: 'What is encryption?',
        options: [
          'Hiding files',
          'Converting data into coded format',
          'Compressing data',
          'Backing up data'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'Encryption converts data into a coded format to prevent unauthorized access.',
      ),
      Question(
        id: 'cyber_006',
        text: 'What is ransomware?',
        options: [
          'Random software',
          'Malware demanding payment to unlock data',
          'Free software',
          'Security software'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'Ransomware encrypts data and demands payment for decryption.',
      ),
      Question(
        id: 'cyber_007',
        text: 'What is a firewall?',
        options: [
          'Fire prevention',
          'Network security system',
          'Wall protection',
          'Heat barrier'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'A firewall monitors and controls incoming and outgoing network traffic.',
      ),
      Question(
        id: 'cyber_008',
        text: 'What is social engineering?',
        options: [
          'Social media management',
          'Manipulating people to divulge information',
          'Network engineering',
          'Community building'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'Social engineering manipulates people into revealing confidential information.',
      ),
      Question(
        id: 'cyber_009',
        text: 'What is a DDoS attack?',
        options: [
          'Data Delivery Service',
          'Distributed Denial of Service attack',
          'Digital Data System',
          'Direct Database Operation'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'DDoS attacks overwhelm systems with traffic to make them unavailable.',
      ),
      Question(
        id: 'cyber_010',
        text: 'What is zero-day vulnerability?',
        options: [
          'No security risk',
          'Unknown security flaw',
          'Day zero backup',
          'Initial security'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'A zero-day vulnerability is an unknown security flaw that can be exploited.',
      ),
      Question(
        id: 'cyber_011',
        text: 'What is penetration testing?',
        options: [
          'Testing durability',
          'Simulated cyber attacks to find vulnerabilities',
          'Password testing',
          'Network speed test'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'Penetration testing simulates attacks to identify security weaknesses.',
      ),
      Question(
        id: 'cyber_012',
        text: 'What is end-to-end encryption?',
        options: [
          'Complete encryption',
          'Encryption from sender to receiver',
          'Final encryption',
          'Total security'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'End-to-end encryption protects data from sender to receiver with no intermediate access.',
      ),
      Question(
        id: 'cyber_013',
        text: 'What is a security patch?',
        options: [
          'Security badge',
          'Software update fixing vulnerabilities',
          'Protective cover',
          'Security team'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'A security patch is a software update that fixes security vulnerabilities.',
      ),
      Question(
        id: 'cyber_014',
        text: 'What is SSL/TLS?',
        options: [
          'Security protocols for encrypted communication',
          'Programming languages',
          'Database systems',
          'Network cables'
        ],
        correctIndex: 0,
        category: 'cybersecurity',
        explanation:
            'SSL/TLS are cryptographic protocols for secure communication over networks.',
      ),
      Question(
        id: 'cyber_015',
        text: 'What is a keylogger?',
        options: [
          'Key storage',
          'Software recording keystrokes',
          'Lock mechanism',
          'Password manager'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'A keylogger records keystrokes to capture sensitive information like passwords.',
      ),
      Question(
        id: 'cyber_016',
        text: 'What is multi-factor authentication?',
        options: [
          'Multiple passwords',
          'Multiple verification methods for access',
          'Several accounts',
          'Many users'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'Multi-factor authentication requires multiple verification methods for access.',
      ),
      Question(
        id: 'cyber_017',
        text: 'What is a security audit?',
        options: [
          'Financial check',
          'Systematic evaluation of security measures',
          'Account review',
          'Performance review'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'A security audit evaluates the effectiveness of security controls and policies.',
      ),
      Question(
        id: 'cyber_018',
        text: 'What is spyware?',
        options: [
          'Spy equipment',
          'Software secretly monitoring user activity',
          'Security software',
          'Spy movies'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'Spyware secretly collects information about user activities.',
      ),
      Question(
        id: 'cyber_019',
        text: 'What is a backdoor?',
        options: [
          'Rear entrance',
          'Hidden access bypassing security',
          'Exit strategy',
          'Alternative route'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'A backdoor is a hidden method of bypassing normal authentication.',
      ),
      Question(
        id: 'cyber_020',
        text: 'What is threat intelligence?',
        options: [
          'Smart threats',
          'Information about cyber threats',
          'Dangerous AI',
          'Threat detection'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'Threat intelligence is analyzed information about current and potential cyber threats.',
      ),
      Question(
        id: 'cyber_021',
        text: 'What is identity theft?',
        options: [
          'Stealing IDs',
          'Fraudulently using someone\'s personal information',
          'Copying identities',
          'Fake identification'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'Identity theft is the fraudulent acquisition and use of someone\'s personal information.',
      ),
      Question(
        id: 'cyber_022',
        text: 'What is a security token?',
        options: [
          'Security coin',
          'Device generating authentication codes',
          'Password holder',
          'Security badge'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'A security token generates one-time codes for authentication.',
      ),
      Question(
        id: 'cyber_023',
        text: 'What is whitelisting?',
        options: [
          'White list paper',
          'Allowing only approved entities',
          'Blacklisting opposite',
          'Bright listing'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'Whitelisting allows only pre-approved applications or users to access systems.',
      ),
      Question(
        id: 'cyber_024',
        text: 'What is network segmentation?',
        options: [
          'Cutting networks',
          'Dividing network into secure zones',
          'Network sections',
          'Isolating networks'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'Network segmentation divides networks into separate zones to improve security.',
      ),
      Question(
        id: 'cyber_025',
        text: 'What is incident response?',
        options: [
          'Emergency reaction',
          'Process of handling security breaches',
          'Quick response',
          'Crisis management'
        ],
        correctIndex: 1,
        category: 'cybersecurity',
        explanation:
            'Incident response is the organized approach to addressing security breaches.',
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
  static List<Question> getRandomQuestions(String categoryId,
      {int count = questionsPerQuiz}) {
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
