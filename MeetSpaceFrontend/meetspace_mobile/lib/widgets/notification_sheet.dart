import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_notification.dart';

class NotificationSheet extends StatelessWidget {
  final List<AppNotification> notifications;

  const NotificationSheet({
    super.key,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 18),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 45, 45, 45),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: notifications.isEmpty
          ? const Center(
              child: Text(
                "No notifications",
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Poppins',
                ),
              ),
            )
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white12),
              itemBuilder: (context, index) {
                final item = notifications[index];

                return Container(
                  color: item.isRead
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.06),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    leading: Icon(
                      Icons.notifications_active_outlined,
                      color: item.isRead
                          ? Colors.white54
                          : Colors.orange,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: item.isRead
                            ? FontWeight.w400
                            : FontWeight.w700,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.message,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('dd MMM yyyy • HH:mm')
                                .format(item.createdAt),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}