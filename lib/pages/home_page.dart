import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/components/toggle_option.dart';
import 'package:fyp/constants/constants.dart';
import 'package:fyp/pages/accident_detection_page.dart';
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
    // Get screen dimensions for responsive calculations
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final bool isSmallScreen = screenWidth < 360;
    final bool isLargeScreen = screenWidth > 600;

    // Calculate responsive dimensions
    final double contentPadding = screenWidth * 0.04; // 4% of screen width
    final double sectionSpacing = screenHeight * 0.025; // 2.5% of screen height
    final double cardRadius = screenWidth * 0.05; // 5% of screen width

    // Responsive text scaling based on screen width
    final double titleScale = isSmallScreen ? 0.85 : isLargeScreen ? 1.2 : 1.0;
    final double subtitleScale = isSmallScreen ? 0.85 : isLargeScreen ? 1.1 : 1.0;
    final double bodyScale = isSmallScreen ? 0.8 : isLargeScreen ? 1.1 : 1.0;

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
            fontSize: 26 * titleScale,
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  children: [
                    SizedBox(height: sectionSpacing),
                    // Welcome Message
                    Text(
                      "Welcome, ${user.email!}",
                      style: TextStyle(
                        fontSize: 18 * subtitleScale,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: sectionSpacing * 1.5),
                    // Emergency Monitoring Section
                    // Container(
                    //   width: double.infinity,
                    //   padding: EdgeInsets.all(contentPadding),
                    //   decoration: BoxDecoration(
                    //     gradient: LinearGradient(
                    //       begin: Alignment.topLeft,
                    //       end: Alignment.bottomRight,
                    //       colors: [Colors.redAccent, Colors.deepOrangeAccent],
                    //     ),
                    //     borderRadius: BorderRadius.circular(cardRadius),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: Colors.redAccent.withOpacity(0.3),
                    //         blurRadius: 15,
                    //         spreadRadius: 5,
                    //       ),
                    //     ],
                    //   ),
                    //   child: Column(
                    //     children: [
                    //       Text(
                    //         "Emergency Monitoring",
                    //         style: TextStyle(
                    //           fontSize: 24 * titleScale,
                    //           fontWeight: FontWeight.bold,
                    //           color: Colors.white,
                    //         ),
                    //       ),
                    //       SizedBox(height: sectionSpacing),
                    //       // Camera feed container with aspect ratio
                    //       AspectRatio(
                    //         aspectRatio: 16 / 9, // Standard video aspect ratio
                    //         child: AnimatedContainer(
                    //           duration: Duration(milliseconds: 500),
                    //           curve: Curves.easeInOut,
                    //           width: double.infinity,
                    //           decoration: BoxDecoration(
                    //             color: Colors.grey[300],
                    //             borderRadius: BorderRadius.circular(cardRadius * 0.8),
                    //           ),
                    //           child: _monitoring
                    //               ? _videoFile != null
                    //               ? ClipRRect(
                    //             borderRadius: BorderRadius.circular(cardRadius * 0.8),
                    //             child: Image.file(
                    //               File(_videoFile!.path),
                    //               fit: BoxFit.cover,
                    //             ),
                    //           )
                    //               : Center(
                    //             child: Text(
                    //               'Camera Feed Not Active',
                    //               style: TextStyle(
                    //                 color: Colors.grey[600],
                    //                 fontSize: 14 * bodyScale,
                    //               ),
                    //             ),
                    //           )
                    //               : Center(
                    //             child: Text(
                    //               'Camera Feed Not Active',
                    //               style: TextStyle(
                    //                 color: Colors.grey[600],
                    //                 fontSize: 14 * bodyScale,
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //       if (_alert != null)
                    //         Container(
                    //           margin: EdgeInsets.symmetric(vertical: sectionSpacing * 0.8),
                    //           padding: EdgeInsets.all(contentPadding * 0.8),
                    //           decoration: BoxDecoration(
                    //             color: Colors.red,
                    //             borderRadius: BorderRadius.circular(cardRadius * 0.8),
                    //           ),
                    //           child: Text(
                    //             _alert!,
                    //             style: TextStyle(
                    //               color: Colors.white,
                    //               fontSize: 14 * bodyScale,
                    //             ),
                    //           ),
                    //         ),
                    //       if (_step == 2)
                    //         Container(
                    //           margin: EdgeInsets.symmetric(vertical: sectionSpacing * 0.8),
                    //           padding: EdgeInsets.all(contentPadding * 0.8),
                    //           decoration: BoxDecoration(
                    //             color: Colors.orange,
                    //             borderRadius: BorderRadius.circular(cardRadius * 0.8),
                    //           ),
                    //           child: Column(
                    //             children: [
                    //               Text(
                    //                 'Number Plate Detected! Retrieving Driver Information...',
                    //                 style: TextStyle(
                    //                   color: Colors.white,
                    //                   fontSize: 14 * bodyScale,
                    //                 ),
                    //               ),
                    //               SizedBox(height: sectionSpacing * 0.8),
                    //               ElevatedButton(
                    //                 onPressed: () {
                    //                   setState(() {
                    //                     _step = 3;
                    //                   });
                    //                 },
                    //                 child: Text('Proceed'),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       if (_step == 3)
                    //         Container(
                    //           margin: EdgeInsets.symmetric(vertical: sectionSpacing * 0.8),
                    //           padding: EdgeInsets.all(contentPadding * 0.8),
                    //           decoration: BoxDecoration(
                    //             color: Colors.blue,
                    //             borderRadius: BorderRadius.circular(cardRadius * 0.8),
                    //           ),
                    //           child: Column(
                    //             children: [
                    //               Text(
                    //                 'Sending email to Family and Emergency Services...',
                    //                 style: TextStyle(
                    //                   color: Colors.white,
                    //                   fontSize: 14 * bodyScale,
                    //                 ),
                    //               ),
                    //               SizedBox(height: sectionSpacing * 0.8),
                    //               ElevatedButton(
                    //                 onPressed: () {
                    //                   setState(() {
                    //                     _step = 4;
                    //                   });
                    //                 },
                    //                 child: Text('Next'),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       if (_step == 4)
                    //         Container(
                    //           margin: EdgeInsets.symmetric(vertical: sectionSpacing * 0.8),
                    //           padding: EdgeInsets.all(contentPadding * 0.8),
                    //           decoration: BoxDecoration(
                    //             color: Colors.green,
                    //             borderRadius: BorderRadius.circular(cardRadius * 0.8),
                    //           ),
                    //           child: Text(
                    //             'Ambulance Dispatched! Tracking the Route...',
                    //             style: TextStyle(
                    //               color: Colors.white,
                    //               fontSize: 14 * bodyScale,
                    //             ),
                    //           ),
                    //         ),
                    //       SizedBox(height: sectionSpacing),
                    //       // Responsive button layout
                    //       LayoutBuilder(
                    //         builder: (context, constraints) {
                    //           // If width is less than 300, stack buttons vertically
                    //           if (constraints.maxWidth < 300) {
                    //             return Column(
                    //               children: [
                    //                 SizedBox(
                    //                   width: double.infinity,
                    //                   child: ElevatedButton(
                    //                     onPressed: _handleStartMonitoring,
                    //                     child: Text('Start Monitoring'),
                    //                   ),
                    //                 ),
                    //                 SizedBox(height: 10),
                    //                 SizedBox(
                    //                   width: double.infinity,
                    //                   child: ElevatedButton(
                    //                     onPressed: _handleStopMonitoring,
                    //                     child: Text('Stop Monitoring'),
                    //                   ),
                    //                 ),
                    //               ],
                    //             );
                    //           } else {
                    //             // Otherwise use a row
                    //             return Row(
                    //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //               children: [
                    //                 Expanded(
                    //                   child: ElevatedButton(
                    //                     onPressed: _handleStartMonitoring,
                    //                     child: Text('Start Monitoring'),
                    //                   ),
                    //                 ),
                    //                 SizedBox(width: 10),
                    //                 Expanded(
                    //                   child: ElevatedButton(
                    //                     onPressed: _handleStopMonitoring,
                    //                     child: Text('Stop Monitoring'),
                    //                   ),
                    //                 ),
                    //               ],
                    //             );
                    //           }
                    //         },
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    SizedBox(height: sectionSpacing),
                    // Accident Detection Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(contentPadding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.redAccent, Colors.deepOrangeAccent],
                        ),
                        borderRadius: BorderRadius.circular(cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Accident Detection Analysis",
                            style: TextStyle(
                              fontSize: 24 * titleScale,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: sectionSpacing),
                          Text(
                            "Record, Upload and analyze videos for accident detection",
                            style: TextStyle(
                              fontSize: 16 * bodyScale,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: sectionSpacing),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AccidentDetectionPage(),
                                ),
                              );
                            },
                           icon: Icon(Icons.video_collection, color: Colors.redAccent),

                            label: Text("Open Accident Detection"),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: contentPadding,
                                vertical: contentPadding * 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: sectionSpacing * 1.5),
                    // Quick Actions Section
                    Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 22 * titleScale,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                    // Responsive grid layout based on screen width
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Determine grid column count based on width
                        int crossAxisCount = constraints.maxWidth > 600 ? 4 :
                        constraints.maxWidth > 400 ? 3 : 2;

                        return GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: contentPadding,
                          mainAxisSpacing: contentPadding,
                          childAspectRatio: isSmallScreen ? 0.9 : 1.0, // Adjust aspect ratio for small screens
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
                              context: context,
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
                              context: context,
                            ),
                            // Add more quick action cards if needed
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
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

  // Helper method to build responsive quick action cards
  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required BuildContext context,
  }) {
    // Get responsive dimensions
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;
    final double iconSize = isSmallScreen ? 30 : screenWidth > 600 ? 50 : 40;
    final double fontSize = isSmallScreen ? 14 : screenWidth > 600 ? 20 : 16;
    final double padding = screenWidth * 0.03; // 3% of screen width

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.05), // 5% of screen width
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(screenWidth * 0.05),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: color),
              SizedBox(height: padding * 0.5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}