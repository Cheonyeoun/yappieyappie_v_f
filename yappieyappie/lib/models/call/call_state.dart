import 'package:livekit_client/livekit_client.dart';

enum CallStatus {
  idle,
  dialing,
  ringing,
  connected,
  ended,
  failed,
}

class CallState {
  final Room? room;
  final CallStatus status;
  final bool isMinimized;
  final String roomName;
  final String remoteName;
  final String? remoteUid;
  final String? remoteAvatar;
  final bool isMicMuted;
  final bool isSpeakerOn;
  final String? callId;
  final DateTime? startTime;

  bool get isActive => status != CallStatus.idle && status != CallStatus.ended && status != CallStatus.failed;
  bool get isConnecting => status == CallStatus.dialing || status == CallStatus.ringing;

  const CallState({
    this.room,
    this.status = CallStatus.idle,
    this.isMinimized = false,
    this.roomName = '',
    this.remoteName = '',
    this.remoteUid,
    this.remoteAvatar,
    this.isMicMuted = false,
    this.isSpeakerOn = false,
    this.callId,
    this.startTime,
  });

  CallState copyWith({
    Room? room,
    CallStatus? status,
    bool? isMinimized,
    String? roomName,
    String? remoteName,
    String? remoteUid,
    String? remoteAvatar,
    bool? isMicMuted,
    bool? isSpeakerOn,
    String? callId,
    DateTime? startTime,
  }) {
    return CallState(
      room: room ?? this.room,
      status: status ?? this.status,
      isMinimized: isMinimized ?? this.isMinimized,
      roomName: roomName ?? this.roomName,
      remoteName: remoteName ?? this.remoteName,
      remoteUid: remoteUid ?? this.remoteUid,
      remoteAvatar: remoteAvatar ?? this.remoteAvatar,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      callId: callId ?? this.callId,
      startTime: startTime ?? this.startTime,
    );
  }
}
