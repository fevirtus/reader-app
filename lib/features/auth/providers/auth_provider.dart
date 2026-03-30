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

  SecureStore get _store => _ref.read(secureStoreProvider);

  GoogleSignIn get _googleSignIn => GoogleSignIn(
        // clientId should be set for iOS/web only. Android reads from google-services.json.
        clientId: (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
            ? null
            : (AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null),
        // ID token for backend verification typically requires a Web OAuth client id.
        serverClientId: AppConfig.googleServerClientId.isNotEmpty
            ? AppConfig.googleServerClientId
            : (AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null),
        scopes: ['email', 'profile'],
      );

  void _logGoogleSignInConfig() {
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    debugPrint(
      '[AUTH][GOOGLE][CONFIG] platform=${isAndroid ? 'android' : (kIsWeb ? 'web' : defaultTargetPlatform.name)} '
      'clientId=${isAndroid ? '<android-default>' : (AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : '<empty>')} '
      'serverClientId=${AppConfig.googleServerClientId.isNotEmpty ? AppConfig.googleServerClientId : (AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : '<empty>')}',
    );
  }

  Future<void> _restore() async {
    final token = await _store.getAccessToken();
    if (token != null && token.isNotEmpty) {
      await _fetchProfile();
    } else {
      state = AuthUnauthenticated();
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final dio = _ref.read(apiClientProvider).dio;
      final res = await dio.get('/api/user/profile');
      state = AuthAuthenticated(UserModel.fromJson(res.data as Map<String, dynamic>));
    } catch (_) {
      await _store.clear();
      state = AuthUnauthenticated();
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      state = AuthLoading();
      _logGoogleSignInConfig();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        state = AuthUnauthenticated();
        return;
      }

      final auth = await account.authentication;
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
      await _store.setAccessToken(data['accessToken'] as String);
      if (data['refreshToken'] != null) {
        await _store.setRefreshToken(data['refreshToken'] as String);
      }

      state = AuthAuthenticated(
        UserModel.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on PlatformException catch (e, st) {
      debugPrint('[AUTH][GOOGLE][ERROR] code=${e.code} message=${e.message} details=${e.details}');
      debugPrintStack(stackTrace: st);
      final raw = '${e.code} ${e.message ?? ''} ${e.details ?? ''}'.toLowerCase();
      if (raw.contains('10') || raw.contains('developer_error')) {
        state = AuthError(
          'Google Sign-In lỗi cấu hình (code 10). Cần kiểm tra package name, SHA-1/SHA-256 và google-services.json cho Android.',
        );
      } else {
        state = AuthError('Google Sign-In thất bại: ${e.message ?? e.code}');
      }
    } on DioException catch (e, st) {
      debugPrint('[AUTH][API][ERROR] type=${e.type} message=${e.message}');
      if (e.response != null) {
        debugPrint('[AUTH][API][ERROR] status=${e.response?.statusCode} data=${e.response?.data}');
      }
      debugPrintStack(stackTrace: st);
      final msg = (e.response?.data as Map?)?['error'] ?? e.message ?? 'Login failed';
      state = AuthError(msg.toString());
    } catch (e, st) {
      debugPrint('[AUTH][UNEXPECTED][ERROR] $e');
      debugPrintStack(stackTrace: st);
      state = AuthError(e.toString());
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _store.clear();
    state = AuthUnauthenticated();
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
