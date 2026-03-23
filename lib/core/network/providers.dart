import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/secure_store.dart';
import 'api_client.dart';

final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStore = ref.watch(secureStoreProvider);
  return ApiClient(baseUrl: AppConfig.baseUrl, secureStore: secureStore);
});
