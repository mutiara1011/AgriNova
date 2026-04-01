import 'package:flutter/material.dart';
import 'notification_model.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notif;
  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inSeconds < 60) return "Baru saja";
    if (diff.inMinutes < 60) return "${diff.inMinutes} menit lalu";
    if (diff.inHours < 24) return "${diff.inHours} jam lalu";

    return "${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }

  const NotificationCard({super.key, required this.notif});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (notif.type) {
      case NotificationType.warning:
        color = const Color(0xffD32F2F);
        icon = Icons.warning_amber_rounded;
        break;
      case NotificationType.success:
        color = const Color(0xff03AF55);
        icon = Icons.check_circle;
        break;
      case NotificationType.info:
        color = Colors.blue;
        icon = Icons.info;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // 🔥 GARIS SAMPING
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 30),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTime(notif.time),
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notif.message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
