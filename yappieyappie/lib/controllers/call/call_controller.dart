import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yappieyappie/models/call/call_state.dart';
import 'package:yappieyappie/services/call/media_service.dart';
import 'package:yappieyappie/services/call/signaling_service.dart';
import 'package:yappieyappie/services/call/callkit_service.dart';
import 'package:yappieyappie/services/chat/chat_service.dart' as yappieyappie_chat_service;

class CallController extends Notifier<CallState> {
  final ISignalingService _signalingService = SignalingService.instance;
  final MediaService _mediaService = MediaService.instance;
  final CallKitService _callKitService = CallKitService.instance;
  Timer? _dialingTimeoutTimer;

  @override
  CallState build() {
    return const CallState();
  }

  /// Initiates an outgoing call
  Future<void> initiateCall({
    required String receiverId,
    required String receiverName,
    required String? receiverAvatar,
    required String callerId,
    required String callerName,
  }) async {
    if (state.isActive) return;

    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      debugPrint("CallController: Microphone permission denied. Cannot initiate.");
      return;
    }

    final roomName = "room_${callerId}_$receiverId";
    
    // 1. Set State to Dialing synchronously so UI can push immediately
    state = state.copyWith(
      status: CallStatus.dialing,
      roomName: roomName,
      remoteName: receiverName.isNotEmpty ? receiverName : 'Unknown',
      remoteUid: receiverId,
      remoteAvatar: receiverAvatar,
      isMinimized: false,
      isMicMuted: false,
      isSpeakerOn: false,
      startTime: DateTime.now(),
    );

    // 2. Trigger Native UI (iOS outgoing) & capture ID
    final callId = await _callKitService.startOutGoingCall(
      receiverName.isNotEmpty ? receiverName : 'User',
    );
    
    state = state.copyWith(callId: callId);

    // 3. Play Dialing Ringtone & Connect to Room
    await _mediaService.playRingtone();
    final token = _signalingService.generateToken(
      roomName: roomName,
      participantName: callerName,
      participantIdentity: callerId,
    );
    
    final room = await _mediaService.connectToLiveKit(roomName: roomName, token: token);
    
    // 4. Send background push to wake receiver
    await _signalingService.sendCallSignal(
      receiverId: receiverId,
      callerId: callerId,
      callerName: callerName,
      callerAvatar: "",
      roomName: roomName,
      callId: callId,
    );
    
    // Start infinite dialing timeout
    _dialingTimeoutTimer?.cancel();
    _dialingTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (state.status == CallStatus.dialing) {
        debugPrint("CallController: Dialing timeout reached. Ending call.");
        endCall();
      }
    });

    // 5. Watch Room State
    if (room != null) {
      state = state.copyWith(room: room);
      
      room.addListener(() {
        if (room.remoteParticipants.isNotEmpty && state.status == CallStatus.dialing) {
          // Receiver joined
          _mediaService.stopRingtone();
          _mediaService.playConnectedSfx();
          state = state.copyWith(status: CallStatus.connected);
        }
        
        if (room.remoteParticipants.isEmpty && state.status == CallStatus.connected) {
          // Receiver left
          endCall();
        }
      });
    } else {
      debugPrint("CallController: Failed to connect to LiveKit room. Ending call.");
      endCall();
    }
  }

  /// Receives an incoming call
  Future<void> answerCall({
    required String roomName,
    required String callerName,
    required String callerId,
    String? callerAvatar,
    String? callId,
  }) async {
    if (state.isActive) return;

    state = state.copyWith(
      status: CallStatus.ringing,
      roomName: roomName,
      remoteName: callerName,
      remoteUid: callerId,
      remoteAvatar: callerAvatar,
      callId: callId,
      isMinimized: false,
      isMicMuted: false,
      isSpeakerOn: false,
      startTime: DateTime.now(),
    );

    var micStatus = await Permission.microphone.status;
    if (micStatus != PermissionStatus.granted) {
      // Activity might not be fully attached yet on cold boot. Wait a moment.
      await Future.delayed(const Duration(milliseconds: 1000));
      micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        debugPrint("CallController: Microphone permission denied. Cannot answer.");
        endCall();
        return;
      }
    }

    // Current user's name would ideally come from UserProvider, but since we are answering,
    // LiveKit participantName can just be 'Me' or fetched if needed.
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
    final token = _signalingService.generateToken(
      roomName: roomName,
      participantName: 'Receiver',
      participantIdentity: myUid, 
    );

    final room = await _mediaService.connectToLiveKit(roomName: roomName, token: token);
    
    if (room != null) {
      state = state.copyWith(room: room, status: CallStatus.connected);
      _mediaService.playConnectedSfx();
      
      room.addListener(() {
        if (room.remoteParticipants.isEmpty && state.status == CallStatus.connected) {
          endCall();
        }
      });
    } else {
      debugPrint("CallController: Failed to connect to LiveKit room during answer. Ending call.");
      endCall();
    }
  }

  void minimizeCall() {
    if (state.isActive) state = state.copyWith(isMinimized: true);
  }

  void maximizeCall() {
    if (state.isActive) state = state.copyWith(isMinimized: false);
  }

  Future<void> toggleMute() async {
    final newMuteState = await _mediaService.toggleMicrophone(state.isMicMuted);
    state = state.copyWith(isMicMuted: newMuteState);
  }

  Future<void> toggleSpeaker() async {
    final newSpeakerState = await _mediaService.toggleSpeaker(!state.isSpeakerOn);
    state = state.copyWith(isSpeakerOn: newSpeakerState);
  }

  Future<void> endCall() async {
    _dialingTimeoutTimer?.cancel();
    if (!state.isActive) return;
    
    final wasMissed = state.status == CallStatus.dialing || state.status == CallStatus.ringing;
    final callId = state.callId;
    final otherUid = state.remoteUid;
    final roomName = state.roomName;
    final startTime = state.startTime;
    
    // Update state to ended immediately for UI responsiveness
    state = state.copyWith(status: CallStatus.ended);
    
    await _mediaService.playDisconnectSfx();
    await _mediaService.cleanup();
    
    if (callId != null) {
      await _callKitService.endCall(callId);
    }
    await _callKitService.endAllCalls();

    if (otherUid != null && startTime != null && roomName.isNotEmpty) {
      final durationSeconds = DateTime.now().difference(startTime).inSeconds;
      final statusString = wasMissed ? 'missed' : 'completed';
      
      try {
        final parts = roomName.split('_');
        if (parts.length == 3) {
          final initiatorId = parts[1];

          // Send cancel signal to the OTHER person so their phone stops ringing
          if (wasMissed) {
             await _signalingService.sendCallCancelledSignal(
              receiverId: otherUid,
              callerId: initiatorId,
              roomName: roomName,
            );
          }
          
          // Log to chat
          final chatService = yappieyappie_chat_service.ChatService();
          await chatService.sendCallMessage(
            otherUid, 
            status: statusString,
            duration: durationSeconds,
          );
        }
      } catch (e) {
        debugPrint("CallController: Failed to finalize call logic - $e");
      }
    }
    
    // Reset state completely
    state = const CallState();
  }
}

final callControllerProvider = NotifierProvider<CallController, CallState>(CallController.new);
