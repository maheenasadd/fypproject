import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/components/toggle_option.dart';
import 'package:fyp/constants/constants.dart';
import 'monitoring_screen.dart';
import 'history_screen.dart';
import 'notification_screen.dart';
import '../components/wave_clipper.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final user = FirebaseAuth.instance.currentUser!;

  // Sign out method
  void signUserOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Maheen', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => signUserOut(context),
          ),
        ],
        flexibleSpace: ClipPath(
          clipper: WaveClipper(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.redAccent.withOpacity(0.8), Colors.white],
              ),
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Center(
                child: Text(
                  "Logged in as ${user.email!}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 60),
              // Emergency Monitoring Container
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 228, 126, 126),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 10, spreadRadius: 1),
                  ],
                ),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to Monitoring Screen
                        globalController.accidentDetected.value = false;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MonitoringScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 226, 225, 225),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        "Tap to Start Monitoring",
                        style: TextStyle(
                            color: const Color.fromARGB(255, 188, 25, 25)),
                      ),
                    ),
                    SizedBox(height: 46),
                    ElevatedButton(
                      onPressed: () {
                        // Add logic to handle accident reporting
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("Emergency services notified")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 224, 222, 222),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text("Accident Handled"),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 80),
              // Circle Buttons for Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue,
                        child: IconButton(
                          icon: Icon(Icons.show_chart, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => HistoryScreen()));
                          },
                        ),
                      ),
                      SizedBox(height: 8),
                      Text("History", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.green,
                        child: IconButton(
                          icon: Icon(Icons.notifications, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => NotificationScreen()));
                          },
                        ),
                      ),
                      SizedBox(height: 8),
                      Text("Notifications", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.blue),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, color: Colors.grey),
            label: 'Accident History',
          ),
        ],
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => HistoryScreen()));
          }
        },
      ),
    );
  }
}
