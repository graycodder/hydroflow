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
      case 'success':
        return Icons.check_circle_outline_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'error':
        return Icons.error_outline_rounded;
      case 'subscription_renewal':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case 'success':
        return const Color(0xFF10B981); // Emerald
      case 'warning':
        return const Color(0xFFF59E0B); // Amber
      case 'error':
        return const Color(0xFFEF4444); // Rose
      case 'subscription_renewal':
        return const Color(0xFF8B5CF6); // Violet
      default:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  Color _getBgColor() {
    switch (notification.type) {
      case 'success':
        return const Color(0xFFECFDF5);
      case 'warning':
        return const Color(0xFFFFFBEB);
      case 'error':
        return const Color(0xFFFEF2F2);
      case 'subscription_renewal':
        return const Color(0xFFF5F3FF);
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  String _formatType(String type) {
    return type
        .split('_')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd MMM, yyyy').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getColor();
    final iconBgColor = _getBgColor();
    final icon = _getIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRead,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification.isRead ? Colors.white : iconBgColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: notification.isRead 
                    ? Colors.grey.withOpacity(0.1) 
                    : iconColor.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                if (!notification.isRead)
                  BoxShadow(
                    color: iconColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatType(notification.type),
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          
                          // Time Label
                          Text(
                            _formatTime(notification.timestamp),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Title
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                          fontSize: 16,
                          color: notification.isRead ? Colors.black87 : Colors.black,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Description
                      Text(
                        notification.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      
                      if (!notification.isRead) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: iconColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'New',
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
