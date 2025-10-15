import 'package:cloud_firestore/cloud_firestore.dart';

enum SupportTicketStatus {
  open,
  inProgress,
  resolved,
  closed
}

class SupportTicket {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String issueDescription;
  final SupportTicketStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? assignedAdminId;
  final String? assignedAdminName;
  final String? adminResponse;
  final String category;
  final String priority; // 'low', 'medium', 'high', 'urgent'

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.issueDescription,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.assignedAdminId,
    this.assignedAdminName,
    this.adminResponse,
    this.category = 'general',
    this.priority = 'medium',
  });

  factory SupportTicket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SupportTicket(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      issueDescription: data['issueDescription'] ?? '',
      status: SupportTicketStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => SupportTicketStatus.open,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      assignedAdminId: data['assignedAdminId'],
      assignedAdminName: data['assignedAdminName'],
      adminResponse: data['adminResponse'],
      category: data['category'] ?? 'general',
      priority: data['priority'] ?? 'medium',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'issueDescription': issueDescription,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'assignedAdminId': assignedAdminId,
      'assignedAdminName': assignedAdminName,
      'adminResponse': adminResponse,
      'category': category,
      'priority': priority,
    };
  }

  SupportTicket copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    String? issueDescription,
    SupportTicketStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedAdminId,
    String? assignedAdminName,
    String? adminResponse,
    String? category,
    String? priority,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      issueDescription: issueDescription ?? this.issueDescription,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedAdminId: assignedAdminId ?? this.assignedAdminId,
      assignedAdminName: assignedAdminName ?? this.assignedAdminName,
      adminResponse: adminResponse ?? this.adminResponse,
      category: category ?? this.category,
      priority: priority ?? this.priority,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case SupportTicketStatus.open:
        return 'Open';
      case SupportTicketStatus.inProgress:
        return 'In Progress';
      case SupportTicketStatus.resolved:
        return 'Resolved';
      case SupportTicketStatus.closed:
        return 'Closed';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return 'Medium';
    }
  }
}