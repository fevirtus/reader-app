import 'package:dio/dio.dart';

import '../storage/secure_store.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required SecureStore secureStore,
  })  : _secureStore = secureStore,
        dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            headers: const {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStore.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
  final SecureStore _secureStore;
}
