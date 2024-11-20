// lib/screens/monitoring_screen.dart
import 'package:flutter/material.dart';
import 'package:fyp/constants/constants.dart';
import 'package:fyp/pages/live_detection.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MonitoringScreen extends StatefulWidget {
  @override
  _MonitoringScreenState createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  bool accidentDetected = false;
  String? numberPlate;
  bool driverDataRetrieved = false;
  File? _videoFile;

  final ImagePicker _picker = ImagePicker();

  // Method to upload video from gallery
  Future<void> uploadVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
        accidentDetected = true; // Simulate accident detection for demo
        numberPlate = null;
        driverDataRetrieved = false;
      });
    }
  }

  // Simulate live camera feed logic
  void startLiveCamera() {
    // setState(() {
    //   accidentDetected = true; // Simulate accident detection for demo
    //   numberPlate = null;
    //   driverDataRetrieved = false;
    // });
    globalController.accidentDetected.value = false;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LiveDetection()),
    );
  }

  // Simulate number plate extraction
  void extractNumberPlate() {
    setState(() {
      numberPlate = "Akk7311"; // Dummy number plate
    });
  }

  // Simulate driver information retrieval
  void retrieveDriverInfo() {
    setState(() {
      driverDataRetrieved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Driver information retrieved!")),
    );
  }

  // Show dialog to confirm SMS was sent
  void showSmsSentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("SMS Status"),
          content: Text("SMS sent to emergency contact!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Accident Monitoring")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Video Demo Section at the top
            Container(
              width: 300,
              height: 200,
              color: Colors.grey[300],
              alignment: Alignment.center,
              child: Text(
                "VIDEO DEMO",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  SizedBox(
                    width: 250,
                    child: ElevatedButton(
                      onPressed: uploadVideo,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        "Upload Video",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: 250,
                    child: ElevatedButton(
                      onPressed: startLiveCamera,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        "Live Camera",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            Obx(() {
              return globalController.accidentDetected.value
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Status: Detected",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: extractNumberPlate,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text("Extract Number Plate"),
                        ),
                        SizedBox(height: 20),
                        if (numberPlate != null) ...[
                          Text(
                            "Plate Number: $numberPlate",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: retrieveDriverInfo,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 20),
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text("Retrieve & Display Data"),
                          ),
                          if (driverDataRetrieved)
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 20),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      spreadRadius: 1),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Driver Data",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text("Name: John Smith"),
                                  Text("License: ABCD1234"),
                                  Text("Insurance: Valid till 2024"),
                                  SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: showSmsSentDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text("Send SMS to Home"),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    )
                  : const SizedBox.shrink();
            })
          ],
        ),
      ),
    );
  }
}
