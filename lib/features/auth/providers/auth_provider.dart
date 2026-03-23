import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null,
    scopes: ['email', 'profile'],
  );

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
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error'] ?? e.message ?? 'Login failed';
      state = AuthError(msg.toString());
    } catch (e) {
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
