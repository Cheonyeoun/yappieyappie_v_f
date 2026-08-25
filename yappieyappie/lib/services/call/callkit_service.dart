import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';
import 'package:yappieyappie/core/globals/app_globals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yappieyappie/services/call/signaling_service.dart';
import 'package:yappieyappie/services/router/app_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/controllers/call/call_controller.dart';
import 'package:yappieyappie/features/call/presentation/livekit_call_screen.dart';

class CallKitService {
  static final CallKitService instance = CallKitService._internal();

  CallKitService._internal();

  Future<void> init(ProviderContainer container) async {
    _checkActiveCallsOnBoot(container);

    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;

      if (event is CallEventActionCallAccept) {
        try {
          final extra = event.callKitParams.extra ?? {};
          final roomName = extra['roomName']?.toString();
          final callerId = extra['callerId']?.toString();
          final callerName = extra['callerName']?.toString();
          final callerAvatar = extra['callerAvatar']?.toString();
          final callId = extra['callId']?.toString();
          
          if (roomName != null && callerId != null && roomName.isNotEmpty) {
            final callState = container.read(callControllerProvider);
            if (callState.isActive) {
              if (callId != null) {
                FlutterCallkitIncoming.endCall(callId);
              }
            } else {
              container.read(callControllerProvider.notifier).answerCall(
                roomName: roomName,
                callerName: callerName ?? 'Unknown',
                callerId: callerId,
                callerAvatar: callerAvatar,
                callId: callId,
              );
              container.read(callControllerProvider.notifier).maximizeCall();
            }
          } else {
            debugPrint("CallKitService: Failed to extract roomName. Aborting incoming call.");
            if (callId != null) {
               FlutterCallkitIncoming.endCall(callId);
            } else {
               FlutterCallkitIncoming.endAllCalls();
            }
          }
        } catch (e) {
          debugPrint("CallKitService: Error parsing accept event - $e");
        }
      } else if (event is CallEventActionCallDecline) {
        debugPrint("CallKit: Declined call");
        final extra = event.callKitParams.extra ?? {};
        final callerId = extra['callerId']?.toString();
        final roomName = extra['roomName']?.toString();
        
        if (callerId != null && roomName != null && roomName.isNotEmpty) {
          final myUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
          SignalingService.instance.sendCallCancelledSignal(
            receiverId: callerId,
            callerId: myUid,
            roomName: roomName,
          );
        }
        container.read(callControllerProvider.notifier).endCall();
      } else if (event is CallEventActionCallTimeout) {
        debugPrint("CallKit: Missed call");
        container.read(callControllerProvider.notifier).endCall();
      } else if (event is CallEventActionCallEnded) {
        debugPrint("CallKit: Ended call");
        container.read(callControllerProvider.notifier).endCall();
      } else if (event is CallEventActionCallTimeout) {
        debugPrint("CallKit: Missed call");
        container.read(callControllerProvider.notifier).endCall();
      }
    });
  }

  /// Shows the native incoming call UI
  Future<void> showIncomingCall({
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required String roomName,
    required String callId,
  }) async {
    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'YappieYappie',
      avatar: callerAvatar,
      handle: 'Incoming Call',
      type: 0, // 0 for audio, 1 for video
      duration: 30000,
      extra: <String, dynamic>{
        'callerId': callerId,
        'callerName': callerName,
        'callerAvatar': callerAvatar,
        'roomName': roomName,
        'callId': callId,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#000000',
        backgroundUrl: 'https://i.pravatar.cc/500',
        actionColor: '#4CAF50',
      ),
      ios: const IOSParams(
        iconName: 'CallKitIcon',
        handleType: 'generic',
        supportsVideo: false,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  /// Start an outgoing call (Shows the outgoing UI on iOS)
  Future<String> startOutGoingCall(String callerName) async {
    final uuid = const Uuid().v4();
    final params = CallKitParams(
      id: uuid,
      nameCaller: callerName,
      handle: 'Calling...',
      type: 0,
      extra: <String, dynamic>{},
    );
    await FlutterCallkitIncoming.startCall(params);
    return uuid;
  }

  /// End the call natively
  Future<void> endCall(String callId) async {
    await FlutterCallkitIncoming.endCall(callId);
  }

  Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
  }

  Future<void> _checkActiveCallsOnBoot(ProviderContainer container) async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is List && calls.isNotEmpty) {
        for (var call in calls) {
          if (call.isAccepted == true) {
            final extra = call.extra ?? {};
            final roomName = extra['roomName']?.toString();
            final callerId = extra['callerId']?.toString();
            final callerName = extra['callerName']?.toString() ?? call.nameCaller;
            final callerAvatar = extra['callerAvatar']?.toString() ?? call.avatar;
            final callId = call.id?.toString();

            if (roomName != null && callerId != null && roomName.isNotEmpty) {
              final callState = container.read(callControllerProvider);
              if (!callState.isActive) {
                container.read(callControllerProvider.notifier).answerCall(
                  roomName: roomName,
                  callerName: callerName ?? 'Unknown',
                  callerId: callerId,
                  callerAvatar: callerAvatar,
                  callId: callId,
                );
                container.read(callControllerProvider.notifier).maximizeCall();
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("CallKitService: Error checking active calls on boot - $e");
    }
  }
}
