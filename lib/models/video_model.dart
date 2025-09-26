import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id; // doc id (not a list)
  final String title; // (not a list)
  final String description; // (not a list)
  final String youtubeId; // youtube video id (not a list)
  final double reward; // (not a list) - new field
  final String thumbnailUrl; // (not a list) - renamed from thumbnail
  final int durationSeconds; // (not a list)

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeId,
    required this.reward, // (not a list) - new field
    required this.thumbnailUrl, // (not a list) - renamed from thumbnail
    required this.durationSeconds, // (not a list)
  });

  factory VideoModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      youtubeId: data['youtubeId'] ?? '',
      reward: (data['reward'] ?? 0.0) as double, // (not a list) - new field
      thumbnailUrl: data['thumbnailUrl'] ?? '', // (not a list) - renamed from thumbnail
      durationSeconds: (data['durationSeconds'] ?? 0) as int,
    );
  }
}
