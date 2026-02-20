import '../../../services/profile/profile_service.dart';
import '../models/app_subscription.dart';
import 'profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._service);

  final ProfileService _service;

  @override
  Future<AppSubscription> getSubscription() => _service.meSubscription();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _service.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
