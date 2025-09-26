import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  UserProvider() {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((u) {
      _user = u;
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    await AuthService.signInWithGoogle();
    // firebase auth state listener will update _user
  }

  Future<void> signInWithEmail(String email, String password) async {
    await AuthService.signInWithEmail(email, password);
  }

  Future<void> signOut() async {
    await AuthService.signOut();
  }
}
