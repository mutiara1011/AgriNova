import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifikasi")),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.warning, color: Colors.orange),
            title: Text("pH tidak optimal"),
            subtitle: Text("Nilai pH berada di bawah standar"),
          ),
          ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text("Sistem Normal"),
            subtitle: Text("Semua parameter dalam kondisi baik"),
          ),
        ],
      ),
    );
  }
}
