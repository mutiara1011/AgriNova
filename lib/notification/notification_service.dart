import 'package:flutter/material.dart';
import 'notification_model.dart';

void showGlobalNotification(BuildContext context, AppNotification notif) {
  final overlay = Overlay.of(context);

  // 🔥 TARO LOGIC DI SINI (DI LUAR WIDGET)
  Color bgColor;

  switch (notif.type) {
    case NotificationType.warning:
      bgColor = const Color(0xffD32F2F);
      break;
    case NotificationType.success:
      bgColor = const Color(0xff03AF55);
      break;
    case NotificationType.info:
      bgColor = Colors.blue;
      break;
  }

  final entry = OverlayEntry(
    builder: (context) => Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor, // ✅ baru dipakai di sini
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "${notif.title} - ${notif.message}",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  Future.delayed(const Duration(seconds: 1), () {
    entry.remove();
  });
}
