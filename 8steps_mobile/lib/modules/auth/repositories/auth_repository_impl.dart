import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../features/auth/data/auth_storage_keys.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/profile/profile_service.dart';
import '../../profile/models/app_subscription.dart';
import '../models/app_user.dart';
import '../models/auth_session.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthService authService,
    required ProfileService profileService,
    required FlutterSecureStorage storage,
  })  : _authService = authService,
        _profileService = profileService,
        _storage = storage;

  final AuthService _authService;
  final ProfileService _profileService;
  final FlutterSecureStorage _storage;

  @override
  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) {
    return _authService.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthSession> login({required String email, required String password}) {
    return _authService.login(email: email, password: password);
  }

  @override
  Future<void> logout() async {
    try {
      await _authService.logout();
    } finally {
      await clearSession();
    }
  }

  @override
  Future<AppSubscription> getSubscription() => _profileService.meSubscription();

  @override
  Future<void> saveSession(AuthSession session) async {
    await _storage.write(
        key: AuthStorageKeys.accessToken, value: session.accessToken);
    await _storage.write(
        key: AuthStorageKeys.refreshToken, value: session.refreshToken);
    await _storage.write(key: AuthStorageKeys.userId, value: session.user.id);
    await _storage.write(
        key: AuthStorageKeys.userEmail, value: session.user.email);
    await _storage.write(key: AuthStorageKeys.userRole, value: session.user.role);
    await _storage.write(
      key: AuthStorageKeys.userFirstName,
      value: session.user.firstName,
    );
    await _storage.write(
      key: AuthStorageKeys.userLastName,
      value: session.user.lastName,
    );
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: AuthStorageKeys.accessToken);
    await _storage.delete(key: AuthStorageKeys.refreshToken);
    await _storage.delete(key: AuthStorageKeys.userId);
    await _storage.delete(key: AuthStorageKeys.userEmail);
    await _storage.delete(key: AuthStorageKeys.userRole);
    await _storage.delete(key: AuthStorageKeys.userFirstName);
    await _storage.delete(key: AuthStorageKeys.userLastName);
  }

  @override
  Future<String?> getAccessToken() =>
      _storage.read(key: AuthStorageKeys.accessToken);

  @override
  Future<AppUser?> getStoredUser() async {
    final id = await _storage.read(key: AuthStorageKeys.userId);
    final email = await _storage.read(key: AuthStorageKeys.userEmail);
    final role = await _storage.read(key: AuthStorageKeys.userRole);
    final firstName = await _storage.read(key: AuthStorageKeys.userFirstName);
    final lastName = await _storage.read(key: AuthStorageKeys.userLastName);

    if (id == null || email == null || role == null) return null;
    return AppUser(
      id: id,
      email: email,
      role: role,
      firstName: firstName,
      lastName: lastName,
    );
  }
}
