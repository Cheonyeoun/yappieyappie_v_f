import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/router/app_router.dart';
import 'core/theme/core/app_theme.dart';
import 'firebase_options.dart';
import 'core/utils/core/app_lifecycle_observer.dart';
import 'services/notifications/push_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize push notifications asynchronously so it DOES NOT block runApp()
  PushService.instance.initialize();

  runApp(
    const ProviderScope(
      child: YappieYappieApp(),
    ),
  );
}

class YappieYappieApp extends ConsumerWidget {
  const YappieYappieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return AppLifecycleObserver(
      // <--- THIS FIXES THE ONLINE BUG
      child: MaterialApp.router(
        title: 'YappieYappie',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: router, // <--- THIS FIXES THE ROUTING BUG
      ),
    );
  }
}
