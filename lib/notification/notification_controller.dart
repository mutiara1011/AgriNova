import 'package:flutter/material.dart';
import 'notification_model.dart';

class NotificationController extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  bool isEnabled = true;

  List<AppNotification> get notifications => _notifications;

  void addNotification(String title, String message, NotificationType type) {
    final notif = AppNotification(
      title: title,
      message: message,
      time: DateTime.now(),
      type: type,
    );

    _notifications.insert(0, notif);
    notifyListeners();
  }
}
