import 'package:hydroflow/features/notifications/domain/repositories/notification_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationRepository _repository;

  MarkNotificationReadUseCase(this._repository);

  Future<void> call(String uid, String notificationId) {
    return _repository.markAsRead(uid, notificationId);
  }
}
