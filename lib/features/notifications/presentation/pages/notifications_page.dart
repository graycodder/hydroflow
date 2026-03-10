import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watermemo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:watermemo/features/auth/presentation/bloc/auth_state.dart';
import 'package:watermemo/features/notifications/domain/entities/notification_entity.dart';
import 'package:watermemo/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:watermemo/features/notifications/presentation/widgets/notification_item.dart';
import 'package:watermemo/core/service_locator.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String uid = '';
    if (authState is AuthAuthenticated) {
      uid = authState.salesman.id;
    }

    return BlocProvider(
      create: (context) => sl<NotificationBloc>()..add(LoadNotifications(uid)),
      child: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          final int unreadCount = state is NotificationLoaded
              ? state.notifications.where((n) => !n.isRead).length
              : 0;
          final bool hasUnread = unreadCount > 0;

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  if (hasUnread) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (hasUnread)
                  IconButton(
                    tooltip: 'Mark all as read',
                    icon: const Icon(Icons.done_all_rounded, color: Colors.blue),
                    onPressed: () {
                      context.read<NotificationBloc>().add(MarkAllAsRead(uid));
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
            body: _buildBody(context, state, uid),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationState state, String uid) {
    if (state is NotificationLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is NotificationError) {
      return Center(child: Text('Error: ${state.message}'));
    } else if (state is NotificationLoaded) {
      if (state.notifications.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none, size: 72, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                "You're all caught up!",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No notifications yet',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        );
      }

      // Group notifications by date
      final grouped = _groupByDate(state.notifications);

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final item = grouped[index];

          // Date header
          if (item is String) {
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            );
          }

          // Notification item
          final notification = item as NotificationEntity;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NotificationItem(
              notification: notification,
              onRead: notification.isRead
                  ? null
                  : () => context
                      .read<NotificationBloc>()
                      .add(MarkAsRead(uid, notification.id)),
            ),
          );
        },
      );
    }
    return const SizedBox();
  }

  /// Groups notifications inserting String date-header entries before each group.
  List<dynamic> _groupByDate(List<NotificationEntity> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));

    final result = <dynamic>[];
    String? currentGroup;

    for (final notification in notifications) {
      final d = DateTime(
        notification.timestamp.year,
        notification.timestamp.month,
        notification.timestamp.day,
      );

      final String group;
      if (d == today) {
        group = 'Today';
      } else if (d == yesterday) {
        group = 'Yesterday';
      } else if (d.isAfter(thisWeekStart)) {
        group = 'This Week';
      } else {
        group = 'Older';
      }

      if (group != currentGroup) {
        result.add(group);
        currentGroup = group;
      }
      result.add(notification);
    }
    return result;
  }
}
