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
      'cneBalance': totalBalance, // Keep both fields in sync for compatibility
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
    // Check both totalBalance and cneBalance for compatibility
    final totalBalance = (data['totalBalance'] ?? 0.0).toDouble();
    final cneBalance = (data['cneBalance'] ?? 0.0).toDouble();
    
    // Use the higher value to ensure we don't lose rewards
    final actualBalance = totalBalance > cneBalance ? totalBalance : cneBalance;
    
    // If there's a mismatch, sync them by updating totalBalance to match cneBalance
    if (totalBalance != cneBalance && cneBalance > 0) {
      print('🔄 Syncing balance fields: totalBalance=$totalBalance, cneBalance=$cneBalance');
      _syncBalanceFields(cneBalance);
    }
    
    _balance = actualBalance > 0 ? actualBalance : 10.0; // Default to 10 if both are 0
    _userBalance = UserBalance.fromMap(data);
    _error = null;
    notifyListeners();
  }

  Future<void> _syncBalanceFields(double cneBalance) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'totalBalance': cneBalance,
        'lastSyncAt': FieldValue.serverTimestamp(),
      });
      print('✅ Balance fields synchronized: totalBalance updated to $cneBalance');
    } catch (e) {
      print('❌ Failed to sync balance fields: $e');
    }
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
      _balance = newBalance;

      final updatedBalance = UserBalance(
        totalBalance: newBalance,
        lockedBalance: 0.0,
        unlockedBalance: newBalance,
        pendingBalance: 0.0,
        totalEarnings: (_userBalance.totalEarnings + amount.toInt()),
        totalUsdValue: newBalance * 0.50,
        lastUpdated: DateTime.now().toIso8601String(),
      );

      // Update in-memory userBalance and notify listeners immediately
      _userBalance = updatedBalance;
      notifyListeners();

      // Persist the change using atomic increments to avoid race conditions
      await _firestore.collection('users').doc(user.uid).set({
        'totalBalance': FieldValue.increment(amount),
        'cneBalance': FieldValue.increment(amount),
        'totalEarnings': FieldValue.increment(amount.toInt()),
        'lastUpdated': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // Also log the earning activity
      await _logEarningActivity(user.uid, amount, reason);

      // Read back the user document to verify persisted values (debug / parity check)
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final persistedTotal = (data['totalBalance'] ?? data['cneBalance'] ?? 0).toDouble();
          final persistedCne = (data['cneBalance'] ?? data['totalBalance'] ?? 0).toDouble();
          debugPrint('Persisted values after addBalance -> totalBalance: $persistedTotal, cneBalance: $persistedCne');
        } else {
          debugPrint('User doc not found after write (unexpected)');
        }
      } catch (e) {
        debugPrint('Error reading back user doc after addBalance: $e');
      }

      debugPrint('Added $amount CNE: $reason. New balance (local): $newBalance CNE');
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
      // Use a transaction to atomically deduct the balance to avoid races
      final userDocRef = _firestore.collection('users').doc(user.uid);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDocRef);
        if (!snapshot.exists) throw Exception('User document does not exist');

        final data = snapshot.data() as Map<String, dynamic>;
        final currentTotal = (data['totalBalance'] ?? data['cneBalance'] ?? 0).toDouble();

        if (currentTotal < amount) {
          throw Exception('Insufficient balance');
        }

        final newBalance = currentTotal - amount;

        transaction.update(userDocRef, {
          'totalBalance': newBalance,
          'cneBalance': newBalance,
          'totalUsdValue': newBalance * 0.50,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      });

      // Update local in-memory balance after successful transaction
      _balance = _balance - amount;

      // Log the spending activity
      await _logSpendingActivity(user.uid, amount);

      notifyListeners();

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
    // Present token equivalent label for UI: show the approximate fiat value
    // as a CNE-labelled string for consistency with token-only UI.
    // Note: this keeps numeric computation intact but changes presentation.
    return '${(_balance * 0.50).toStringAsFixed(2)} USD';
  }

  double get availableBalance => _balance;
  
  bool canAfford(double amount) {
    return _balance >= amount;
  }

  /// Force refresh balance from Firestore
  Future<void> refreshBalance() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _updateBalanceFromFirestore(data);
        print('🔄 Balance manually refreshed from Firestore');
      }
    } catch (e) {
      print('❌ Failed to refresh balance: $e');
      _error = 'Failed to refresh balance: $e';
      notifyListeners();
    }
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
