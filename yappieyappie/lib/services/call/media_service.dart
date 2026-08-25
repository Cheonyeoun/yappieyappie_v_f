import 'package:livekit_client/livekit_client.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MediaService {
  static final MediaService instance = MediaService._internal();

  final AudioPlayer _ringPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  Room? _currentRoom;

  MediaService._internal() {
    _ringPlayer.setReleaseMode(ReleaseMode.loop);

    final audioContext = AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playAndRecord,
        options: const {
          AVAudioSessionOptions.allowBluetooth,
        },
      ),
    );
    AudioPlayer.global.setAudioContext(audioContext);
    
    // Preload audio sources to avoid MediaPlayer state errors (-38)
    _ringPlayer.setSourceAsset('audio/ringing.mp3');
    _sfxPlayer.setSourceAsset('audio/disconnected.mp3');
  }

  /// Connects to a LiveKit room
  Future<Room?> connectToLiveKit({
    required String roomName,
    required String token,
  }) async {
    final url = dotenv.env['LIVEKIT_URL'];
    if (url == null) throw Exception('LIVEKIT_URL is missing in .env');

    final roomOptions = const RoomOptions(
      adaptiveStream: true,
      dynacast: true,
    );

    try {
      final room = Room();
      _currentRoom = room;

      await room.connect(
        url,
        token,
        roomOptions: roomOptions,
        fastConnectOptions: FastConnectOptions(
          microphone: TrackOption(
            enabled: true,
          ),
        ),
      );

      await room.localParticipant?.setMicrophoneEnabled(true);
      
      // Default to earpiece initially
      await Hardware.instance.setSpeakerphoneOn(false);
      
      return room;
    } catch (e) {
      debugPrint("MediaService: Failed to connect to LiveKit - $e");
      return null;
    }
  }

  /// Plays the dialing ringtone
  Future<void> playRingtone() async {
    try {
      await _ringPlayer.seek(Duration.zero);
      await _ringPlayer.resume();
    } catch (e) {
      debugPrint("MediaService: Ringtone failed to play - $e");
    }
  }

  /// Stops any currently playing ringtone
  Future<void> stopRingtone() async {
    try {
      await _ringPlayer.stop();
    } catch (e) {
      debugPrint("MediaService: Failed to stop ringtone - $e");
    }
  }

  /// Plays the disconnect SFX
  Future<void> playDisconnectSfx() async {
    try {
      await _sfxPlayer.seek(Duration.zero);
      await _sfxPlayer.resume();
    } catch (e) {
      debugPrint("MediaService: SFX failed to play - $e");
    }
  }

  /// Play blink SFX (connected)
  Future<void> playConnectedSfx() async {
    try {
      // For connected_blink, we can just play it directly as it's a one-off SFX
      // If we preloaded disconnected, we need to temporarily set this source
      await _sfxPlayer.play(AssetSource('audio/connected_blink.mp3'));
    } catch (e) {
      debugPrint("MediaService: Connected SFX failed to play - $e");
    }
  }

  Future<bool> toggleMicrophone(bool currentIsMuted) async {
    if (_currentRoom?.localParticipant != null) {
      final newIsMuted = !currentIsMuted;
      await _currentRoom!.localParticipant!.setMicrophoneEnabled(!newIsMuted);
      return newIsMuted;
    }
    return currentIsMuted;
  }

  /// Toggles the hardware speaker
  Future<bool> toggleSpeaker(bool isSpeakerOn) async {
    await Hardware.instance.setSpeakerphoneOn(isSpeakerOn);
    return isSpeakerOn;
  }

  /// Cleans up media resources
  Future<void> cleanup() async {
    await stopRingtone();
    await _currentRoom?.disconnect();
    _currentRoom = null;
  }
}
