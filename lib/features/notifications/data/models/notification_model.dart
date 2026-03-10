import 'package:firebase_database/firebase_database.dart';
import 'package:watermemo/features/notifications/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.description,
    required super.timestamp,
    required super.type,
    super.isRead,
  });

  factory NotificationModel.fromSnapshot(DataSnapshot snapshot) {
    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    return NotificationModel(
      id: snapshot.key ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? data['body'] ?? '',
      timestamp: _parseTimestamp(data['timestamp']),
      type: data['type'] ?? 'info',
      isRead: data['isRead'] ?? false,
    );
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? map['body'] ?? '',
      timestamp: _parseTimestamp(map['timestamp']),
      type: map['type'] ?? 'info',
      isRead: map['isRead'] ?? false,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
      'isRead': isRead,
    };
  }
}
