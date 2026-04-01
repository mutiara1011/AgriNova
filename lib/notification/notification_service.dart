import 'package:flutter/material.dart';
import 'notification_model.dart';

void showGlobalNotification(BuildContext context, AppNotification notif) {
  final overlay = Overlay.of(context);

  late OverlayEntry entry;

  // 🔥 Animation controller
  final controller = AnimationController(
    vsync: Navigator.of(context),
    duration: const Duration(milliseconds: 400),
  );

  final animation = CurvedAnimation(parent: controller, curve: Curves.easeOut);

  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.5),
            end: Offset.zero,
          ).animate(animation),
          child: Material(
            color: Colors.transparent,
            child: _notificationUI(notif),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  controller.forward();

  // 🔥 auto remove + reverse animation
  Future.delayed(const Duration(seconds: 2), () {
    controller.reverse().then((_) {
      entry.remove();
      controller.dispose();
    });
  });
}

Widget _notificationUI(AppNotification notif) {
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
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // 🔥 garis samping
            Container(
              width: 5,
              height: 70,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(width: 8),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

        // 🔥 progress bar auto dismiss
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: 0),
          duration: const Duration(seconds: 2),
          builder: (context, value, _) {
            return LinearProgressIndicator(
              value: value,
              minHeight: 3,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(color),
            );
          },
        ),
      ],
    ),
  );
}
