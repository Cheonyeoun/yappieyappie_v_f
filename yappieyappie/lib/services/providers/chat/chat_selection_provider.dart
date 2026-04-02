import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stores selected message IDs
final selectedMessagesProvider =
    NotifierProvider<SelectedMessagesNotifier, Set<String>>(
        SelectedMessagesNotifier.new);

class SelectedMessagesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void add(String msgId) {
    state = <String>{...state, msgId};
  }

  void remove(String msgId) {
    state = <String>{...state}..remove(msgId);
  }

  void clear() {
    state = <String>{};
  }
}

// Whether selection mode is active
final isSelectionModeProvider = NotifierProvider<IsSelectionModeNotifier, bool>(
    IsSelectionModeNotifier.new);

class IsSelectionModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setValue(bool value) {
    state = value;
  }

  void toggle() {
    state = !state;
  }
}
