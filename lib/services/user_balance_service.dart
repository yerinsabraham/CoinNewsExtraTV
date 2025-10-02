import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class UserBalance {
  final double totalBalance;
  final double lockedBalance;
  final double unlockedBalance;
  final double pendingBalance;
  final int totalEarnings;
  final double totalUsdValue;
  final String lastUpdated;

  UserBalance({
    required this.totalBalance,
    required this.lockedBalance,
    required this.unlockedBalance,
    required this.pendingBalance,
    required this.totalEarnings,
    required this.totalUsdValue,
    required this.lastUpdated,
  });

  factory UserBalance.fromMap(Map<String, dynamic> data) {
    return UserBalance(
      totalBalance: (data['totalBalance'] ?? 0.0).toDouble(),
      lockedBalance: (data['lockedBalance'] ?? 0.0).toDouble(),
      unlockedBalance: (data['unlockedBalance'] ?? 0.0).toDouble(),
      pendingBalance: (data['pendingBalance'] ?? 0.0).toDouble(),
      totalEarnings: data['totalEarnings'] ?? 0,
      totalUsdValue: (data['totalUsdValue'] ?? 0.0).toDouble(),
      lastUpdated: data['lastUpdated'] ?? DateTime.now().toIso8601String(),
    );
  }

  factory UserBalance.empty() {
    return UserBalance(
      totalBalance: 0.0,
      lockedBalance: 0.0,
      unlockedBalance: 0.0,
      pendingBalance: 0.0,
      totalEarnings: 0,
      totalUsdValue: 0.0,
      lastUpdated: DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalBalance': totalBalance,
      'lockedBalance': lockedBalance,
      'unlockedBalance': unlockedBalance,
      'pendingBalance': pendingBalance,
      'totalEarnings': totalEarnings,
      'totalUsdValue': totalUsdValue,
      'lastUpdated': lastUpdated,
    };
  }
}

class UserBalanceService extends ChangeNotifier {
  UserBalance _userBalance = UserBalance.empty();
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _authSubscription;
  StreamSubscription? _firestoreSubscription;
  
  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Simple in-memory balance for demo
  double _balance = 10.0; // Start with 10 CNE from backend
  
  // Getters
  UserBalance get userBalance => _userBalance;
  double get balance => _balance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserBalanceService() {
    _initializeService();
  }

  void _initializeService() {
    // Listen to auth state changes
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        // User signed in, load their balance and listen to real-time updates
        _listenToUserBalance(user.uid);
      } else {
        // User signed out, reset to empty state
        _resetToEmpty();
      }
    });
  }

  void _resetToEmpty() {
    _firestoreSubscription?.cancel();
    _userBalance = UserBalance.empty();
    _balance = 0.0;
    _error = null;
    notifyListeners();
  }

  void _listenToUserBalance(String userId) {
    _firestoreSubscription?.cancel();
    
    _firestoreSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        _updateBalanceFromFirestore(data);
      } else {
        // Create new user document with initial balance
        _createInitialUserDocument(userId);
      }
    }, onError: (error) {
      _error = 'Failed to load balance: $error';
      debugPrint('Firestore error: $error');
      notifyListeners();
    });
  }

  void _updateBalanceFromFirestore(Map<String, dynamic> data) {
    _balance = (data['totalBalance'] ?? 10.0).toDouble();
    _userBalance = UserBalance.fromMap(data);
    _error = null;
    notifyListeners();
  }

  Future<void> _createInitialUserDocument(String userId) async {
    try {
      final initialBalance = UserBalance(
        totalBalance: 10.0, // Start with 10 CNE
        lockedBalance: 0.0,
        unlockedBalance: 10.0,
        pendingBalance: 0.0,
        totalEarnings: 10,
        totalUsdValue: 5.0, // 10 CNE * $0.50
        lastUpdated: DateTime.now().toIso8601String(),
      );

      await _firestore.collection('users').doc(userId).set(initialBalance.toMap());
      
      _balance = 10.0;
      _userBalance = initialBalance;
      _error = null;
      notifyListeners();
      
      debugPrint('Created initial user document with 10 CNE for user: $userId');
    } catch (e) {
      _error = 'Failed to create user document: $e';
      debugPrint('Error creating user document: $e');
      notifyListeners();
    }
  }

  Future<void> loadUserBalance() async {
    final user = _auth.currentUser;
    if (user == null || _isLoading) return;
    
    _setLoading(true);
    _error = null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _updateBalanceFromFirestore(data);
      } else {
        // Create new user document
        await _createInitialUserDocument(user.uid);
      }
    } catch (e) {
      _error = 'Failed to load balance: $e';
      debugPrint('Error loading user balance: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add balance (for rewards)
  Future<void> addBalance(double amount, String reason) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Cannot add balance: User not authenticated');
      return;
    }

    try {
      // Update local balance immediately for responsive UI
      final newBalance = _balance + amount;
      final updatedBalance = UserBalance(
        totalBalance: newBalance,
        lockedBalance: 0.0,
        unlockedBalance: newBalance,
        pendingBalance: 0.0,
        totalEarnings: newBalance.toInt(),
        totalUsdValue: newBalance * 0.50,
        lastUpdated: DateTime.now().toIso8601String(),
      );

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).set(updatedBalance.toMap());

      // Also log the earning activity
      await _logEarningActivity(user.uid, amount, reason);

      debugPrint('Added $amount CNE: $reason. New balance: $newBalance CNE');
    } catch (e) {
      _error = 'Failed to add balance: $e';
      debugPrint('Error adding balance: $e');
      notifyListeners();
    }
  }

  Future<void> _logEarningActivity(String userId, double amount, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).collection('earnings').add({
        'amount': amount,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging earning activity: $e');
    }
  }

  // Spend balance
  Future<bool> spendBalance(double amount) async {
    final user = _auth.currentUser;
    if (user == null || _balance < amount) {
      return false;
    }

    try {
      final newBalance = _balance - amount;
      final updatedBalance = UserBalance(
        totalBalance: newBalance,
        lockedBalance: 0.0,
        unlockedBalance: newBalance,
        pendingBalance: 0.0,
        totalEarnings: _userBalance.totalEarnings, // Keep original total earnings
        totalUsdValue: newBalance * 0.50,
        lastUpdated: DateTime.now().toIso8601String(),
      );

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).set(updatedBalance.toMap());

      // Log the spending activity
      await _logSpendingActivity(user.uid, amount);

      return true;
    } catch (e) {
      _error = 'Failed to spend balance: $e';
      debugPrint('Error spending balance: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> _logSpendingActivity(String userId, double amount) async {
    try {
      await _firestore.collection('users').doc(userId).collection('spendings').add({
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging spending activity: $e');
    }
  }

  // Formatting methods
  String getFormattedBalance() {
    return _balance.toStringAsFixed(2);
  }

  String getFormattedUsdValue() {
    return '\$${(_balance * 0.50).toStringAsFixed(2)}';
  }

  double get availableBalance => _balance;
  
  bool canAfford(double amount) {
    return _balance >= amount;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _firestoreSubscription?.cancel();
    super.dispose();
  }
}
