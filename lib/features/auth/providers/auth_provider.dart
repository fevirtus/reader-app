import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/providers.dart';
import '../../../core/storage/secure_store.dart';

// ─── State ────────────────────────────────────────────────────────────────────

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  AuthAuthenticated(this.user);
  final UserModel user;
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  AuthError(this.message);
  final String message;
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(AuthInitial()) {
    _restore();
  }

  final Ref _ref;
  int _generation = 0;
  Future<void> _storageWrites = Future.value();

  Future<void> _persist(Future<void> Function(SecureStore) write) {
    final store = _store;
    final task = _storageWrites.then((_) => write(store));
    _storageWrites = task.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return task;
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  SecureStore get _store => _ref.read(secureStoreProvider);

  GoogleSignIn get _googleSignIn => GoogleSignIn(
    // clientId should be set for iOS/web only. Android reads from google-services.json.
    clientId: (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? null
        : (AppConfig.googleClientId.isNotEmpty
              ? AppConfig.googleClientId
              : null),
    // ID token for backend verification typically requires a Web OAuth client id.
    serverClientId: AppConfig.googleServerClientId.isNotEmpty
        ? AppConfig.googleServerClientId
        : (AppConfig.googleClientId.isNotEmpty
              ? AppConfig.googleClientId
              : null),
    scopes: ['email', 'profile'],
  );

  void _logGoogleSignInConfig() {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    debugPrint(
      '[AUTH][GOOGLE][CONFIG] platform=${isAndroid ? 'android' : (kIsWeb ? 'web' : defaultTargetPlatform.name)} '
      'clientId=${isAndroid ? '<android-default>' : (AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : '<empty>')} '
      'serverClientId=${AppConfig.googleServerClientId.isNotEmpty ? AppConfig.googleServerClientId : (AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : '<empty>')}',
    );
  }

  Future<void> _restore() async {
    final generation = _generation;
    try {
      final token = await _store.getAccessToken();
      if (generation != _generation) return;
      if (token != null && token.isNotEmpty) {
        final cached = await _store.getProfile();
        if (cached != null) {
          try {
            final snapshot = jsonDecode(cached);
            if (generation == _generation && snapshot['token'] == token) {
              state = AuthAuthenticated(UserModel.fromJson(snapshot['user']));
            }
          } catch (_) {}
        }
        if (generation == _generation) await _fetchProfile();
      } else {
        state = AuthUnauthenticated();
      }
    } catch (_) {
      if (generation == _generation && state is! AuthAuthenticated) {
        state = AuthError('Chưa đọc được phiên đăng nhập. Vui lòng thử lại.');
      }
    }
  }

  Future<void> _fetchProfile() async {
    final generation = _generation;
    String? token;
    try {
      token = await _store.getAccessToken();
      final res = await _ref
          .read(apiClientProvider)
          .dio
          .get('/api/user/profile');
      if (generation != _generation || token != await _store.getAccessToken()) {
        return;
      }
      final user = UserModel.fromJson(res.data as Map<String, dynamic>);
      await _persist((store) async {
        if (generation == _generation) {
          await store.setProfile(
            jsonEncode({'token': token, 'user': user.toJson()}),
          );
        }
      });
      if (generation == _generation) state = AuthAuthenticated(user);
    } on DioException catch (e) {
      if (generation != _generation) return;
      try {
        if (token != await _store.getAccessToken()) return;
      } catch (_) {
        return;
      }
      if (generation != _generation) return;
      if (e.response?.statusCode == 401) {
        await _persist((store) async {
          if (generation == _generation) await store.clear();
        });
        if (generation == _generation) state = AuthUnauthenticated();
      } else if (state is! AuthAuthenticated) {
        // Preserve credentials during transport/server failures.
        state = AuthUnauthenticated();
      }
    } catch (_) {
      // A malformed profile response must not discard an offline session.
      if (generation == _generation && state is! AuthAuthenticated) {
        state = AuthUnauthenticated();
      }
    }
  }

  Future<void> refreshSession() async {
    if (state is AuthUnauthenticated || state is AuthInitial) await _restore();
  }

  Future<void> signInWithGoogle() async {
    final generation = ++_generation;
    try {
      state = AuthLoading();
      _logGoogleSignInConfig();
      final account = await _googleSignIn.signIn();
      if (generation != _generation) return;
      if (account == null) {
        state = AuthUnauthenticated();
        return;
      }

      final auth = await account.authentication;
      if (generation != _generation) return;
      final idToken = auth.idToken;
      if (idToken == null) {
        state = AuthError('Could not get ID token from Google');
        return;
      }

      final dio = _ref.read(apiClientProvider).dio;
      final res = await dio.post(
        '/api/auth/mobile-login',
        data: {'googleIdToken': idToken},
      );

      final data = res.data as Map<String, dynamic>;
      if (generation != _generation) return;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _persist((store) async {
        if (generation != _generation) return;
        await store.setAccessToken(data['accessToken'] as String);
        if (data['refreshToken'] != null) {
          await store.setRefreshToken(data['refreshToken'] as String);
        }
        await store.setProfile(
          jsonEncode({'token': data['accessToken'], 'user': user.toJson()}),
        );
      });
      if (generation == _generation) state = AuthAuthenticated(user);
    } on PlatformException catch (e, st) {
      if (generation != _generation) return;
      debugPrint(
        '[AUTH][GOOGLE][ERROR] code=${e.code} message=${e.message} details=${e.details}',
      );
      debugPrintStack(stackTrace: st);
      final raw = '${e.code} ${e.message ?? ''} ${e.details ?? ''}'
          .toLowerCase();
      if (raw.contains('10') || raw.contains('developer_error')) {
        state = AuthError(
          'Google Sign-In lỗi cấu hình (code 10). Cần kiểm tra package name, SHA-1/SHA-256 và google-services.json cho Android.',
        );
      } else {
        state = AuthError('Google Sign-In thất bại: ${e.message ?? e.code}');
      }
    } on DioException catch (e, st) {
      if (generation != _generation) return;
      debugPrint('[AUTH][API][ERROR] type=${e.type} message=${e.message}');
      if (e.response != null) {
        debugPrint(
          '[AUTH][API][ERROR] status=${e.response?.statusCode} data=${e.response?.data}',
        );
      }
      debugPrintStack(stackTrace: st);
      final body = e.response?.data;
      final msg =
          (body is Map ? body['error'] : null) ?? e.message ?? 'Login failed';
      state = AuthError(msg.toString());
    } catch (e, st) {
      if (generation != _generation) return;
      debugPrint('[AUTH][UNEXPECTED][ERROR] $e');
      debugPrintStack(stackTrace: st);
      state = AuthError(e.toString());
    }
  }

  Future<void> signOut() async {
    ++_generation;
    state = AuthUnauthenticated();
    await _persist((store) => store.clear());
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<void> handleSessionExpired() async {
    ++_generation;
    state = AuthUnauthenticated();
    await _persist((store) => store.clear());
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

// Conveniences
final currentUserProvider = Provider<UserModel?>((ref) {
  final s = ref.watch(authProvider);
  return s is AuthAuthenticated ? s.user : null;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AuthAuthenticated;
});
