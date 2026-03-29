import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yappieyappie/models/profile/user_model.dart';
import 'package:yappieyappie/services/profile/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

// Stream provider for a single user (used in chat, profile, etc.)
final userStreamProvider = StreamProvider.family<UserModel, String>((ref, uid) {
  final userService = ref.read(userServiceProvider);
  return userService.getUserStream(uid);
});
