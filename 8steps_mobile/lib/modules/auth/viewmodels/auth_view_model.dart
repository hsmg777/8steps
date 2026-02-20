import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/models/app_subscription.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.subscription,
    this.errorMessage,
    this.loading = false,
  });

  const AuthState.unknown()
      : status = AuthStatus.unknown,
        user = null,
        subscription = null,
        errorMessage = null,
        loading = true;

  final AuthStatus status;
  final AppUser? user;
  final AppSubscription? subscription;
  final String? errorMessage;
  final bool loading;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    AppSubscription? subscription,
    String? errorMessage,
    bool clearError = false,
    bool? loading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      subscription: subscription ?? this.subscription,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      loading: loading ?? this.loading,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel(this._repo) : super(const AuthState.unknown()) {
    unawaited(onInit());
  }

  final AuthRepository _repo;

  Future<void> onInit() async {
    state = state.copyWith(loading: true, clearError: true);

    final token = await _repo.getAccessToken();
    if (token == null || token.isEmpty) {
      state =
          const AuthState(status: AuthStatus.unauthenticated, loading: false);
      return;
    }

    try {
      final subscription = await _repo.getSubscription();
      final user = await _repo.getStoredUser();

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        subscription: subscription,
        loading: false,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _repo.clearSession();
      }
      state = AuthState(
        status: AuthStatus.unauthenticated,
        loading: false,
        errorMessage: _mapErrorMessage(e),
      );
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        loading: false,
        errorMessage: 'No se pudo conectar',
      );
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      await _repo.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      return await login(email, password);
    } on DioException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        loading: false,
        errorMessage: _mapErrorMessage(e, isRegister: true),
      );
      return false;
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        loading: false,
        errorMessage: 'No se pudo conectar',
      );
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final session = await _repo.login(email: email, password: password);
      await _repo.saveSession(session);
      final subscription = await _repo.getSubscription();

      state = AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
        subscription: subscription,
        loading: false,
      );
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _repo.clearSession();
      }
      state = AuthState(
        status: AuthStatus.unauthenticated,
        loading: false,
        errorMessage: _mapErrorMessage(e),
      );
      return false;
    } on FormatException {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        loading: false,
        errorMessage: 'Respuesta inválida del servidor',
      );
      return false;
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        loading: false,
        errorMessage: 'No se pudo conectar',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated, loading: false);
  }

  Future<void> handleUnauthorized() async {
    await _repo.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated, loading: false);
  }

  String _mapErrorMessage(DioException e, {bool isRegister = false}) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return 'No se pudo conectar';
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;
    final apiMessage =
        data is Map<String, dynamic> ? data['message'] as String? : null;
    final rawMessage = data is String ? data : null;

    if (isRegister && status == 400) {
      return apiMessage ?? 'El email ya existe';
    }

    if (status == 401) {
      return 'Credenciales inválidas';
    }

    if (status == 400) {
      return apiMessage ?? 'Datos inválidos';
    }

    if (apiMessage != null && apiMessage.isNotEmpty) {
      return apiMessage;
    }
    if (rawMessage != null && rawMessage.isNotEmpty) {
      if (rawMessage.contains('<!DOCTYPE html') ||
          rawMessage.contains('<html')) {
        return 'La app recibió HTML en vez de JSON. Revisa base URL y endpoint.';
      }
      return rawMessage;
    }
    if (status != null) {
      return 'Error del servidor (HTTP $status)';
    }

    return 'Ocurrió un error';
  }
}
