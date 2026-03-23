import 'package:flutter/material.dart';
import 'notification_controller.dart';
import 'package:provider/provider.dart';
import '../notification/notification_widget.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notif = context.watch<NotificationController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Notifikasi")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notif.notifications.length,
        itemBuilder: (context, index) {
          final n = notif.notifications[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NotificationCard(notif: n),
          );
        },
      ),
    );
  }
}
