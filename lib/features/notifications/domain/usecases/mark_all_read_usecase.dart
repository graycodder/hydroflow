import 'package:hydroflow/features/notifications/domain/repositories/notification_repository.dart';

class MarkAllReadUseCase {
  final NotificationRepository _repository;

  MarkAllReadUseCase(this._repository);

  Future<void> call(String uid) {
    return _repository.markAllAsRead(uid);
  }
}
