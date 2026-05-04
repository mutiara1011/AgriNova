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

  Map<String, dynamic> toJson() => {
        'title': title,
        'message': message,
        'time': time.toIso8601String(),
        'type': type.name,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      title: json['title'],
      message: json['message'],
      time: DateTime.parse(json['time']),
      type: NotificationType.values.firstWhere((e) => e.name == json['type']),
    );
  }
}

