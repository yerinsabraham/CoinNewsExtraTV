import 'package:flutter/foundation.dart';

class AdminProvider extends ChangeNotifier {
  bool _isAdmin = false;
  bool _isLoading = false;

  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;

  // Mock admin check - in real app this would check user permissions
  Future<void> checkAdminStatus() async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock: set to true for testing, false for normal users
    _isAdmin = false; // Change to true to test admin features

    _isLoading = false;
    notifyListeners();
  }

  void setAdminStatus(bool isAdmin) {
    _isAdmin = isAdmin;
    notifyListeners();
  }

  void logout() {
    _isAdmin = false;
    notifyListeners();
  }
}
