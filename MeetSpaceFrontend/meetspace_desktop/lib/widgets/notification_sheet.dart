import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_notification.dart';

class NotificationSheet extends StatelessWidget {
  final List<AppNotification> notifications;
  final Future<void> Function() onMarkAllAsRead;
  final Future<void> Function(int notificationId) onMarkAsRead;

  const NotificationSheet({
    super.key,
    required this.notifications,
    required this.onMarkAllAsRead,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = notifications.any((item) => !item.isRead);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 520,
        constraints: const BoxConstraints(
          maxHeight: 650,
        ),
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF2F2F2F),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  "Notifications",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasUnread)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onMarkAllAsRead,
                  child: const Text(
                    "Mark all as read",
                    style: TextStyle(
                      color: Color(0xFFB87900),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Text(
                  "No notifications",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white12),
                  itemBuilder: (context, index) {
                    final item = notifications[index];

                    return Container(
                      decoration: BoxDecoration(
                        color: item.isRead
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        leading: Icon(
                          Icons.notifications_active_outlined,
                          color: item.isRead
                              ? Colors.white54
                              : const Color(0xFFB87900),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: item.isRead
                                ? FontWeight.w500
                                : FontWeight.w800,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.message,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('dd MMM yyyy - HH:mm')
                                    .format(item.createdAt),
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: item.isRead
                            ? null
                            : TextButton(
                                onPressed: () => onMarkAsRead(item.id),
                                child: const Text(
                                  "Read",
                                  style: TextStyle(
                                    color: Color(0xFFB87900),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}