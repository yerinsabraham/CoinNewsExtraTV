import 'package:cloud_firestore/cloud_firestore.dart';

enum SupportChatStatus {
  active,
  waiting,
  closed
}

class SupportChat {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String subject;
  final SupportChatStatus status;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int unreadByUser;
  final int unreadByAdmin;
  final String lastMessage;
  final String? assignedTo;
  final String assignedAdminName;

  SupportChat({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.lastMessageAt,
    required this.unreadByUser,
    required this.unreadByAdmin,
    required this.lastMessage,
    this.assignedTo,
    this.assignedAdminName = '',
  });

  factory SupportChat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SupportChat(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      subject: data['subject'] ?? '',
      status: SupportChatStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => SupportChatStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastMessageAt: data['lastMessageAt'] != null 
          ? (data['lastMessageAt'] as Timestamp).toDate() 
          : DateTime.now(),
      unreadByUser: data['unreadByUser'] ?? 0,
      unreadByAdmin: data['unreadByAdmin'] ?? 0,
      lastMessage: data['lastMessage'] ?? '',
      assignedTo: data['assignedTo'],
      assignedAdminName: data['assignedAdminName'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'subject': subject,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'unreadByUser': unreadByUser,
      'unreadByAdmin': unreadByAdmin,
      'lastMessage': lastMessage,
      'assignedTo': assignedTo,
      'assignedAdminName': assignedAdminName,
    };
  }

  String get statusDisplayName {
    switch (status) {
      case SupportChatStatus.active:
        return 'Active';
      case SupportChatStatus.waiting:
        return 'Waiting';
      case SupportChatStatus.closed:
        return 'Closed';
    }
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderType;
  final String message;
  final String? attachmentUrl;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.message,
    this.attachmentUrl,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatMessage(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderType: data['senderType'] ?? 'user',
      message: data['message'] ?? '',
      attachmentUrl: data['attachmentUrl'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'message': message,
      'attachmentUrl': attachmentUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}