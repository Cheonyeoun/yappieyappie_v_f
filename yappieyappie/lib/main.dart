import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/router/app_router.dart';
import 'core/theme/core/app_theme.dart';
import 'firebase_options.dart';
import 'core/utils/core/app_lifecycle_observer.dart';
import 'services/notifications/push_service.dart';
import 'services/call/callkit_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yappieyappie/services/call/signaling_service.dart';
import 'package:yappieyappie/features/call/presentation/widgets/call_overlay.dart';
import 'package:yappieyappie/features/call/presentation/livekit_call_screen.dart';
import 'package:yappieyappie/controllers/call/call_controller.dart';

Future<void> _handleIncomingFCMCall(RemoteMessage message, {ProviderContainer? container}) async {
  if (message.data['type'] == 'call') {
    // If foreground container is provided, check if we are busy
    if (container != null) {
      final callState = container.read(callControllerProvider);
      if (callState.isActive) {
        final callerId = message.data['callerId'];
        final roomName = message.data['roomName'];
        final myUid = FirebaseAuth.instance.currentUser?.uid;
        if (callerId != null && myUid != null && roomName != null) {
          SignalingService.instance.sendCallCancelledSignal(
            receiverId: callerId,
            callerId: myUid,
            roomName: roomName,
          );
        }
        return;
      }
    }
    await CallKitService.instance.showIncomingCall(
      callerId: message.data['callerId'] ?? '',
      callerName: message.data['callerName'] ?? 'Unknown Caller',
      callerAvatar: message.data['callerAvatar'] ?? '',
      roomName: message.data['roomName'] ?? '',
      callId: message.data['callId'] ?? const Uuid().v4(),
    );
  } else if (message.data['type'] == 'call_cancelled') {
    await CallKitService.instance.endAllCalls();
    container?.read(callControllerProvider.notifier).endCall();
  }
}
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _handleIncomingFCMCall(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final container = ProviderContainer();

  // Listen to foreground calls
  FirebaseMessaging.onMessage.listen((message) {
    _handleIncomingFCMCall(message, container: container);
  });

  // Initialize push notifications asynchronously so it DOES NOT block runApp()
  PushService.instance.initialize();
  
  // Initialize native ringing system
  CallKitService.instance.init(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const YappieYappieApp(),
    ),
  );
}

class GlobalCallManager extends ConsumerWidget {
  const GlobalCallManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callControllerProvider);
    if (!callState.isActive) return const SizedBox.shrink();
    if (callState.isMinimized) return const CallOverlay();
    return const LiveKitCallScreen();
  }
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
        builder: (context, child) {
          return Stack(
            children: [
              if (child != null) child,
              const GlobalCallManager(),
            ],
          );
        },
      ),
    );
  }
}
