import 'package:flutter/material.dart';

import 'package:hydroflow/features/notifications/domain/entities/notification_entity.dart';
import 'package:intl/intl.dart';

class NotificationItem extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback? onRead;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onRead,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case 'success': return Icons.check;
      case 'warning': return Icons.error_outline;
      case 'error': return Icons.error_outline;
      default: return Icons.info_outline;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case 'success': return const Color(0xFF2E7D32);
      case 'warning': return const Color(0xFFE65100);
      case 'error': return const Color(0xFFC62828);
      default: return const Color(0xFF1565C0);
    }
  }

  Color _getBgColor() {
    switch (notification.type) {
      case 'success': return const Color(0xFFE8F5E9);
      case 'warning': return const Color(0xFFFFF3E0);
      case 'error': return const Color(0xFFFFEBEE);
      default: return const Color(0xFFE3F2FD);
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('dd MMM').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getColor();
    final iconBgColor = _getBgColor();
    final icon = _getIcon();

    return GestureDetector(
      onTap: onRead,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFF1F5F9), 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
                border: Border.all(color: iconColor, width: 1.5),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2962FF), // Blue dot
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(notification.timestamp),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
