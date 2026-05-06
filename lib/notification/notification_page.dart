import 'package:flutter/material.dart';
import 'notification_controller.dart';
import 'package:provider/provider.dart';
import '../notification/notification_widget.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notif = context.watch<NotificationController>();
    final list = notif.notifications.toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'NOTIFIKASI',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xff03AF55).withValues(alpha: 0.8),
                  const Color(0xff03AF55).withValues(alpha: 0.4),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.2, 0.5],
              ),
            ),
          ),
          list.isEmpty
              ? const Center(child: Text("Tidak ada notifikasi", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 70, 16, 40),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return NotificationCard(notif: list[index]);
                  },
                ),
        ],
      ),
    );

  }
}
