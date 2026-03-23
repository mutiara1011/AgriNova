enum NotificationType { warning, info, success }

class AppNotification {
  final String title;
  final String message;
  final DateTime time;
  final NotificationType type;

  AppNotification({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
  });
}
