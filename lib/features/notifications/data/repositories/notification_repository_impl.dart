import 'package:firebase_database/firebase_database.dart';
import 'package:hydroflow/features/notifications/domain/entities/notification_entity.dart';
import 'package:hydroflow/features/notifications/domain/repositories/notification_repository.dart';
import 'package:hydroflow/features/notifications/data/models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseDatabase _database;

  NotificationRepositoryImpl({required FirebaseDatabase database}) : _database = database;

  @override
  Stream<List<NotificationEntity>> getNotifications(String uid) {
    return _database.ref().child('Notifications').child(uid).onValue.map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final List<NotificationEntity> notifications = [];
        data.forEach((key, value) {
          final map = Map<String, dynamic>.from(value as Map);
          notifications.add(NotificationModel.fromMap(map, key as String));
        });
        
        // Sort by timestamp desc
        notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return notifications;
      }
      return [];
    });
  }

  @override
  Future<void> markAsRead(String uid, String notificationId) async {
    await _database
        .ref()
        .child('Notifications')
        .child(uid)
        .child(notificationId)
        .update({'isRead': true});
  }

  @override
  Future<void> markAllAsRead(String uid) async {
    final snapshot = await _database.ref().child('Notifications').child(uid).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final Map<String, dynamic> updates = {};
      data.forEach((key, value) {
        updates['$key/isRead'] = true;
      });
      await _database.ref().child('Notifications').child(uid).update(updates);
    }
  }
}
