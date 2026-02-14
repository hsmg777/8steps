import 'models/app_subscription.dart';
import 'models/app_user.dart';
import 'models/auth_session.dart';

abstract class AuthRepository {
  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });
  Future<AuthSession> login({required String email, required String password});
  Future<AppSubscription> getSubscription();

  Future<void> saveSession(AuthSession session);
  Future<void> clearSession();

  Future<String?> getAccessToken();
  Future<AppUser?> getStoredUser();
}
