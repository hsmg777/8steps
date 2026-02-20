import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_subscription.dart';
import '../repositories/profile_repository.dart';

class ProfileState {
  const ProfileState({
    this.loading = false,
    this.subscription,
    this.errorMessage,
    this.successMessage,
  });

  final bool loading;
  final AppSubscription? subscription;
  final String? errorMessage;
  final String? successMessage;

  ProfileState copyWith({
    bool? loading,
    AppSubscription? subscription,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return ProfileState(
      loading: loading ?? this.loading,
      subscription: subscription ?? this.subscription,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ProfileViewModel extends StateNotifier<ProfileState> {
  ProfileViewModel(this._repo) : super(const ProfileState());

  final ProfileRepository _repo;

  Future<void> loadSubscription() async {
    state = state.copyWith(loading: true, clearMessages: true);
    try {
      final data = await _repo.getSubscription();
      state = ProfileState(loading: false, subscription: data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map<String, dynamic>
          ? (data['message'] as String? ?? 'No se pudo cargar suscripción')
          : 'No se pudo cargar suscripción';
      state = ProfileState(loading: false, errorMessage: msg);
    } catch (_) {
      state = const ProfileState(
        loading: false,
        errorMessage: 'No se pudo conectar',
      );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(loading: true, clearMessages: true);
    try {
      await _repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(
        loading: false,
        successMessage: 'Contraseña actualizada',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map<String, dynamic>
          ? (data['message'] as String? ?? 'No se pudo cambiar la contraseña')
          : 'No se pudo cambiar la contraseña';
      state = state.copyWith(loading: false, errorMessage: msg);
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'No se pudo conectar',
      );
    }
  }
}
