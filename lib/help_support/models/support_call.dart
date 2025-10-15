import 'package:cloud_firestore/cloud_firestore.dart';

enum SupportCallStatus {
  initiated,
  connected,
  ended
}

class SupportCall {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String? chatId;
  final String? ticketId;
  final String? adminId;
  final String? adminName;
  final String? agoraChannel;
  final String? agoraToken;
  final SupportCallStatus status;
  final DateTime createdAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final int? durationSeconds;

  SupportCall({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.chatId,
    this.ticketId,
    this.adminId,
    this.adminName,
    this.agoraChannel,
    this.agoraToken,
    required this.status,
    required this.createdAt,
    this.connectedAt,
    this.endedAt,
    this.durationSeconds,
  });

  factory SupportCall.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SupportCall(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      chatId: data['chatId'],
      ticketId: data['ticketId'],
      adminId: data['adminId'],
      adminName: data['adminName'],
      agoraChannel: data['agoraChannel'],
      agoraToken: data['agoraToken'],
      status: SupportCallStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => SupportCallStatus.initiated,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      connectedAt: data['connectedAt'] != null 
          ? (data['connectedAt'] as Timestamp).toDate() 
          : null,
      endedAt: data['endedAt'] != null 
          ? (data['endedAt'] as Timestamp).toDate() 
          : null,
      durationSeconds: data['durationSeconds'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'chatId': chatId,
      'ticketId': ticketId,
      'adminId': adminId,
      'adminName': adminName,
      'agoraChannel': agoraChannel,
      'agoraToken': agoraToken,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'connectedAt': connectedAt != null ? Timestamp.fromDate(connectedAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'durationSeconds': durationSeconds,
    };
  }

  String get statusDisplayName {
    switch (status) {
      case SupportCallStatus.initiated:
        return 'Calling...';
      case SupportCallStatus.connected:
        return 'Connected';
      case SupportCallStatus.ended:
        return 'Ended';
    }
  }

  String get formattedDuration {
    if (durationSeconds == null) return '00:00';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}