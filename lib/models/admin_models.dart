import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUser {
  final String id;
  final String email;
  final String role;
  final bool isActive;
  final String addedBy;
  final DateTime addedAt;
  final DateTime? lastLoginAt;

  AdminUser({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    required this.addedBy,
    required this.addedAt,
    this.lastLoginAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'role': role,
      'isActive': isActive,
      'addedBy': addedBy,
      'addedAt': Timestamp.fromDate(addedAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'admin',
      isActive: json['isActive'] ?? true,
      addedBy: json['addedBy'] ?? '',
      addedAt: (json['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (json['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  AdminUser copyWith({
    String? id,
    String? email,
    String? role,
    bool? isActive,
    String? addedBy,
    DateTime? addedAt,
    DateTime? lastLoginAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

class AdminContent {
  final String id;
  final String type; // banner, ad, event, news, etc.
  final String title;
  final String description;
  final String? imageUrl;
  final String? linkUrl;
  final Map<String, dynamic> data; // Additional data specific to content type
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final DateTime? publishAt; // For scheduling content
  final DateTime? expireAt; // For expiring content

  AdminContent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.imageUrl,
    this.linkUrl,
    required this.data,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.publishAt,
    this.expireAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'data': data,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
      'publishAt': publishAt != null ? Timestamp.fromDate(publishAt!) : null,
      'expireAt': expireAt != null ? Timestamp.fromDate(expireAt!) : null,
    };
  }

  factory AdminContent.fromJson(Map<String, dynamic> json) {
    return AdminContent(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      linkUrl: json['linkUrl'],
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      isActive: json['isActive'] ?? true,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: json['createdBy'] ?? '',
      publishAt: (json['publishAt'] as Timestamp?)?.toDate(),
      expireAt: (json['expireAt'] as Timestamp?)?.toDate(),
    );
  }

  AdminContent copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    String? imageUrl,
    String? linkUrl,
    Map<String, dynamic>? data,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    DateTime? publishAt,
    DateTime? expireAt,
  }) {
    return AdminContent(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      data: data ?? this.data,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      publishAt: publishAt ?? this.publishAt,
      expireAt: expireAt ?? this.expireAt,
    );
  }

  // Helper methods for specific content types
  bool get isScheduled => publishAt != null && publishAt!.isAfter(DateTime.now());
  bool get isExpired => expireAt != null && expireAt!.isBefore(DateTime.now());
  bool get isCurrentlyVisible => isActive && !isScheduled && !isExpired;
}

// Specific content type models for type safety
class BannerContent extends AdminContent {
  BannerContent({
    required String id,
    required String title,
    required String description,
    String? imageUrl,
    String? linkUrl,
    required bool isActive,
    required DateTime createdAt,
    DateTime? updatedAt,
    required String createdBy,
    DateTime? publishAt,
    DateTime? expireAt,
    int priority = 0,
    String? ctaText,
  }) : super(
          id: id,
          type: 'banner',
          title: title,
          description: description,
          imageUrl: imageUrl,
          linkUrl: linkUrl,
          data: {
            'priority': priority,
            'ctaText': ctaText,
          },
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
          createdBy: createdBy,
          publishAt: publishAt,
          expireAt: expireAt,
        );

  int get priority => data['priority'] ?? 0;
  String? get ctaText => data['ctaText'];
}

class AdContent extends AdminContent {
  AdContent({
    required String id,
    required String title,
    required String description,
    String? imageUrl,
    String? linkUrl,
    required bool isActive,
    required DateTime createdAt,
    DateTime? updatedAt,
    required String createdBy,
    DateTime? publishAt,
    DateTime? expireAt,
    String? advertiser,
    String? campaignId,
    int impressions = 0,
    int clicks = 0,
  }) : super(
          id: id,
          type: 'ad',
          title: title,
          description: description,
          imageUrl: imageUrl,
          linkUrl: linkUrl,
          data: {
            'advertiser': advertiser,
            'campaignId': campaignId,
            'impressions': impressions,
            'clicks': clicks,
          },
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
          createdBy: createdBy,
          publishAt: publishAt,
          expireAt: expireAt,
        );

  String? get advertiser => data['advertiser'];
  String? get campaignId => data['campaignId'];
  int get impressions => data['impressions'] ?? 0;
  int get clicks => data['clicks'] ?? 0;
}

class EventContent extends AdminContent {
  EventContent({
    required String id,
    required String title,
    required String description,
    String? imageUrl,
    String? linkUrl,
    required bool isActive,
    required DateTime createdAt,
    DateTime? updatedAt,
    required String createdBy,
    DateTime? publishAt,
    DateTime? expireAt,
    required DateTime eventDate,
    String? location,
    String? organizer,
    bool isPaid = false,
    double? price,
    String? currency,
  }) : super(
          id: id,
          type: 'event',
          title: title,
          description: description,
          imageUrl: imageUrl,
          linkUrl: linkUrl,
          data: {
            'eventDate': eventDate.millisecondsSinceEpoch,
            'location': location,
            'organizer': organizer,
            'isPaid': isPaid,
            'price': price,
            'currency': currency,
          },
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
          createdBy: createdBy,
          publishAt: publishAt,
          expireAt: expireAt,
        );

  DateTime get eventDate => DateTime.fromMillisecondsSinceEpoch(data['eventDate']);
  String? get location => data['location'];
  String? get organizer => data['organizer'];
  bool get isPaid => data['isPaid'] ?? false;
  double? get price => data['price'];
  String? get currency => data['currency'];
}
