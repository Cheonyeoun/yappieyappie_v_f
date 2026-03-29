import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stores selected message IDs
final selectedMessagesProvider = StateProvider<Set<String>>((ref) => {});

// Whether selection mode is active
final isSelectionModeProvider = StateProvider<bool>((ref) => false);
