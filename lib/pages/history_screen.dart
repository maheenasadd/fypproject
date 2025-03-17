// lib/screens/history_screen.dart

import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  // Dummy data for accident history
  final List<Map<String, String>> accidents = [
    {
      "date": "10/05/2023",
      "location": "HSR Layout",
      "status": "Resolved",
    },
    {
      "date": "01/03/2023",
      "location": "Indiranagar",
      "status": "Unresolved",
    },
    {
      "date": "15/02/2023",
      "location": "Koramangala",
      "status": "Resolved",
    },
  ];

  // Helper method to get status color
  Color _getStatusColor(String status) {
    return status == "Resolved" ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Accident History",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.redAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: accidents.length,
        itemBuilder: (context, index) {
          final accident = accidents[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: EdgeInsets.only(bottom: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                // Navigate to accident details
              },
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon with gradient background
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.redAccent, Colors.orangeAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.warning,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    SizedBox(width: 16),
                    // Accident details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Accident on ${accident['date']}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Location: ${accident['location']}",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 12,
                                color: _getStatusColor(accident['status']!),
                              ),
                              SizedBox(width: 8),
                              Text(
                                accident['status']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _getStatusColor(accident['status']!),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Forward arrow
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}