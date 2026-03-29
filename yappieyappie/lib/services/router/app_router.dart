import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/presentation/auth_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../providers/auth/auth_provider.dart'; // <- authStateProvider
import '../providers/splash/splash_provider.dart'; // <- splashScreenProvider

// Optional: class to notify GoRouter of auth changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final showSplashOnce = ref.watch(splashScreenProvider);

  return GoRouter(
    // Always start on splash
    initialLocation: '/splash',

    // Optional: refresh routes when Firebase auth changes
    refreshListenable:
        GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),

    redirect: (context, state) {
      final route = state.matchedLocation;

      // 1. If splash must be shown once, force it (even if auth loads fast)
      if (showSplashOnce) {
        if (route == '/splash') return null;
        return '/splash';
      }

      // 2. If auth is still loading, also force splash
      if (authState.isLoading) {
        if (route == '/splash') return null;
        return '/splash';
      }

      final user = authState.value;
      final isAtAuth = route == '/auth';
      final isAtSplash = route == '/splash';

      // 3. Not logged in → /auth
      if (user == null) {
        if (isAtAuth) return null;
        return '/auth';
      }

      // 4. If logged in → /splash or /auth → go to /home
      if (isAtSplash || isAtAuth) {
        return '/home';
      }

      // 5. Otherwise, stay on current route (e.g. /home or deeper)
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});
