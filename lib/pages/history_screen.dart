// lib/screens/history_screen.dart
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Accident History")),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.warning, color: Colors.red),
            title: Text("Accident on 10/05/2023"),
            subtitle: Text("Location: HSR Layout"),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to accident details
            },
          ),
          ListTile(
            leading: Icon(Icons.warning, color: Colors.red),
            title: Text("Accident on 01/03/2023"),
            subtitle: Text("Location: Indiranagar"),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to accident details
            },
          ),
        ],
      ),
    );
  }
}
