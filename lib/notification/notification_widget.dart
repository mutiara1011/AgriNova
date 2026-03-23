import 'package:flutter/material.dart';
import 'notification_model.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notif;

  const NotificationCard({super.key, required this.notif});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    IconData icon;

    switch (notif.type) {
      case NotificationType.warning:
        bgColor = const Color(0xffD32F2F);
        icon = Icons.warning_amber_rounded;
        break;
      case NotificationType.success:
        bgColor = const Color(0xff03AF55);
        icon = Icons.check_circle;
        break;
      case NotificationType.info:
        bgColor = Colors.blue;
        icon = Icons.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 34),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  notif.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
