import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/controllers/call/call_controller.dart';

class LiveKitCallScreen extends ConsumerWidget {
  const LiveKitCallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callControllerProvider);
    final callNotifier = ref.read(callControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image (if available) & Blur
          Positioned.fill(
            child: callState.remoteAvatar != null && callState.remoteAvatar!.isNotEmpty
                ? Image.network(
                    callState.remoteAvatar!,
                    fit: BoxFit.cover,
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E1E2C),
                          callState.isConnecting ? const Color(0xFF3B1E28) : const Color(0xFF1A3B2B),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
          ),
          // Intense blur on top
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Bar (Minimize Button)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 36),
                      onPressed: () {
                        callNotifier.minimizeCall();
                      },
                    ),
                  ),
                ),
                
                // Avatar & Status
                Column(
                  children: [
                    _buildAnimatedAvatar(callState.remoteAvatar, callState.isConnecting),
                    const SizedBox(height: 32),
                    Text(
                      callState.remoteName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<int>(
                      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
                      builder: (context, snapshot) {
                        if (callState.isConnecting) {
                          return const Text(
                            'Calling...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        final duration = DateTime.now().difference(callState.startTime ?? DateTime.now());
                        final minutes = duration.inMinutes.toString().padLeft(2, '0');
                        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
                        return Text(
                          '$minutes:$seconds',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 16,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                    ),
                  ],
                ),
                
                // Controls Panel (Glassmorphism)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0, left: 24, right: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildControlBtn(
                              icon: callState.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                              color: callState.isSpeakerOn ? Colors.white : Colors.white24,
                              iconColor: callState.isSpeakerOn ? Colors.black : Colors.white,
                              onTap: () => callNotifier.toggleSpeaker(),
                            ),
                            _buildControlBtn(
                              icon: callState.isMicMuted ? Icons.mic_off : Icons.mic,
                              color: callState.isMicMuted ? Colors.white : Colors.white24,
                              iconColor: callState.isMicMuted ? Colors.black : Colors.white,
                              onTap: () => callNotifier.toggleMute(),
                            ),
                            _buildControlBtn(
                              icon: Icons.call_end,
                              color: Colors.redAccent,
                              iconColor: Colors.white,
                              onTap: () => callNotifier.endCall(),
                              size: 64,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedAvatar(String? callerAvatar, bool isConnecting) {
    Widget avatarChild = callerAvatar != null && callerAvatar.isNotEmpty
        ? CircleAvatar(
            radius: 70,
            backgroundImage: NetworkImage(callerAvatar),
            backgroundColor: Colors.white24,
          )
        : const CircleAvatar(
            radius: 70,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 70, color: Colors.white),
          );

    if (!isConnecting) {
      return avatarChild;
    }
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.2 * (1.2 - value)),
                blurRadius: 30 * value,
                spreadRadius: 10 * value,
              )
            ],
          ),
          child: Transform.scale(
            scale: value < 1.0 ? value : 2.0 - value, // Simple pulse
            child: avatarChild,
          ),
        );
      },
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required Color color,
    Color iconColor = Colors.white,
    required VoidCallback onTap,
    double size = 56,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            )
          ],
        ),
        child: Icon(icon, color: iconColor, size: size * 0.45),
      ),
    );
  }
}
