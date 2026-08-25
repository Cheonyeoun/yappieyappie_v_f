import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/controllers/call/call_controller.dart';
import 'package:yappieyappie/features/call/presentation/livekit_call_screen.dart';
import 'package:yappieyappie/services/router/app_router.dart';

class CallOverlay extends ConsumerWidget {
  const CallOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callControllerProvider);

    // Only show the overlay if a call is active and MINIMIZED
    if (!callState.isActive || !callState.isMinimized) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 50,
      right: 20,
      child: GestureDetector(
        onTap: () {
          // Maximize Call
          ref.read(callControllerProvider.notifier).maximizeCall();
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.call, color: Colors.black, size: 20),
                const SizedBox(width: 8),
                Text(
                  callState.isConnecting ? "Connecting..." : "Tap to return",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
