import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/support_ticket.dart';
import '../models/support_chat.dart';
import '../models/support_call.dart';

class SupportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _ticketsCollection = 'support_tickets';
  static const String _chatsCollection = 'support_chats';
  static const String _callsCollection = 'support_calls';
  static const String _messagesCollection = 'messages';

  // ===== TICKET OPERATIONS =====

  /// Submit a new support ticket
  static Future<String> submitTicket(SupportTicket ticket) async {
    try {
      final docRef = await _firestore.collection(_ticketsCollection).add({
        ...ticket.toFirestore(),
        'id': '', // Placeholder, will be updated
      });

      // Update the document with its own ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit ticket: $e');
    }
  }

  /// Get all tickets for current user
  static Stream<List<SupportTicket>> getUserTickets() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    return _firestore
        .collection(_ticketsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportTicket.fromFirestore(doc))
            .toList());
  }

  /// Get ticket by ID
  static Future<SupportTicket?> getTicketById(String ticketId) async {
    try {
      final doc = await _firestore.collection(_ticketsCollection).doc(ticketId).get();
      if (!doc.exists) return null;
      return SupportTicket.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get ticket: $e');
    }
  }

  /// Update ticket status (Admin only)
  static Future<void> updateTicketStatus(String ticketId, SupportTicketStatus status) async {
    try {
      await _firestore.collection(_ticketsCollection).doc(ticketId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update ticket status: $e');
    }
  }

  /// Assign ticket to admin (Admin only)
  static Future<void> assignTicket(String ticketId, String adminId, String adminName) async {
    try {
      await _firestore.collection(_ticketsCollection).doc(ticketId).update({
        'assignedTo': adminId,
        'assignedAdminName': adminName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to assign ticket: $e');
    }
  }

  // ===== CHAT OPERATIONS =====

  /// Create a new support chat
  static Future<String> createSupportChat(String subject) async {
    try {
      final userId = _auth.currentUser?.uid;
      final userEmail = _auth.currentUser?.email;
      final userName = _auth.currentUser?.displayName ?? 'Unknown User';

      if (userId == null) throw Exception('User not logged in');

      final chat = SupportChat(
        id: '',
        userId: userId,
        userEmail: userEmail ?? '',
        userName: userName,
        subject: subject,
        status: SupportChatStatus.active,
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
        unreadByUser: 0,
        unreadByAdmin: 0,
        lastMessage: '',
      );

      final docRef = await _firestore.collection(_chatsCollection).add({
        ...chat.toFirestore(),
        'id': '', // Placeholder
      });

      // Update with actual ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  /// Get user's support chats
  static Stream<List<SupportChat>> getUserChats() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    return _firestore
        .collection(_chatsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportChat.fromFirestore(doc))
            .toList());
  }

  /// Get chat by ID
  static Future<SupportChat?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection(_chatsCollection).doc(chatId).get();
      if (!doc.exists) return null;
      return SupportChat.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get chat: $e');
    }
  }

  // ===== MESSAGE OPERATIONS =====

  /// Send a message in support chat
  static Future<void> sendMessage(String chatId, String message, {String? attachmentUrl}) async {
    try {
      final userId = _auth.currentUser?.uid;
      final userName = _auth.currentUser?.displayName ?? 'User';

      if (userId == null) throw Exception('User not logged in');

      final chatMessage = ChatMessage(
        id: '',
        chatId: chatId,
        senderId: userId,
        senderName: userName,
        senderType: 'user',
        message: message,
        attachmentUrl: attachmentUrl,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Add message
      final docRef = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .add(chatMessage.toFirestore());

      // Update message with its ID
      await docRef.update({'id': docRef.id});

      // Update chat's last message and unread count
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'lastMessage': message,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadByAdmin': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get messages for a chat
  static Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _firestore
        .collection(_chatsCollection)
        .doc(chatId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  /// Mark messages as read by user
  static Future<void> markMessagesAsRead(String chatId) async {
    try {
      final batch = _firestore.batch();
      
      // Get unread messages from admin
      final unreadMessages = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .where('senderType', isEqualTo: 'admin')
          .where('isRead', isEqualTo: false)
          .get();

      // Mark them as read
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Reset unread count for user
      batch.update(
        _firestore.collection(_chatsCollection).doc(chatId),
        {'unreadByUser': 0},
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Delete a chat and all its messages
  static Future<void> deleteChat(String chatId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      // Get chat to verify ownership (users can only delete their own chats, admins can delete any)
      final chatDoc = await _firestore.collection(_chatsCollection).doc(chatId).get();
      if (!chatDoc.exists) throw Exception('Chat not found');

      final chat = SupportChat.fromFirestore(chatDoc);
      
      // Check if user owns this chat or is admin
      // TODO: Add proper admin role check when user roles are implemented
      final isOwner = chat.userId == userId;
      if (!isOwner) {
        throw Exception('You can only delete your own chats');
      }

      final batch = _firestore.batch();

      // Delete all messages in the chat
      final messagesSnapshot = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesCollection)
          .get();

      for (final messageDoc in messagesSnapshot.docs) {
        batch.delete(messageDoc.reference);
      }

      // Delete the chat document
      batch.delete(_firestore.collection(_chatsCollection).doc(chatId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  // ===== CALL OPERATIONS =====

  /// Initiate a support call
  static Future<String> initiateCall(String? chatId, String? ticketId) async {
    try {
      final userId = _auth.currentUser?.uid;
      final userEmail = _auth.currentUser?.email;
      final userName = _auth.currentUser?.displayName ?? 'Unknown User';

      if (userId == null) throw Exception('User not logged in');

      final call = SupportCall(
        id: '',
        userId: userId,
        userEmail: userEmail ?? '',
        userName: userName,
        chatId: chatId,
        ticketId: ticketId,
        status: SupportCallStatus.initiated,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection(_callsCollection).add({
        ...call.toFirestore(),
        'id': '', // Placeholder
      });

      // Update with actual ID
      await docRef.update({'id': docRef.id});

      // TODO: Send push notification to admins
      await _notifyAdminsOfCall(docRef.id, userName);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to initiate call: $e');
    }
  }

  /// Accept a call (Admin only)
  static Future<void> acceptCall(String callId, String adminId, String adminName, 
      String agoraChannel, String agoraToken) async {
    try {
      await _firestore.collection(_callsCollection).doc(callId).update({
        'status': SupportCallStatus.connected.toString().split('.').last,
        'adminId': adminId,
        'adminName': adminName,
        'agoraChannel': agoraChannel,
        'agoraToken': agoraToken,
        'connectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to accept call: $e');
    }
  }

  /// End a call
  static Future<void> endCall(String callId, [int? durationSeconds]) async {
    try {
      final callDoc = await _firestore.collection(_callsCollection).doc(callId).get();
      if (!callDoc.exists) throw Exception('Call not found');

      final call = SupportCall.fromFirestore(callDoc);
      int? finalDurationSeconds = durationSeconds;

      // If duration not provided, calculate from connectedAt
      if (finalDurationSeconds == null && call.connectedAt != null) {
        finalDurationSeconds = DateTime.now().difference(call.connectedAt!).inSeconds;
      }

      await _firestore.collection(_callsCollection).doc(callId).update({
        'status': SupportCallStatus.ended.toString().split('.').last,
        'endedAt': FieldValue.serverTimestamp(),
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
      });
    } catch (e) {
      throw Exception('Failed to end call: $e');
    }
  }

  /// Get call by ID
  static Future<SupportCall?> getCallById(String callId) async {
    try {
      final doc = await _firestore.collection(_callsCollection).doc(callId).get();
      if (!doc.exists) return null;
      return SupportCall.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get call: $e');
    }
  }

  /// Get user's call history
  static Stream<List<SupportCall>> getUserCalls() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    return _firestore
        .collection(_callsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportCall.fromFirestore(doc))
            .toList());
  }

  // ===== ADMIN OPERATIONS =====

  /// Get all tickets (Admin only)
  static Stream<List<SupportTicket>> getAllTickets() {
    return _firestore
        .collection(_ticketsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportTicket.fromFirestore(doc))
            .toList());
  }

  /// Get all chats (Admin only)
  static Stream<List<SupportChat>> getAllChats() {
    return _firestore
        .collection(_chatsCollection)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportChat.fromFirestore(doc))
            .toList());
  }

  /// Get pending calls (Admin only)
  static Stream<List<SupportCall>> getPendingCalls() {
    return _firestore
        .collection(_callsCollection)
        .where('status', isEqualTo: SupportCallStatus.initiated.toString().split('.').last)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportCall.fromFirestore(doc))
            .toList());
  }

  // ===== UTILITY METHODS =====

  /// Send push notification to admins about new call
  static Future<void> _notifyAdminsOfCall(String callId, String userName) async {
    try {
      // TODO: Implement push notification logic
      // This would typically involve:
      // 1. Get all admin FCM tokens from Firestore
      // 2. Send push notification using Firebase Cloud Messaging
      // 3. Include call ID and user name in notification payload
      
      print('📞 Notifying admins of call from $userName (Call ID: $callId)');
      
      // For now, we'll create a simple admin notification document
      await _firestore.collection('admin_notifications').add({
        'type': 'support_call',
        'callId': callId,
        'userName': userName,
        'message': '$userName is requesting support assistance',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error notifying admins: $e');
      // Don't throw error here as call creation should still succeed
    }
  }

  /// Get support statistics (Admin only)
  static Future<Map<String, dynamic>> getSupportStats() async {
    try {
      final tickets = await _firestore.collection(_ticketsCollection).get();
      final chats = await _firestore.collection(_chatsCollection).get();
      final calls = await _firestore.collection(_callsCollection).get();

      final openTickets = tickets.docs.where((doc) => 
          doc.data()['status'] == 'open').length;
      final activeChats = chats.docs.where((doc) => 
          doc.data()['status'] == 'active').length;
      final pendingCalls = calls.docs.where((doc) => 
          doc.data()['status'] == 'initiated').length;

      return {
        'totalTickets': tickets.docs.length,
        'openTickets': openTickets,
        'totalChats': chats.docs.length,
        'activeChats': activeChats,
        'totalCalls': calls.docs.length,
        'pendingCalls': pendingCalls,
      };
    } catch (e) {
      throw Exception('Failed to get support stats: $e');
    }
  }

  /// Search tickets and chats (Admin only)
  static Future<Map<String, dynamic>> searchSupport(String query) async {
    try {
      final lowercaseQuery = query.toLowerCase();
      
      // Search tickets
      final ticketsQuery = await _firestore.collection(_ticketsCollection).get();
      final matchingTickets = ticketsQuery.docs.where((doc) {
        final data = doc.data();
        return data['userEmail'].toString().toLowerCase().contains(lowercaseQuery) ||
               data['userName'].toString().toLowerCase().contains(lowercaseQuery) ||
               data['issueDescription'].toString().toLowerCase().contains(lowercaseQuery);
      }).map((doc) => SupportTicket.fromFirestore(doc)).toList();

      // Search chats
      final chatsQuery = await _firestore.collection(_chatsCollection).get();
      final matchingChats = chatsQuery.docs.where((doc) {
        final data = doc.data();
        return data['userEmail'].toString().toLowerCase().contains(lowercaseQuery) ||
               data['userName'].toString().toLowerCase().contains(lowercaseQuery) ||
               data['subject'].toString().toLowerCase().contains(lowercaseQuery);
      }).map((doc) => SupportChat.fromFirestore(doc)).toList();

      return {
        'tickets': matchingTickets,
        'chats': matchingChats,
      };
    } catch (e) {
      throw Exception('Failed to search support data: $e');
    }
  }
}