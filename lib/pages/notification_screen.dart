import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  // Dummy data for multiple notifications
  final List<Map<String, String>> notifications = [
    {
      "location": "Faizabad",
      "time": "10:35 AM, 12 Oct 2023",
      "user": "John Doe",
    },
    {
      "location": "Pindi Mor",
      "time": "1:20 PM, 15 Oct 2023",
      "user": "Jane Smith",
    },
    {
      "location": "Park Road",
      "time": "5:50 PM, 18 Oct 2023",
      "user": "Mike Johnson",
    },
  ];

  // Function to send SMS notification
  void sendSmsNotification(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Send SMS to Emergency Contacts"),
          content: Text(
              "Are you sure you want to send an SMS to emergency contacts?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // Logic to send SMS notification
                Navigator.pop(context); // Close the dialog after sending SMS
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("SMS sent to emergency contacts")),
                );
              },
              child: Text("Send SMS"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.redAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification Title
                  Text(
                    "Accident Detected by ${notification['user']}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Location
                  Text(
                    notification['location']!,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  SizedBox(height: 8),
                  // Time
                  Text(
                    notification['time']!,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  SizedBox(height: 16),
                  // Send SMS Button
                  ElevatedButton(
                    onPressed: () => sendSmsNotification(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text("Send SMS to Emergency Contacts"),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}