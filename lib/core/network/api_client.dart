import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_store.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required SecureStore secureStore,
    this.onSessionExpired,
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
          debugPrint('[API] ${options.method} ${options.baseUrl}${options.path}');
          final token = await _secureStore.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '[API][OK] ${response.requestOptions.method} '
            '${response.requestOptions.baseUrl}${response.requestOptions.path} '
            '-> ${response.statusCode}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          final statusCode = error.response?.statusCode;
          final path = error.requestOptions.path;

          if ((statusCode == 401 || statusCode == 403) && !_isAuthEndpoint(path)) {
            _handleSessionExpired();
          }

          debugPrint(
            '[API][ERROR] ${error.requestOptions.method} ${error.requestOptions.baseUrl}${error.requestOptions.path} '
            '-> ${error.type}: ${error.message}',
          );
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final SecureStore _secureStore;
  final VoidCallback? onSessionExpired;
  DateTime? _lastSessionExpiredAt;

  bool _isAuthEndpoint(String path) {
    return path.contains('/api/auth/mobile-login');
  }

  void _handleSessionExpired() {
    final now = DateTime.now();
    if (_lastSessionExpiredAt != null &&
        now.difference(_lastSessionExpiredAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastSessionExpiredAt = now;
    _secureStore.clear();
    onSessionExpired?.call();
  }
}
