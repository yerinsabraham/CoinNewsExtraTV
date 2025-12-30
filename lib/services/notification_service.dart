import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _channelId = 'coinnewsextra_notifications';
  static const String _channelName = 'CoinNewsExtra Notifications';
  static const String _channelDescription = 'Notifications from CoinNewsExtra TV';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  String? _fcmToken;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase Messaging
      await _initializeFirebaseMessaging();

      // Get and store FCM token
      await _getFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      _isInitialized = true;
      debugPrint('🔔 NotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ NotificationService initialization error: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Request Firebase Messaging permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('🔔 Firebase Messaging permission status: ${settings.authorizationStatus}');

    // Request system notification permission (Android 13+)
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      debugPrint('🔔 System notification permission: $status');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Initialize timezone data for scheduling
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (e) {
      debugPrint('❌ Error initializing timezone data: $e');
    }

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }

    debugPrint('🔔 Local notifications initialized');
  }

  /// Initialize Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Configure foreground notification presentation options for iOS
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('🔔 Firebase Messaging configured');
  }

  /// Get and store FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔔 FCM Token: $_fcmToken');

      if (_fcmToken != null) {
        await _storeFCMToken(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _storeFCMToken(newToken);
        debugPrint('🔔 FCM Token refreshed: $newToken');
      });
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// Store FCM token in Firestore
  Future<void> _storeFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
      });

      debugPrint('🔔 FCM token stored in Firestore');
    } catch (e) {
      debugPrint('❌ Error storing FCM token: $e');
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Handle terminated app message tap
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleBackgroundMessageTap(message);
      }
    });

    debugPrint('🔔 Message handlers configured');
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Foreground message received: ${message.messageId}');
    
    // Show local notification when app is in foreground
    await _showLocalNotification(
      title: message.notification?.title ?? 'CoinNewsExtra',
      body: message.notification?.body ?? 'New notification',
      payload: message.data,
    );
  }

  /// Handle background message tap
  void _handleBackgroundMessageTap(RemoteMessage message) {
    debugPrint('🔔 Background message tapped: ${message.messageId}');
    
    // Navigate to appropriate screen based on message data
    _navigateFromNotification(message.data);
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: payload?.toString(),
      );

      debugPrint('🔔 Local notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      // Parse payload and navigate
      try {
        // For now, just navigate to notifications screen
        // You can extend this to handle different notification types
        _navigateToNotifications();
      } catch (e) {
        debugPrint('❌ Error handling notification tap: $e');
      }
    }
  }

  /// Navigate from notification
  void _navigateFromNotification(Map<String, dynamic> data) {
    // Handle different notification types
    final type = data['type'] as String?;
    
    switch (type) {
      case 'announcement':
        _navigateToNotifications();
        break;
      case 'support':
        _navigateToSupport();
        break;
      default:
        _navigateToNotifications();
    }
  }

  /// Navigate to notifications screen
  void _navigateToNotifications() {
    // This will be handled by the main app navigation
    debugPrint('🔔 Navigate to notifications screen');
  }

  /// Navigate to support screen
  void _navigateToSupport() {
    // This will be handled by the main app navigation
    debugPrint('🔔 Navigate to support screen');
  }

  /// Send test notification (for debugging)
  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from CoinNewsExtra TV',
      payload: {'type': 'test'},
    );
  }

  /// Schedule a local notification at a specific DateTime
  Future<int> scheduleNotificationForDate({
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000; // compact int id

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload?.toString(),
      );

      // Persist scheduled notification metadata in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final key = 'scheduled_notification_$id';
      final value = jsonEncode({
        'title': title,
        'body': body,
        'time': scheduledDate.millisecondsSinceEpoch,
      });
      await prefs.setString(key, value);

      debugPrint('🔔 Scheduled notification id=$id at $scheduledDate');
      return id;
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
      rethrow;
    }
  }

  /// Cancel a scheduled notification by id and remove persisted metadata
  Future<void> cancelScheduledNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      final prefs = await SharedPreferences.getInstance();
      final key = 'scheduled_notification_$id';
      if (prefs.containsKey(key)) await prefs.remove(key);
      debugPrint('🔔 Canceled scheduled notification id=$id');
    } catch (e) {
      debugPrint('❌ Error canceling scheduled notification: $e');
    }
  }

  /// Return list of persisted scheduled notifications
  Future<List<Map<String, dynamic>>> getPersistedScheduledNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('scheduled_notification_'));
    final List<Map<String, dynamic>> items = [];
    for (final k in keys) {
      try {
        final idPart = k.replaceFirst('scheduled_notification_', '');
        final id = int.tryParse(idPart) ?? 0;
        final jsonStr = prefs.getString(k);
        if (jsonStr == null) continue;
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        data['id'] = id;
        items.add(data);
      } catch (e) {
        debugPrint('❌ Error reading scheduled notification $k: $e');
      }
    }
    return items;
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Clear FCM token on logout
  Future<void> clearFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': FieldValue.delete(),
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      _fcmToken = null;
      debugPrint('🔔 FCM token cleared');
    } catch (e) {
      debugPrint('❌ Error clearing FCM token: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message received: ${message.messageId}');
  
  // Handle background message processing here
  // Note: Don't call Flutter UI methods here as the app might not be running
}