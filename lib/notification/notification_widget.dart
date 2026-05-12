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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color color;
    IconData icon;

    switch (notif.type) {
      case NotificationType.warning:
        color = const Color(0xffFF5252);
        icon = Icons.warning_amber_rounded;
        break;
      case NotificationType.success:
        color = const Color(0xff03AF55);
        icon = Icons.check_circle_outline_rounded;
        break;
      case NotificationType.info:
        color = Colors.blueAccent;
        icon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(notif.time),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notif.message,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
