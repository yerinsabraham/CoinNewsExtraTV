import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/spotlight_model.dart';

class SpotlightService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'spotlight_items';

  // Sample data for UI preview - will be replaced by real Firestore data
  static List<SpotlightItem> _getSampleData() {
    return [
      // AIRDROP CATEGORY
      SpotlightItem(
        id: 'sample-airdrop-1',
        title: 'MetaDrop Airdrop',
        category: SpotlightCategory.airdrops,
        shortDescription: 'Join MetaDrop\'s limited token giveaway and earn rewards for early participation.',
        description: 'MetaDrop is a decentralized reward platform hosting token campaigns for early adopters. Participate now to earn tokens and level up your wallet status. Our platform connects users with the best airdrop opportunities in the crypto space, ensuring you never miss out on valuable token distributions.',
        imageUrl: 'assets/spotlight/1.png',
        bannerUrl: 'assets/spotlight/1.png',
        galleryImages: [
          'assets/spotlight/1.png',
          'assets/spotlight/1.png'
        ],
        ctaText: 'Join Airdrop',
        ctaLink: 'https://metadrop.io/airdrop',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: true,
        priority: 10,
        createdBy: 'admin',
      ),
      SpotlightItem(
        id: 'sample-airdrop-2',
        title: 'BlockMint Rewards',
        category: SpotlightCategory.airdrops,
        shortDescription: 'Complete simple blockchain tasks and claim up to 200 BMT tokens.',
        description: 'BlockMint offers an innovative rewards system where users can earn BMT tokens by completing simple blockchain-related tasks. Whether you\'re new to crypto or an experienced user, our platform provides easy ways to earn digital assets.',
        imageUrl: 'assets/spotlight/2.png',
        bannerUrl: 'assets/spotlight/2.png',
        galleryImages: ['assets/spotlight/2.png'],
        ctaText: 'Claim Tokens',
        ctaLink: 'https://blockmint.io/rewards',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: false,
        priority: 8,
        createdBy: 'admin',
      ),
      SpotlightItem(
        id: 'sample-airdrop-3',
        title: 'AeroChain Free Mint',
        category: SpotlightCategory.airdrops,
        shortDescription: 'Claim your free NFT mint from AeroChain before it ends.',
        description: 'AeroChain is launching an exclusive free NFT mint for early community members. This limited-time opportunity allows you to mint unique digital collectibles that will serve as membership tokens for the AeroChain ecosystem.',
        imageUrl: 'assets/spotlight/3.png',
        bannerUrl: 'assets/spotlight/3.png',
        galleryImages: ['assets/spotlight/3.png'],
        ctaText: 'Mint Now',
        ctaLink: 'https://aerochain.io/mint',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: false,
        priority: 6,
        createdBy: 'admin',
      ),

      // CRYPTO CATEGORY
      SpotlightItem(
        id: 'sample-crypto-1',
        title: 'NexPay Wallet',
        category: SpotlightCategory.crypto,
        shortDescription: 'The easiest way to manage your crypto assets securely.',
        description: 'NexPay Wallet revolutionizes cryptocurrency management with its user-friendly interface and enterprise-grade security. Store, send, and receive over 100 different cryptocurrencies with confidence. Our wallet features multi-layer security protocols and biometric authentication.',
        imageUrl: 'assets/spotlight/4.png',
        bannerUrl: 'assets/spotlight/4.png',
        galleryImages: [
          'assets/spotlight/4.png',
          'assets/spotlight/4.png'
        ],
        ctaText: 'Download Wallet',
        ctaLink: 'https://nexpay.io',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: true,
        priority: 9,
        createdBy: 'admin',
      ),
      SpotlightItem(
        id: 'sample-crypto-2',
        title: 'ChainBridge Exchange',
        category: SpotlightCategory.crypto,
        shortDescription: 'Trade and earn rewards with zero gas fees on ChainBridge.',
        description: 'ChainBridge Exchange offers a revolutionary trading experience with zero gas fees and lightning-fast transactions. Our advanced matching engine ensures optimal trade execution while our liquidity pools provide the best prices in the market.',
        imageUrl: 'assets/spotlight/5.png',
        bannerUrl: 'assets/spotlight/5.png',
        galleryImages: ['assets/spotlight/5.png'],
        ctaText: 'Trade Now',
        ctaLink: 'https://chainbridge.io',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: false,
        priority: 7,
        createdBy: 'admin',
      ),
      SpotlightItem(
        id: 'sample-crypto-3',
        title: 'TokenVault',
        category: SpotlightCategory.crypto,
        shortDescription: 'Store, stake, and grow your digital assets on TokenVault.',
        description: 'TokenVault is your comprehensive platform for digital asset management and growth. Our secure vaulting system protects your cryptocurrencies while our staking protocols help you earn passive income with automated portfolio rebalancing.',
        imageUrl: 'assets/spotlight/6.png',
        bannerUrl: 'assets/spotlight/6.png',
        galleryImages: ['assets/spotlight/6.png'],
        ctaText: 'Explore Platform',
        ctaLink: 'https://tokenvault.io',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: false,
        priority: 5,
        createdBy: 'admin',
      ),

      // AI CATEGORY
      SpotlightItem(
        id: 'sample-ai-1',
        title: 'VisionAI Studio',
        category: SpotlightCategory.ai,
        shortDescription: 'Build and deploy smart AI image models in minutes.',
        description: 'VisionAI Studio empowers developers and businesses to create sophisticated computer vision applications without extensive ML expertise. Our drag-and-drop interface, pre-trained models, and automated deployment pipeline make AI development accessible to everyone.',
        imageUrl: 'assets/spotlight/7.png',
        bannerUrl: 'assets/spotlight/7.png',
        galleryImages: [
          'assets/spotlight/7.png',
          'assets/spotlight/7.png'
        ],
        ctaText: 'Try Now',
        ctaLink: 'https://visionai.io',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: true,
        priority: 8,
        createdBy: 'admin',
      ),
      SpotlightItem(
        id: 'sample-ai-2',
        title: 'ChatNova',
        category: SpotlightCategory.ai,
        shortDescription: 'Your personal AI assistant for content, tasks, and automation.',
        description: 'ChatNova is an advanced AI assistant designed to streamline your workflow and boost productivity. From content creation and email drafting to task management and process automation, ChatNova handles it all with natural language understanding.',
        imageUrl: 'assets/spotlight/8.png',
        bannerUrl: 'assets/spotlight/8.png',
        galleryImages: ['assets/spotlight/8.png'],
        ctaText: 'Start Chat',
        ctaLink: 'https://chatnova.ai',
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: false,
        priority: 6,
        createdBy: 'admin',
      ),
      SpotlightItem(
        id: 'sample-ai-3',
        title: 'SynthMind Analytics',
        category: SpotlightCategory.ai,
        shortDescription: 'AI-powered insights for business decisions and forecasting.',
        description: 'SynthMind Analytics transforms raw business data into actionable insights using advanced machine learning algorithms. Our platform provides real-time analytics, predictive forecasting, and automated reporting to help businesses make data-driven decisions.',
        imageUrl: 'assets/spotlight/9.png',
        bannerUrl: 'assets/spotlight/9.png',
        galleryImages: ['assets/spotlight/9.png'],
        ctaText: 'Visit Website',
        ctaLink: 'https://synthmind.ai',
        createdAt: DateTime.now().subtract(const Duration(hours: 14)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: false,
        priority: 4,
        createdBy: 'admin',
      ),

      // FINTECH CATEGORY
      SpotlightItem(
        id: 'sample-fintech-1',
        title: 'Paylium',
        category: SpotlightCategory.fintech,
        shortDescription: 'A seamless mobile payment app for instant local and cross-border transactions.',
        description: 'Paylium revolutionizes digital payments with instant, secure, and cost-effective transactions across borders. Our mobile app supports multiple currencies, offers competitive exchange rates, and ensures bank-level security for all transfers.',
        imageUrl: 'assets/spotlight/10.png',
        bannerUrl: 'assets/spotlight/10.png',
        galleryImages: [
          'assets/spotlight/10.png',
          'assets/spotlight/10.png'
        ],
        ctaText: 'Get App',
        ctaLink: 'https://paylium.com',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: true,
        priority: 7,
        createdBy: 'admin',
      ),
      SpotlightItem(
        id: 'sample-fintech-2',
        title: 'Credify',
        category: SpotlightCategory.fintech,
        shortDescription: 'AI-based lending and credit scoring platform for small businesses.',
        description: 'Credify leverages artificial intelligence to provide fair and accurate credit assessments for small businesses. Our platform analyzes multiple data points beyond traditional credit scores to determine creditworthiness, enabling more businesses to access funding.',
        imageUrl: 'assets/spotlight/11.png',
        bannerUrl: 'assets/spotlight/11.png',
        galleryImages: ['assets/spotlight/11.png'],
        ctaText: 'Apply Now',
        ctaLink: 'https://credify.io',
        createdAt: DateTime.now().subtract(const Duration(hours: 18)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: false,
        priority: 5,
        createdBy: 'admin',
      ),
      SpotlightItem(
        id: 'sample-fintech-3',
        title: 'FinSmart',
        category: SpotlightCategory.fintech,
        shortDescription: 'Smart budgeting and savings tracker for modern users.',
        description: 'FinSmart is an intelligent personal finance app that helps you take control of your money with AI-powered budgeting and savings recommendations. Track expenses automatically, set financial goals, and receive personalized insights to improve your financial health.',
        imageUrl: 'assets/spotlight/12.png',
        bannerUrl: 'assets/spotlight/12.png',
        galleryImages: ['assets/spotlight/12.png'],
        ctaText: 'Start Saving',
        ctaLink: 'https://finsmart.io',
        createdAt: DateTime.now().subtract(const Duration(hours: 20)),
        updatedAt: DateTime.now(),
        isActive: true,
        isFeatured: false,
        priority: 3,
        createdBy: 'admin',
      ),
    ];
  }

  // Get all active spotlight items
  static Stream<List<SpotlightItem>> getActiveSpotlightItems() {
    return _firestore
        .collection(_collectionName)
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // If no real data exists, return all sample data
      if (snapshot.docs.isEmpty) {
        return _getSampleData()
          ..sort((a, b) => b.priority.compareTo(a.priority));
      }
      
      // Return real Firestore data if it exists
      return snapshot.docs
          .map((doc) => SpotlightItem.fromFirestore(doc))
          .toList();
    });
  }

  // Get spotlight items by category
  static Stream<List<SpotlightItem>> getSpotlightItemsByCategory(SpotlightCategory category) {
    return _firestore
        .collection(_collectionName)
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category.name)
        .orderBy('priority', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // If no real data exists, return sample data for this category
      if (snapshot.docs.isEmpty) {
        return _getSampleData()
            .where((item) => item.category == category)
            .toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));
      }
      
      // Return real Firestore data if it exists
      return snapshot.docs
          .map((doc) => SpotlightItem.fromFirestore(doc))
          .toList();
    });
  }

  // Get featured spotlight items
  static Stream<List<SpotlightItem>> getFeaturedSpotlightItems() {
    return _firestore
        .collection(_collectionName)
        .where('isActive', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .orderBy('priority', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
      // If no real data exists, return sample featured items
      if (snapshot.docs.isEmpty) {
        return _getSampleData()
            .where((item) => item.isFeatured)
            .take(5)
            .toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));
      }
      
      // Return real Firestore data if it exists
      return snapshot.docs
          .map((doc) => SpotlightItem.fromFirestore(doc))
          .toList();
    });
  }

  // Get single spotlight item by ID
  static Future<SpotlightItem?> getSpotlightItem(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        return SpotlightItem.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting spotlight item: $e');
      return null;
    }
  }

  // Create new spotlight item (Admin only)
  static Future<String?> createSpotlightItem(SpotlightItem item) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final newItem = item.copyWith(
        createdBy: user.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(_collectionName)
          .add(newItem.toFirestore());

      return docRef.id;
    } catch (e) {
      print('Error creating spotlight item: $e');
      return null;
    }
  }

  // Update spotlight item (Admin only)
  static Future<bool> updateSpotlightItem(String id, SpotlightItem item) async {
    try {
      final updatedItem = item.copyWith(
        id: id,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update(updatedItem.toFirestore());

      return true;
    } catch (e) {
      print('Error updating spotlight item: $e');
      return false;
    }
  }

  // Delete spotlight item (Admin only)
  static Future<bool> deleteSpotlightItem(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting spotlight item: $e');
      return false;
    }
  }

  // Toggle active status
  static Future<bool> toggleSpotlightItemStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error toggling spotlight item status: $e');
      return false;
    }
  }

  // Toggle featured status
  static Future<bool> toggleFeaturedStatus(String id, bool isFeatured) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        'isFeatured': isFeatured,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error toggling featured status: $e');
      return false;
    }
  }

  // Update priority
  static Future<bool> updatePriority(String id, int priority) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        'priority': priority,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating priority: $e');
      return false;
    }
  }

  // Get all spotlight items for admin (including inactive)
  static Stream<List<SpotlightItem>> getAllSpotlightItemsForAdmin() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SpotlightItem.fromFirestore(doc))
            .toList());
  }

  // Get count by category
  static Future<Map<SpotlightCategory, int>> getCategoryCounts() async {
    try {
      final Map<SpotlightCategory, int> counts = {};
      
      for (final category in SpotlightCategory.values) {
        final snapshot = await _firestore
            .collection(_collectionName)
            .where('isActive', isEqualTo: true)
            .where('category', isEqualTo: category.name)
            .get();
        
        counts[category] = snapshot.size;
      }
      
      return counts;
    } catch (e) {
      print('Error getting category counts: $e');
      return {};
    }
  }

  // Search spotlight items
  static Stream<List<SpotlightItem>> searchSpotlightItems(String query) {
    // Note: This is a basic search. For production, consider using Algolia or similar
    return _firestore
        .collection(_collectionName)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      List<SpotlightItem> items;
      
      // If no real data exists, search sample data
      if (snapshot.docs.isEmpty) {
        items = _getSampleData();
      } else {
        // Use real Firestore data if it exists
        items = snapshot.docs
            .map((doc) => SpotlightItem.fromFirestore(doc))
            .toList();
      }
      
      // Filter by search query
      return items
          .where((item) =>
              item.title.toLowerCase().contains(query.toLowerCase()) ||
              item.description.toLowerCase().contains(query.toLowerCase()) ||
              item.shortDescription.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }
}