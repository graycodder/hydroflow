import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hydroflow/features/notifications/presentation/widgets/notification_item.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Hide default back button
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Stay updated with your subscription and system alerts',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Mark all as read',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                NotificationItem(
                  title: 'Subscription Expiring Soon',
                  description: 'Your subscription expires in 2 days. Please contact admin to renew.',
                  time: '1h ago',
                  icon: Icons.error_outline,
                  iconColor: Color(0xFFE65100), // Orange
                  iconBgColor: Color(0xFFFFF3E0), // Light Orange
                  isUnread: true,
                ),
                SizedBox(height: 16),
                NotificationItem(
                  title: 'Payment Confirmed',
                  description: 'Your subscription payment of ₹999 has been confirmed. Valid until Feb 28, 2026.',
                  time: '3d ago',
                  icon: Icons.check,
                  iconColor: Color(0xFF2E7D32), // Green
                  iconBgColor: Color(0xFFE8F5E9), // Light Green
                  isUnread: true,
                ),
                SizedBox(height: 16),
                NotificationItem(
                  title: 'App Update Available',
                  description: 'A new version of HydroFlow Pro is available with bug fixes and improvements.',
                  time: '5d ago',
                  icon: Icons.info_outline,
                  iconColor: Color(0xFF1565C0), // Blue
                  iconBgColor: Color(0xFFE3F2FD), // Light Blue
                  isUnread: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
