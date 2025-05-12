// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:fyp/services/database_helper.dart';
import 'dart:io';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _accidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccidents();
  }

  Future<void> _loadAccidents() async {
    try {
      final accidents = await _databaseHelper.getAccidents();
      setState(() {
        _accidents = accidents;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading accidents: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading accident history: $e')),
      );
    }
  }

  // Helper method to format the timestamp
  String _formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return timestamp;
    }
  }

  // Helper method to get status color
  Color _getStatusColor(int isResolved) {
    return isResolved == 1 ? Colors.green : Colors.red;
  }

  // Helper method to get status text
  String _getStatusText(int isResolved) {
    return isResolved == 1 ? "Resolved" : "Unresolved";
  }

  // Mark an accident as resolved
  Future<void> _markAsResolved(int id) async {
    try {
      await _databaseHelper.markAccidentAsResolved(id);
      _loadAccidents(); // Reload the data
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAccidents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _accidents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        "No accident history found",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _accidents.length,
                  itemBuilder: (context, index) {
                    final accident = _accidents[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {
                          // Show accident details
                          _showAccidentDetails(accident);
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
                                      "Accident on ${_formatDate(accident[DatabaseHelper.columnTimestamp])}",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Location: ${accident[DatabaseHelper.columnLocation] ?? 'Unknown'}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (accident[DatabaseHelper.columnAccidentType] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          "Type: ${accident[DatabaseHelper.columnAccidentType]}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 12,
                                          color: _getStatusColor(accident[DatabaseHelper.columnIsResolved] ?? 0),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          _getStatusText(accident[DatabaseHelper.columnIsResolved] ?? 0),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: _getStatusColor(accident[DatabaseHelper.columnIsResolved] ?? 0),
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

  void _showAccidentDetails(Map<String, dynamic> accident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Accident Details",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Divider(height: 30),
              _detailRow("Date & Time", _formatDate(accident[DatabaseHelper.columnTimestamp])),
              _detailRow("Location", accident[DatabaseHelper.columnLocation] ?? "Unknown"),
              _detailRow("Type", accident[DatabaseHelper.columnAccidentType] ?? "Unknown"),
              _detailRow("Confidence", "${(accident[DatabaseHelper.columnConfidenceScore] ?? 0) * 100}%"),
              _detailRow("Status", _getStatusText(accident[DatabaseHelper.columnIsResolved] ?? 0)),
              
              SizedBox(height: 20),
              
              // Video player section (if video path available)
              if (accident[DatabaseHelper.columnVideoPath] != null)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Here you would add code to play the video
                    _playVideo(accident[DatabaseHelper.columnVideoPath]);
                  },
                  icon: Icon(Icons.play_circle_filled),
                  label: Text("Play Accident Video"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                
              SizedBox(height: 10),
              
              // Mark as resolved/unresolved button
              if (accident[DatabaseHelper.columnIsResolved] == 0)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _markAsResolved(accident[DatabaseHelper.columnId]);
                  },
                  icon: Icon(Icons.check_circle),
                  label: Text("Mark as Resolved"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label + ":",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _playVideo(String path) {
    // Play video logic would be added here
    // You could navigate to a video player screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playing video: $path')),
    );
  }
}