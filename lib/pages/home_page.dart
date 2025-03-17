import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/components/toggle_option.dart';
import 'package:fyp/constants/constants.dart';
import 'monitoring_screen.dart';
import 'history_screen.dart';
import 'notification_screen.dart';
import '../components/wave_clipper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io'; // Import for File class

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  bool _monitoring = false;
  String? _alert;
  int _step = 0; // 0 for Splash, 1 for Monitoring
  bool _showSettings = false;
  final ImagePicker _picker = ImagePicker();
  XFile? _videoFile;

  // Sign out method
  void signUserOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _handleStartMonitoring() async {
    setState(() {
      _monitoring = true;
      _alert = null;
      _step = 1;
    });

    // Simulate accident detection
    await Future.delayed(Duration(seconds: 5), () {
      setState(() {
        _alert = 'Accident Detected! Notifying Emergency Services...';
        _step = 2;
      });
    });
  }

  void _handleStopMonitoring() {
    setState(() {
      _monitoring = false;
      _alert = null;
      _step = 1;
      _videoFile = null;
    });
  }

  void _handleSettingsToggle() {
    setState(() {
      _showSettings = !_showSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'AlertX',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 26,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => signUserOut(context),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.redAccent, Colors.deepOrangeAccent],
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              // Welcome Message
              Text(
                "Welcome, ${user.email!}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 40),
              // Emergency Monitoring Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.redAccent, Colors.deepOrangeAccent],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Emergency Monitoring",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _monitoring
                          ? _videoFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    File(_videoFile!.path),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    'Camera Feed Not Active',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                )
                          : Center(
                              child: Text(
                                'Camera Feed Not Active',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                    ),
                    if (_alert != null)
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _alert!,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (_step == 2)
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Number Plate Detected! Retrieving Driver Information...',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _step = 3;
                                });
                              },
                              child: Text('Proceed'),
                            ),
                          ],
                        ),
                      ),
                    if (_step == 3)
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Sending SMS to Family and Emergency Services...',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _step = 4;
                                });
                              },
                              child: Text('Next'),
                            ),
                          ],
                        ),
                      ),
                    if (_step == 4)
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Ambulance Dispatched! Tracking the Route...',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _handleStartMonitoring,
                          child: Text('Start Monitoring'),
                        ),
                        ElevatedButton(
                          onPressed: _handleStopMonitoring,
                          child: Text('Stop Monitoring'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              // Quick Actions Section
              Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildQuickActionCard(
                    icon: Icons.show_chart,
                    label: "History",
                    color: Colors.blueAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => HistoryScreen()),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    icon: Icons.notifications,
                    label: "Notifications",
                    color: Colors.greenAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => NotificationScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: BottomAppBar(
          color: Colors.white,
          elevation: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.home, color: Colors.redAccent),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.history, color: Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HistoryScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build quick action cards
  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}