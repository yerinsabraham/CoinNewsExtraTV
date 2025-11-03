import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'first_launch_service.dart';

class TourService {
  TutorialCoachMark? _tutorial;

  // Singleton-like factory to allow calling next/skip from other places.
  static final TourService _instance = TourService._internal();
  TourService._internal();
  factory TourService() => _instance;

  Future<void> showTour({
    required BuildContext context,
    required List<TargetFocus> targets,
    VoidCallback? onFinishCallback,
    VoidCallback? onSkipCallback,
  }) async {
    _tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.8),
      textSkip: "Skip Tour",
      alignSkip: Alignment.topLeft,
      // Keep callbacks for finish/skip to set the seen flag
      onFinish: () {
        FirstLaunchService().setSeenIntro();
        if (onFinishCallback != null) onFinishCallback();
        // some versions of the package expect a return value; return true to be safe
        return true;
      },
      onSkip: () {
        FirstLaunchService().setSeenIntro();
        if (onSkipCallback != null) onSkipCallback();
        return true;
      },
    );

    _tutorial?.show(context: context);
  }

  /// Move to the next step in the tutorial if available.
  void next() => _tutorial?.next();

  /// Skip the tutorial entirely.
  void skip() => _tutorial?.skip();
}
