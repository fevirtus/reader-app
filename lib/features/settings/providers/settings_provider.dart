import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/reading_settings.dart';
import '../../../core/storage/local_store.dart';

class UserSettingsNotifier extends StateNotifier<AsyncValue<ReadingSettings>> {
  final Ref _ref;

  UserSettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final local = _ref.read(localStoreProvider);
    final saved = await local.loadReadingSettings();
    state = AsyncValue.data(saved ?? const ReadingSettings());
  }

  Future<void> updateSettings(ReadingSettings settings) async {
    state = AsyncValue.data(settings);
    final local = _ref.read(localStoreProvider);
    await local.saveReadingSettings(settings);
  }
}

final userSettingsProvider =
    StateNotifierProvider<UserSettingsNotifier, AsyncValue<ReadingSettings>>(
        (ref) => UserSettingsNotifier(ref));
