class Event {
  final String id;
  final String title;
  final DateTime date;
  final String location;
  final String description;
  final String longDescription;
  final bool isPaid;
  final double price;
  final String currency;
  final String imageUrl;
  final String category;
  final int attendeeCount;
  final int maxAttendees;
  final String organizer;
  final List<String> tags;
  final List<Map<String, String>> speakers;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.description,
    required this.longDescription,
    required this.isPaid,
    required this.price,
    required this.currency,
    required this.imageUrl,
    required this.category,
    required this.attendeeCount,
    required this.maxAttendees,
    required this.organizer,
    required this.tags,
    required this.speakers,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'location': location,
      'description': description,
      'longDescription': longDescription,
      'isPaid': isPaid,
      'price': price,
      'currency': currency,
      'imageUrl': imageUrl,
      'category': category,
      'attendeeCount': attendeeCount,
      'maxAttendees': maxAttendees,
      'organizer': organizer,
      'tags': tags,
      'speakers': speakers,
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      longDescription: json['longDescription'] ?? '',
      isPaid: json['isPaid'] ?? false,
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      attendeeCount: json['attendeeCount'] ?? 0,
      maxAttendees: json['maxAttendees'] ?? 0,
      organizer: json['organizer'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      speakers: List<Map<String, String>>.from(
        (json['speakers'] ?? []).map((speaker) => Map<String, String>.from(speaker)),
      ),
    );
  }

  Event copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? location,
    String? description,
    String? longDescription,
    bool? isPaid,
    double? price,
    String? currency,
    String? imageUrl,
    String? category,
    int? attendeeCount,
    int? maxAttendees,
    String? organizer,
    List<String>? tags,
    List<Map<String, String>>? speakers,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      location: location ?? this.location,
      description: description ?? this.description,
      longDescription: longDescription ?? this.longDescription,
      isPaid: isPaid ?? this.isPaid,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      organizer: organizer ?? this.organizer,
      tags: tags ?? this.tags,
      speakers: speakers ?? this.speakers,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Event && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Event(id: $id, title: $title, date: $date, location: $location)';
  }
}
