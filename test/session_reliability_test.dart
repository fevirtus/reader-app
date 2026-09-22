import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reader_app/core/network/api_client.dart';
import 'package:reader_app/core/network/providers.dart';
import 'package:reader_app/features/auth/providers/auth_provider.dart';
import 'offline_sync_test.dart' show MemorySecrets, FakeHttp, jsonResponse;
import 'browse_reliability_test.dart' show BrokenSecrets;

class DelayedProfileStore extends MemorySecrets {
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<void> setProfile(String value) async {
    started.complete();
    await release.future;
    profile = value;
  }
}

void main() {
  test(
    'logout waits for an in-flight profile write and leaves no stale session',
    () async {
      final secrets = DelayedProfileStore();
      final api = ApiClient(
        baseUrl: 'https://test.invalid',
        secureStore: secrets,
      );
      api.dio.httpClientAdapter = FakeHttp(
        (_) async => jsonResponse({'id': 'A', 'email': 'a@example.com'}),
      );
      final container = ProviderContainer(
        overrides: [
          secureStoreProvider.overrideWithValue(secrets),
          apiClientProvider.overrideWithValue(api),
        ],
      );
      addTearDown(() {
        container.dispose();
        api.dio.close();
      });
      final auth = container.read(authProvider.notifier);
      await secrets.started.future;
      final expired = auth.handleSessionExpired();
      secrets.release.complete();
      await expired;
      expect(secrets.token, isNull);
      expect(secrets.profile, isNull);
      expect(container.read(authProvider), isA<AuthUnauthenticated>());
    },
  );

  test(
    'secure storage failure does not leave login stuck on startup',
    () async {
      final container = ProviderContainer(
        overrides: [secureStoreProvider.overrideWithValue(BrokenSecrets())],
      );
      addTearDown(container.dispose);
      final settled = Completer<AuthState>();
      container.listen(authProvider, (_, state) {
        if (state is! AuthInitial) settled.complete(state);
      });
      expect(
        await settled.future.timeout(const Duration(seconds: 2)),
        isA<AuthError>(),
      );
    },
  );
}
