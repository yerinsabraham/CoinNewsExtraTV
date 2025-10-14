import 'package:shared_preferences/shared_preferences.dart';

class FirstLaunchService {
  static const _keySeenIntro = 'seen_intro_v1';
  static const _keyRequestTour = 'request_tour_v1';

  Future<bool> hasSeenIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySeenIntro) ?? false;
  }

  Future<void> setSeenIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySeenIntro, true);
  }

  /// Request that the tour be shown on next Home load (used by Settings).
  Future<void> requestTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRequestTour, true);
  }

  /// Consume and clear any pending tour request. Returns true if a request was present.
  Future<bool> consumeTourRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final requested = prefs.getBool(_keyRequestTour) ?? false;
    if (requested) {
      await prefs.remove(_keyRequestTour);
    }
    return requested;
  }
}
