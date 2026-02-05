import 'package:hydroflow/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  Stream<List<NotificationEntity>> getNotifications(String uid);
  Future<void> markAsRead(String uid, String notificationId);
  Future<void> markAllAsRead(String uid);
}
