import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fyp/services/accident_service.dart';
import 'package:fyp/services/database_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AccidentDetectionPage extends StatefulWidget {
  const AccidentDetectionPage({Key? key}) : super(key: key);

  @override
  State<AccidentDetectionPage> createState() => _AccidentDetectionPageState();
}

class _AccidentDetectionPageState extends State<AccidentDetectionPage> {
  final AccidentService _accidentService = AccidentService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _emergencyEmailController = TextEditingController();
  File? _videoFile;
  bool _isAnalyzing = false;
  String? _taskId;
  Map<String, dynamic>? _analysisResults;
  VideoPlayerController? _videoController;
  bool _isVideoControllerInitialized = false;
  bool _isServerAvailable = false;
  bool _emailNotificationSent = false;
  
  // Number plate detection states
  bool _isDetectingNumberPlate = false;
  String? _numberPlateJobId;
  Map<String, dynamic>? _numberPlateResults;
  bool _isNumberPlatePolling = false;
  
  // Current location - default value, in real app you would use geolocation
  String _currentLocation = "Unknown Location";

  @override
  void initState() {
    super.initState();
    _checkServerStatus();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _emergencyEmailController.dispose();
    super.dispose();
  }

  Future<void> _checkServerStatus() async {
    try {
      final isAvailable = await _accidentService.checkServerStatus();
      setState(() {
        _isServerAvailable = isAvailable;
      });
      print('Server status updated: $_isServerAvailable');
    } catch (e) {
      print('Error checking server status: $e');
      setState(() {
        _isServerAvailable = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedVideo = await picker.pickVideo(source: ImageSource.gallery);
    
    if (pickedVideo != null) {
      setState(() {
        _videoFile = File(pickedVideo.path);
        _taskId = null;
        _analysisResults = null;
        _initializeVideoPlayer();
      });
    }
  }

  Future<void> _captureVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? capturedVideo = await picker.pickVideo(source: ImageSource.camera);
    
    if (capturedVideo != null) {
      setState(() {
        _videoFile = File(capturedVideo.path);
        _taskId = null;
        _analysisResults = null;
        _initializeVideoPlayer();
      });
    }
  }

  void _initializeVideoPlayer() {
    if (_videoFile != null) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(_videoFile!);
      _videoController!.initialize().then((_) {
        setState(() {
          _isVideoControllerInitialized = true;
        });
      }).catchError((error) {
        print('Error initializing video player: $error');
        // Handle error appropriately
      });
    }
  }

  Future<void> _analyzeVideo() async {
    if (_videoFile == null) return;

    // First check server status
    if (!_isServerAvailable) {
      final isAvailable = await _accidentService.checkServerStatus();
      setState(() {
        _isServerAvailable = isAvailable;
      });
      
      if (!_isServerAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server is not available. Please check your connection.')),
        );
        return;
      }
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      print('Starting video analysis for file: ${_videoFile!.path}');
      final result = await _accidentService.analyzeVideo(_videoFile!);
      print('Analysis request complete with task ID: ${result['task_id']}');
      
      setState(() {
        _taskId = result['task_id'];
        _isAnalyzing = false;
      });
      
      // Start checking for results
      _checkResults();
    } catch (e) {
      print('Error analyzing video: $e');
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  int _resultCheckAttempts = 0;
  static const int _maxResultCheckAttempts = 3;

  Future<void> _checkResults() async {
    if (_taskId == null) return;

    setState(() {
      _isAnalyzing = true;
      _resultCheckAttempts = 0;
    });

    _attemptResultCheck();
  }

  Future<void> _attemptResultCheck() async {
    try {
      print('Checking results for task ID: $_taskId (Attempt ${_resultCheckAttempts + 1}/$_maxResultCheckAttempts)');
      final results = await _accidentService.getAnalysisResults(_taskId!);
      print('Received results: $results');
      
      // Check if results are properly structured
      if (results != null) {
        if (results.containsKey('status') && results['status'] == 'processing') {
          // Still processing, handle accordingly
          print('Task still processing, will retry after delay');
          
          if (_resultCheckAttempts < _maxResultCheckAttempts) {
            _resultCheckAttempts++;
            setState(() {
              // Update UI to show we're waiting
            });
            
            // Wait and retry
            Future.delayed(Duration(seconds: 2), () {
              _attemptResultCheck();
            });
            return;
          } else {
            // Max retries reached
            print('Max retry attempts reached');
            setState(() {
              _isAnalyzing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Video is still being processed. Please try again later.')),
            );
            return;
          }
        }
        
        print('Accidents detected: ${results['accidents_detected']}');
        if (results.containsKey('accidents_count')) {
          print('Accidents count: ${results['accidents_count']}');
        }
        if (results['timestamps'] != null) {
          print('Timestamps: ${results['timestamps']}');
        }
        
        // Save accident data to the database if accidents are detected
        if (results['accidents_detected'] == true) {
          // Save each accident instance to the database
          if (results.containsKey('timestamps') && 
              results['timestamps'] is List && 
              (results['timestamps'] as List).isNotEmpty) {
            
            for (var i = 0; i < (results['timestamps'] as List).length; i++) {
              String timestamp = (results['timestamps'] as List)[i].toString();
              String accidentType = 'Unknown';
              double confidenceScore = 0.0;
              
              // Extract additional info if available
              if (results.containsKey('accident_types') && 
                  (results['accident_types'] as List).length > i) {
                accidentType = (results['accident_types'] as List)[i].toString();
              }
              
              if (results.containsKey('confidence_scores') && 
                  (results['confidence_scores'] as List).length > i) {
                confidenceScore = double.tryParse((results['confidence_scores'] as List)[i].toString()) ?? 0.0;
              }
              
              // Prepare data to save
              Map<String, dynamic> accidentData = {
                DatabaseHelper.columnTaskId: _taskId,
                DatabaseHelper.columnTimestamp: DateTime.now().toIso8601String(),
                DatabaseHelper.columnLocation: _currentLocation,
                DatabaseHelper.columnAccidentType: accidentType,
                DatabaseHelper.columnConfidenceScore: confidenceScore,
                DatabaseHelper.columnVideoPath: null, // This will be updated when video is downloaded
                DatabaseHelper.columnIsNotified: _emailNotificationSent ? 1 : 0,
                DatabaseHelper.columnIsResolved: 0
              };
              
              // Save to database
              await _databaseHelper.insertAccident(accidentData);
              print('Saved accident to database: $accidentData');
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Accident data saved to history')),
            );
          }
          
          // Send emergency email notification if not yet sent
          if (!_emailNotificationSent && _emergencyEmailController.text.isNotEmpty) {
            _sendEmergencyNotification();
          }
        }
      }
      
      setState(() {
        _analysisResults = results;
        _isAnalyzing = false;
        print('Updated state with analysis results');
      });
    } catch (e) {
      print('Error getting results: $e');
      
      if (_resultCheckAttempts < _maxResultCheckAttempts) {
        _resultCheckAttempts++;
        print('Retrying after error. Attempt $_resultCheckAttempts/$_maxResultCheckAttempts');
        
        // Wait and retry
        Future.delayed(Duration(seconds: 2), () {
          _attemptResultCheck();
        });
      } else {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting results: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _sendEmergencyNotification() async {
    if (_taskId == null || _emergencyEmailController.text.isEmpty) return;
    
    try {
      setState(() {
        _isAnalyzing = true;
      });
      
      final result = await _accidentService.setEmergencyEmail(
        _emergencyEmailController.text, 
        _taskId!
      );
      
      setState(() {
        _emailNotificationSent = true;
        _isAnalyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Emergency notification sent to ${_emergencyEmailController.text}')),
      );
      
      print('Emergency notification sent: $result');
    } catch (e) {
      print('Error sending emergency notification: $e');
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending emergency notification: ${e.toString()}')),
      );
    }
  }

  Future<void> _downloadProcessedVideo() async {
    if (_taskId == null) return;
    
    try {
      setState(() {
        _isAnalyzing = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading video...')),
      );
      
      final localFilePath = await _accidentService.downloadAccidentVideo(_taskId!);
      
      // Update database with video path
      final existingRecord = await _databaseHelper.getAccidentByTaskId(_taskId!);
      if (existingRecord != null) {
        Map<String, dynamic> updatedAccident = {...existingRecord};
        updatedAccident[DatabaseHelper.columnVideoPath] = localFilePath;
        
        await _databaseHelper.updateAccident(updatedAccident);
        print('Updated accident record with video path: $localFilePath');
      }
      
      setState(() {
        _isAnalyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video saved to: $localFilePath'),
          action: SnackBarAction(
            label: 'Play',
            onPressed: () {
              _playLocalVideo(File(localFilePath));
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading video: $e')),
      );
    }
  }
  
  void _playLocalVideo(File videoFile) {
    _videoController?.dispose();
    setState(() {
      _videoController = VideoPlayerController.file(videoFile);
      _isVideoControllerInitialized = false;
    });
    
    _videoController!.initialize().then((_) {
      setState(() {
        _isVideoControllerInitialized = true;
        _videoController!.play();
      });
    }).catchError((error) {
      print('Error initializing video player: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing video: $error')),
      );
    });
  }
  
  void _playVideoFromUrl(String url) {
    print('Playing video from URL: $url');
    _videoController?.dispose();
    
    setState(() {
      _isAnalyzing = true; // Show loading indicator
      _videoController = VideoPlayerController.network(
        url,
        httpHeaders: {
          'Accept': '*/*',
          'User-Agent': 'Flutter Video Player',
        },
      );
      _isVideoControllerInitialized = false;
    });
    
    _videoController!.initialize().then((_) {
      setState(() {
        _isVideoControllerInitialized = true;
        _isAnalyzing = false;
        _videoController!.play();
      });
      
      // Scroll to the video player to make it visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
      
    }).catchError((error) {
      print('Error initializing video player: $error');
      setState(() {
        _isAnalyzing = false;
      });
      
      // Fall back to downloading and playing locally
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Streaming failed. Downloading video to play locally...'),
          duration: const Duration(seconds: 5),
        ),
      );
      
      // Try to download and play locally
      _downloadAndPlayVideo(url);
    });
  }
  
  Future<void> _downloadAndPlayVideo(String url) async {
    try {
      setState(() {
        _isAnalyzing = true;
      });
      
      // Extract filename from URL
      final filename = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final localFilePath = await _accidentService.downloadVideoFile(url, filename);
      
      setState(() {
        _isAnalyzing = false;
      });
      
      // Play the local file
      _playLocalVideo(File(localFilePath));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video downloaded and playing from: $localFilePath')),
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download video: $e'),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }
  
  Future<void> _playNumberPlateVideo() async {
    if (_numberPlateJobId == null) return;
    
    try {
      final url = _accidentService.getNumberPlateVideoUrl(_numberPlateJobId!);
      print('Number plate video URL: $url');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading video...')),
      );
      
      _playVideoFromUrl(url);
    } catch (e) {
      print('Error playing number plate video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing video: $e')),
      );
    }
  }
  
  Future<void> _playAccidentVideo() async {
    if (_taskId == null) return;
    
    try {
      final url = _accidentService.getProcessedVideoUrl(_taskId!);
      print('Accident video URL: $url');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading video...')),
      );
      
      _playVideoFromUrl(url);
    } catch (e) {
      print('Error playing accident video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing video: $e')),
      );
    }
  }
  
  Future<void> _downloadNumberPlateVideo() async {
    if (_numberPlateJobId == null) return;
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading number plate detection video...')),
      );
      
      setState(() {
        _isNumberPlatePolling = true;
      });
      
      final localFilePath = await _accidentService.downloadNumberPlateVideo(_numberPlateJobId!);
      
      setState(() {
        _isNumberPlatePolling = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video saved to: $localFilePath'),
          action: SnackBarAction(
            label: 'Play',
            onPressed: () {
              _playLocalVideo(File(localFilePath));
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isNumberPlatePolling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading video: $e')),
      );
    }
  }

  // Number Plate Detection Methods
  Future<void> _detectNumberPlate() async {
    if (_videoFile == null) return;

    setState(() {
      _isDetectingNumberPlate = true;
      _numberPlateJobId = null;
      _numberPlateResults = null;
    });

    try {
      print('Starting number plate detection for file: ${_videoFile!.path}');
      final result = await _accidentService.detectNumberPlate(_videoFile!);
      print('Number plate detection request complete with job ID: ${result['job_id']}');
      
      setState(() {
        _numberPlateJobId = result['job_id'];
        _isDetectingNumberPlate = false;
      });
      
      // Start polling for job status
      _pollNumberPlateJobStatus();
    } catch (e) {
      print('Error detecting number plate: $e');
      setState(() {
        _isDetectingNumberPlate = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _pollNumberPlateJobStatus() async {
    if (_numberPlateJobId == null) return;
    
    setState(() {
      _isNumberPlatePolling = true;
    });
    
    try {
      bool isProcessing = true;
      int attemptCount = 0;
      
      while (isProcessing && attemptCount < 10) {
        final jobStatus = await _accidentService.getNumberPlateJobStatus(_numberPlateJobId!);
        
        if (jobStatus['status'] == 'completed') {
          isProcessing = false;
          _getNumberPlateResults();
        } else if (jobStatus['status'] == 'failed') {
          setState(() {
            _isNumberPlatePolling = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Number plate detection failed: ${jobStatus['error'] ?? 'Unknown error'}')),
          );
          return;
        } else {
          // Update UI with current progress
          setState(() {
            _numberPlateResults = jobStatus;
          });
          
          // Still processing, wait and retry
          await Future.delayed(Duration(seconds: 3));
          attemptCount++;
        }
      }
      
      if (isProcessing) {
        // Max polling attempts reached
        setState(() {
          _isNumberPlatePolling = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Number plate detection is taking longer than expected. Please check results later.')),
        );
      }
    } catch (e) {
      print('Error polling number plate job status: $e');
      setState(() {
        _isNumberPlatePolling = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking number plate job status: ${e.toString()}')),
      );
    }
  }

  Future<void> _getNumberPlateResults() async {
    if (_numberPlateJobId == null) return;
    
    try {
      final results = await _accidentService.getNumberPlateResults(_numberPlateJobId!);
      
      setState(() {
        _numberPlateResults = results;
        _isNumberPlatePolling = false;
      });
      
      print('Number plate detection results retrieved: $results');
      
      // Save number plate data to the database
      if (results != null && 
          results.containsKey('detected_plates') && 
          results['detected_plates'] is List && 
          (results['detected_plates'] as List).isNotEmpty) {
        
        for (int i = 0; i < (results['detected_plates'] as List).length; i++) {
          String plateNumber = (results['detected_plates'] as List)[i].toString();
          String? plateImage;
          
          // Get plate image URL if available
          if (results.containsKey('plate_images') && 
              (results['plate_images'] as List).length > i) {
            plateImage = (results['plate_images'] as List)[i].toString();
          }
          
          // Prepare data to save
          Map<String, dynamic> numberPlateData = {
            DatabaseHelper.columnJobId: _numberPlateJobId,
            DatabaseHelper.columnPlateNumber: plateNumber,
            DatabaseHelper.columnPlateImage: plateImage,
            DatabaseHelper.columnVideoTimestamp: null, // Timestamp in video if available
            DatabaseHelper.columnTimestamp: DateTime.now().toIso8601String()
          };
          
          // Save to database
          await _databaseHelper.insertNumberPlate(numberPlateData);
          print('Saved number plate to database: $numberPlateData');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Number plate data saved to history')),
        );
      }
    } catch (e) {
      print('Error getting number plate results: $e');
      setState(() {
        _isNumberPlatePolling = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting number plate results: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
         title: const Text(
           'Accident Detection',
           style: TextStyle(
             color: Colors.white,
             fontWeight: FontWeight.bold,
             fontSize: 15,
           ),
         ),
          actions: [
            // Server status indicator
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Text(
                    'Server: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _isServerAvailable ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: _checkServerStatus,
                    tooltip: 'Check server connection',
                  ),
                ],
              ),
            ),
          ],
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video selection buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
               ElevatedButton.icon(
                 onPressed: _pickVideo,
                 icon: const Icon(Icons.photo_library, color: Colors.white),
                 label: const Text('Select Video '),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.redAccent,
                   foregroundColor: Colors.white,
                 ),
               ),
               ElevatedButton.icon(
                 onPressed: _captureVideo,
                 icon: const Icon(Icons.videocam, color: Colors.white),
                 label: const Text('Record Video'),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.redAccent,
                   foregroundColor: Colors.white,
                 ),
               ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Video preview
            if (_videoFile != null && _isVideoControllerInitialized)
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_videoController!),
                    VideoProgressIndicator(_videoController!, allowScrubbing: true),
                    Positioned(
                      bottom: 10,
                      child: IconButton(
                        icon: Icon(
                          _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _videoController!.value.isPlaying
                                ? _videoController!.pause()
                                : _videoController!.play();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              )
            else if (_videoFile != null)
              const Center(child: CircularProgressIndicator()),
            
            const SizedBox(height: 20),
            
            // Emergency Email field (shown after video selection)
            if (_videoFile != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Emergency Email',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                 TextField(
                   controller: _emergencyEmailController,
                   decoration: const InputDecoration(
                     hintText: 'Enter emergency email',
                     border: OutlineInputBorder(
                       borderSide: BorderSide(color: Colors.redAccent),
                     ),
                     enabledBorder: OutlineInputBorder(
                       borderSide: BorderSide(color: Colors.redAccent),
                     ),
                     focusedBorder: OutlineInputBorder(
                       borderSide: BorderSide(color: Colors.redAccent),
                     ),
                     prefixIcon: Icon(Icons.email, color: Colors.redAccent),
                   ),
                   keyboardType: TextInputType.emailAddress,
                 ),
                  const SizedBox(height: 8),
                  Text(
                    'An emergency notification will be sent to this email if an accident is detected',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (_emailNotificationSent)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Emergency notification sent ✓',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            
            const SizedBox(height: 20),
            
            // Analyze button
            if (_videoFile != null)
              ElevatedButton(
                onPressed: _isAnalyzing ? null : _analyzeVideo,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: _isAnalyzing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Analyzing...'),
                        ],
                      )
                    : const Text('Analyze for Accidents'),
              ),
            
            const SizedBox(height: 20),
            
            // Task ID
            if (_taskId != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analysis in Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Task ID: $_taskId'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isAnalyzing ? null : _checkResults,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),

                        child: _isAnalyzing
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Checking Results...'),
                                ],
                              )
                            : const Text('Check Results'),
                      ),
                      // Add debug info widget
                      if (_analysisResults == null && !_isAnalyzing)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'No results yet. Click "Check Results" to retrieve analysis.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Analysis Results
            if (_analysisResults != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analysis Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Debug information section
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Raw response data (Debug):'),
                            const SizedBox(height: 4),
                            Text(
                              _analysisResults.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Handle potentially missing fields with null safety
                      if (_analysisResults!.containsKey('accidents_detected'))
                        Text(
                          'Accidents Detected: ${_analysisResults!['accidents_detected'] == true ? 'Yes' : 'No'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      else
                        const Text(
                          'Error: Missing accident detection data',
                          style: TextStyle(color: Colors.red),
                        ),
                      
                      if (_analysisResults!.containsKey('accidents_detected') && 
                          _analysisResults!['accidents_detected'] == true)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text('Number of Accidents: ${_analysisResults!['accidents_count'] ?? 'Unknown'}'),
                            const SizedBox(height: 8),
                            const Text('Timestamps (seconds):'),
                            if (_analysisResults!.containsKey('timestamps') && 
                                _analysisResults!['timestamps'] is List &&
                                (_analysisResults!['timestamps'] as List).isNotEmpty)
                              for (var i = 0; i < (_analysisResults!['timestamps'] as List).length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                                  child: Text(
                                    '${i + 1}. ${(_analysisResults!['timestamps'] as List)[i]} sec ' +
                                    '(${_analysisResults!.containsKey('accident_types') && (_analysisResults!['accident_types'] as List).length > i ? (_analysisResults!['accident_types'] as List)[i] : 'Unknown'}), ' +
                                    'Confidence: ${_analysisResults!.containsKey('confidence_scores') && (_analysisResults!['confidence_scores'] as List).length > i ? (_analysisResults!['confidence_scores'] as List)[i] : 'Unknown'}',
                                  ),
                                )
                            else
                              const Padding(
                                padding: EdgeInsets.only(left: 16.0, top: 4.0),
                                child: Text('No timestamp data available'),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _downloadProcessedVideo,
                                    icon: const Icon(Icons.download),
                                    label: const Text('Download Video'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _playAccidentVideo,
                                    icon: const Icon(Icons.play_circle_filled),
                                    label: const Text('Play Video'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isDetectingNumberPlate || _isNumberPlatePolling ? null : _detectNumberPlate,
                                    icon: const Icon(Icons.directions_car),
                                    label: const Text('Detect Plates'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
            // Number Plate Detection Results
            if (_numberPlateJobId != null)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Number Plate Detection',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Job ID: $_numberPlateJobId'),
                        
                        // Video actions
                        if (!_isNumberPlatePolling) 
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _playNumberPlateVideo,
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Play Video'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _downloadNumberPlateVideo,
                                    icon: const Icon(Icons.download),
                                    label: const Text('Download'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 16),

                        if (_isNumberPlatePolling && _numberPlateResults != null)
                          // Show job status during processing
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status: ${_numberPlateResults!['status'] ?? 'Processing'}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              
                              // Progress information
                              if (_numberPlateResults!.containsKey('progress_percentage'))
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Progress: ${_numberPlateResults!['progress_percentage']}%'),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: (_numberPlateResults!['progress_percentage'] as int) / 100,
                                    ),
                                  ],
                                )
                              else
                                const CircularProgressIndicator(),
                                
                              const SizedBox(height: 12),
                              
                              // Frames processing information
                              if (_numberPlateResults!.containsKey('processed_frames') && 
                                  _numberPlateResults!.containsKey('total_frames'))
                                Text('Processed ${_numberPlateResults!['processed_frames']} of ${_numberPlateResults!['total_frames']} frames'),
                                
                              // Detections so far
                              if (_numberPlateResults!.containsKey('detections_count'))
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('Detections so far: ${_numberPlateResults!['detections_count']}'),
                                ),
                                
                              // Error message if any
                              if (_numberPlateResults!.containsKey('error') && _numberPlateResults!['error'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Text(
                                    'Error: ${_numberPlateResults!['error']}',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          )
                        else if (_isNumberPlatePolling)
                          const Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text('Processing video for number plates...'),
                              ],
                            ),
                          )
                        else if (_numberPlateResults != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status and completion information
                              Text(
                                'Status: ${_numberPlateResults!['status'] ?? 'Unknown'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  color: _numberPlateResults!['status'] == 'completed' ? Colors.green : Colors.orange,
                                ),
                              ),
                              
                              if (_numberPlateResults!.containsKey('message') && _numberPlateResults!['message'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('${_numberPlateResults!['message']}'),
                                ),
                                
                              const SizedBox(height: 16),
                              
                              // Detections summary
                              if (_numberPlateResults!.containsKey('detection_count'))
                                Text('Total Detections: ${_numberPlateResults!['detection_count']}'),
                                
                              if (_numberPlateResults!.containsKey('unique_plates_count'))
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text('Unique Plates: ${_numberPlateResults!['unique_plates_count']}'),
                                ),
                              
                              const SizedBox(height: 16),
                              
                              // Detected plates
                              if (_numberPlateResults!.containsKey('detected_plates') && 
                                  _numberPlateResults!['detected_plates'] is List &&
                                  (_numberPlateResults!['detected_plates'] as List).isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Detected Plates:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    for (int i = 0; i < (_numberPlateResults!['detected_plates'] as List).length; i++)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: Container(
                                          padding: const EdgeInsets.all(12.0),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(8.0),
                                            border: Border.all(color: Colors.blue[200]!),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Plate ${i + 1}: ${(_numberPlateResults!['detected_plates'] as List)[i]}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              // Show plate image if available
                                              if (_numberPlateResults!.containsKey('plate_images') && 
                                                  (_numberPlateResults!['plate_images'] as List).length > i)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8.0),
                                                  child: Image.network(
                                                    (_numberPlateResults!['plate_images'] as List)[i],
                                                    height: 100,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Center(
                                                        child: CircularProgressIndicator(
                                                          value: loadingProgress.expectedTotalBytes != null
                                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                              : null,
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Text('Image not available');
                                                    },
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              else
                                const Text('No number plates detected in this video.'),
                                
                              const SizedBox(height: 16),
                              
                              // Keyframes (if available)
                              if (_numberPlateResults!.containsKey('keyframes') && 
                                  (_numberPlateResults!['keyframes'] as List).isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Key Frames:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    SizedBox(
                                      height: 120,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: (_numberPlateResults!['keyframes'] as List).length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: Image.network(
                                              (_numberPlateResults!['keyframes'] as List)[index],
                                              height: 120,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Container(
                                                  width: 160,
                                                  height: 120,
                                                  color: Colors.grey[200],
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 160,
                                                  height: 120,
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child: Text('Image not available'),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                
                              // Raw data for debugging (collapsible)
                              ExpansionTile(
                                title: const Text('Debug Information'),
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Raw response data:'),
                                        const SizedBox(height: 4),
                                        Text(
                                          _numberPlateResults.toString(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          const Text('Waiting for results...'),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 