import 'package:hydroflow/features/notifications/domain/entities/notification_entity.dart';
import 'package:hydroflow/features/notifications/domain/repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository _repository;

  GetNotificationsUseCase(this._repository);

  Stream<List<NotificationEntity>> call(String uid) {
    return _repository.getNotifications(uid);
  }
}
