import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yappieyappie/core/theme/app_theme.dart';
import 'package:yappieyappie/features/auth/presentation/auth_screen.dart';
import 'package:yappieyappie/features/home/presentation/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: YappieYappieApp()));
}

class YappieYappieApp extends StatelessWidget {
  const YappieYappieApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/auth',
      routes: [
        GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      ],
      redirect: (context, state) {
        final isLoggedIn = FirebaseAuth.instance.currentUser != null;
        final goingToAuth = state.matchedLocation == '/auth';

        if (!isLoggedIn && !goingToAuth) return '/auth';
        if (isLoggedIn && goingToAuth) return '/home';
        return null;
      },
    );

    return MaterialApp.router(
      title: 'YappieYappie',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
