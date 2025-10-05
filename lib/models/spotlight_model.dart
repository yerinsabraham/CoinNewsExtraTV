import 'package:cloud_firestore/cloud_firestore.dart';

enum SpotlightCategory {
  airdrops('Airdrops'),
  crypto('Crypto / Blockchain'),
  ai('AI'),
  fintech('Fintech');

  const SpotlightCategory(this.displayName);
  final String displayName;

  static SpotlightCategory fromString(String category) {
    switch (category.toLowerCase()) {
      case 'airdrops':
      case 'airdrop':
        return SpotlightCategory.airdrops;
      case 'crypto':
      case 'crypto / blockchain':
      case 'blockchain':
        return SpotlightCategory.crypto;
      case 'ai':
        return SpotlightCategory.ai;
      case 'fintech':
        return SpotlightCategory.fintech;
      default:
        return SpotlightCategory.crypto;
    }
  }
}

class SpotlightItem {
  final String id;
  final String title;
  final SpotlightCategory category;
  final String description;
  final String shortDescription;
  final String imageUrl;
  final String? bannerUrl;
  final List<String> galleryImages;
  final String ctaText;
  final String ctaLink;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final bool isFeatured;
  final int priority;
  final String? createdBy;

  SpotlightItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.shortDescription,
    required this.imageUrl,
    this.bannerUrl,
    this.galleryImages = const [],
    required this.ctaText,
    required this.ctaLink,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.isFeatured = false,
    this.priority = 0,
    this.createdBy,
  });

  // Convert from Firestore document
  factory SpotlightItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SpotlightItem(
      id: doc.id,
      title: data['title'] ?? '',
      category: SpotlightCategory.fromString(data['category'] ?? 'crypto'),
      description: data['description'] ?? '',
      shortDescription: data['shortDescription'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      bannerUrl: data['bannerUrl'],
      galleryImages: List<String>.from(data['galleryImages'] ?? []),
      ctaText: data['ctaText'] ?? 'Learn More',
      ctaLink: data['ctaLink'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      priority: data['priority'] ?? 0,
      createdBy: data['createdBy'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'category': category.name,
      'description': description,
      'shortDescription': shortDescription,
      'imageUrl': imageUrl,
      'bannerUrl': bannerUrl,
      'galleryImages': galleryImages,
      'ctaText': ctaText,
      'ctaLink': ctaLink,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'priority': priority,
      'createdBy': createdBy,
    };
  }

  // Copy with method for updates
  SpotlightItem copyWith({
    String? id,
    String? title,
    SpotlightCategory? category,
    String? description,
    String? shortDescription,
    String? imageUrl,
    String? bannerUrl,
    List<String>? galleryImages,
    String? ctaText,
    String? ctaLink,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isFeatured,
    int? priority,
    String? createdBy,
  }) {
    return SpotlightItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      imageUrl: imageUrl ?? this.imageUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      ctaText: ctaText ?? this.ctaText,
      ctaLink: ctaLink ?? this.ctaLink,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      priority: priority ?? this.priority,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  String toString() {
    return 'SpotlightItem(id: $id, title: $title, category: ${category.displayName}, isActive: $isActive)';
  }
}