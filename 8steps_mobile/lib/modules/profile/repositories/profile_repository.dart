import '../models/app_subscription.dart';

abstract class ProfileRepository {
  Future<AppSubscription> getSubscription();
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
