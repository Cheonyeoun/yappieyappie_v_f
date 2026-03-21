import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/services/auth_service.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to auth state
    final authState = ref.watch(authServiceProvider).authStateChange;

    return StreamBuilder(
      stream: authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // This is a simple logic gate
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (snapshot.hasData) {
            context.go('/home');
          } else {
            context.go('/auth');
          }
        });

        return const Scaffold(body: Center(child: Text("YappieYappie...")));
      },
    );
  }
}
