import 'package:flutter/material.dart';
import 'package:fyp/services/database_helper.dart';
import 'dart:io';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _databaseHelper.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notifications: $e')),
      );
    }
  }

  // Helper method to format the timestamp
  String _formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.hour}:${date.minute}, ${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return timestamp;
    }
  }

  // Function to mark an accident as resolved
  Future<void> _markAsResolved(int id) async {
    try {
      await _databaseHelper.markAccidentAsResolved(id);
      _loadNotifications(); // Reload the data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Accident marked as resolved')),
      );
    } catch (e) {
      print('Error marking accident as resolved: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Function to send SMS notification
  void _sendSmsNotification(BuildContext context, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Send Email to Emergency Contacts"),
          content: Text(
              "Are you sure you want to send an email to emergency contacts about this accident?"),
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
                  SnackBar(content: Text("Email sent to emergency contacts")),
                );
              },
              child: Text("Send Email"),
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        "No unresolved accidents",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
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
                              "Accident Detected",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            SizedBox(height: 16),
                            // Location
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.grey[600]),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    notification[DatabaseHelper.columnLocation] ?? "Unknown Location",
                                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            // Time
                            Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.grey[600]),
                                SizedBox(width: 8),
                                Text(
                                  _formatDate(notification[DatabaseHelper.columnTimestamp]),
                                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                                ),
                              ],
                            ),
                            if (notification[DatabaseHelper.columnAccidentType] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.grey[600]),
                                    SizedBox(width: 8),
                                    Text(
                                      "Type: ${notification[DatabaseHelper.columnAccidentType]}",
                                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(height: 16),
                            // Action buttons
                            Row(
                              children: [
                                // Send SMS Button
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _sendSmsNotification(context, notification),
                                    icon: Icon(Icons.email),
                                    label: Text("Send Email"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                // Resolve Button
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _markAsResolved(notification[DatabaseHelper.columnId]),
                                    icon: Icon(Icons.check_circle),
                                    label: Text("Resolve"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // View Video button (if video is available)
                            if (notification[DatabaseHelper.columnVideoPath] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Navigate to video player
                                    _playVideo(notification[DatabaseHelper.columnVideoPath]);
                                  },
                                  icon: Icon(Icons.play_circle_filled),
                                  label: Text("View Video"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(double.infinity, 0),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
  
  void _playVideo(String path) {
    // Play video logic would be added here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playing video: $path')),
    );
  }
}