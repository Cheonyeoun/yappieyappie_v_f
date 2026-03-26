import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final splashScreenProvider = NotifierProvider<SplashScreenNotifier, bool>(
  SplashScreenNotifier.new,
);

class SplashScreenNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Start true so splash must be shown first
    return true;
  }

  void markSplashFinished() {
    // Mark splash as finished, GoRouter will re‑evaluate
    state = false;
  }
}
