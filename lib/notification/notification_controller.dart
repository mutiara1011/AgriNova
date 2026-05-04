import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_model.dart';

class NotificationController extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool isEnabled = true;
  static const String _notifKey = 'app_notifications';

  NotificationController() {
    _loadNotifications();
  }

  List<AppNotification> get notifications => _notifications;

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notifStr = prefs.getString(_notifKey);
    if (notifStr != null) {
      final List decoded = jsonDecode(notifStr);
      _notifications = decoded.map((e) => AppNotification.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _notifications.map((e) => e.toJson()).toList();
    await prefs.setString(_notifKey, jsonEncode(list));
  }

  void addNotification(String title, String message, NotificationType type) {
    if (!isEnabled) return;
    
    final notif = AppNotification(
      title: title,
      message: message,
      time: DateTime.now(),
      type: type,
    );

    _notifications.insert(0, notif);
    
    // Keep max 50 notifications
    if (_notifications.length > 50) {
      _notifications = _notifications.sublist(0, 50);
    }
    
    _saveNotifications();
    notifyListeners();
  }

  void clearNotifications() async {
    _notifications.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notifKey);
    notifyListeners();
  }
}

