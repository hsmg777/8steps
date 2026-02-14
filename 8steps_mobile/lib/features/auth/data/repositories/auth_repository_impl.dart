import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth_storage_keys.dart';
import '../datasources/remote_auth_data_source.dart';
import '../../domain/auth_repository.dart';
import '../../domain/models/app_subscription.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/auth_session.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required RemoteAuthDataSource remote,
    required FlutterSecureStorage storage,
  })  : _remote = remote,
        _storage = storage;

  final RemoteAuthDataSource _remote;
  final FlutterSecureStorage _storage;

  @override
  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) {
    return _remote.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthSession> login({required String email, required String password}) {
    return _remote.login(email: email, password: password);
  }

  @override
  Future<AppSubscription> getSubscription() {
    return _remote.meSubscription();
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    await _storage.write(
        key: AuthStorageKeys.accessToken, value: session.accessToken);
    await _storage.write(
        key: AuthStorageKeys.refreshToken, value: session.refreshToken);
    await _storage.write(key: AuthStorageKeys.userId, value: session.user.id);
    await _storage.write(
        key: AuthStorageKeys.userEmail, value: session.user.email);
    await _storage.write(
        key: AuthStorageKeys.userRole, value: session.user.role);
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: AuthStorageKeys.accessToken);
    await _storage.delete(key: AuthStorageKeys.refreshToken);
    await _storage.delete(key: AuthStorageKeys.userId);
    await _storage.delete(key: AuthStorageKeys.userEmail);
    await _storage.delete(key: AuthStorageKeys.userRole);
  }

  @override
  Future<String?> getAccessToken() =>
      _storage.read(key: AuthStorageKeys.accessToken);

  @override
  Future<AppUser?> getStoredUser() async {
    final id = await _storage.read(key: AuthStorageKeys.userId);
    final email = await _storage.read(key: AuthStorageKeys.userEmail);
    final role = await _storage.read(key: AuthStorageKeys.userRole);

    if (id == null || email == null || role == null) return null;
    return AppUser(id: id, email: email, role: role);
  }
}
