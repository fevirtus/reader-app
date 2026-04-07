import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionExpiryNotifier extends StateNotifier<int> {
  SessionExpiryNotifier() : super(0);

  void notifyExpired() {
    state = state + 1;
  }
}

final sessionExpiryProvider =
    StateNotifierProvider<SessionExpiryNotifier, int>((ref) {
  return SessionExpiryNotifier();
});
