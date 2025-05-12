import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

class AccidentService {
  final String baseUrl = "http://192.168.113.222:8003";
  bool isServerAvailable = false;

  AccidentService() {
    _checkServerConnection();
  }

  // Check if the server is available
  Future<bool> _checkServerConnection() async {
    try {
      print('Checking server connection to: $baseUrl');
      final response = await http.get(Uri.parse('$baseUrl')).timeout(
            const Duration(seconds: 5),
          );
      isServerAvailable = response.statusCode == 200;
      print('Server connection status: $isServerAvailable (${response.statusCode})');
      return isServerAvailable;
    } catch (e) {
      print('Server connection check failed: $e');
      isServerAvailable = false;
      return false;
    }
  }

  // Public method to check and get server status
  Future<bool> checkServerStatus() async {
    return await _checkServerConnection();
  }

  // Upload video for analysis
  Future<Map<String, dynamic>> analyzeVideo(File videoFile) async {
    try {
      // Check server connection first
      if (!isServerAvailable && !await _checkServerConnection()) {
        throw Exception('Server is not available. Please check your connection.');
      }

      final uri = Uri.parse('$baseUrl/api/accident/analyze');
      print('Sending POST request to: $uri');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', uri);
      
      // Add video file to the request
      final fileStream = http.ByteStream(videoFile.openRead());
      final fileLength = await videoFile.length();
      
      final multipartFile = http.MultipartFile(
        'video', 
        fileStream, 
        fileLength,
        filename: 'video.mp4',
        contentType: MediaType('video', 'mp4'),
      );
      
      request.files.add(multipartFile);
      print('Uploading video of size: ${fileLength / 1024 / 1024} MB');
      
      // Send the request
      final response = await request.send();
      
      // Get response
      final responseData = await response.stream.bytesToString();
      print('Response status code: ${response.statusCode}');
      print('Response data: $responseData');
      
      final parsedResponse = json.decode(responseData);
      
      if (response.statusCode == 200) {
        print('Video upload successful with task_id: ${parsedResponse['task_id']}');
        return parsedResponse;
      } else {
        print('Failed to upload video: ${parsedResponse['message']}');
        throw Exception('Failed to upload video: ${parsedResponse['message']}');
      }
    } catch (e) {
      print('Error uploading video: $e');
      throw Exception('Error uploading video: $e');
    }
  }

  // Get analysis results
  Future<Map<String, dynamic>> getAnalysisResults(String taskId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/accident/results/$taskId');
      print('Sending GET request to: $uri');
      
      final response = await http.get(uri);
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        print('Decoded response: $decodedResponse');
        return decodedResponse;
      } else {
        // Try to decode error message if possible
        try {
          final errorResponse = json.decode(response.body);
          print('Error response: $errorResponse');
          throw Exception('Failed to get results: ${errorResponse['message'] ?? 'Unknown error'}');
        } catch (decodeError) {
          // If we can't decode the error JSON
          print('Failed to decode error response: $decodeError');
          throw Exception('Failed to get results: Status code ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error in getAnalysisResults: $e');
      throw Exception('Error getting analysis results: $e');
    }
  }

  // Send emergency email notification
  Future<Map<String, dynamic>> setEmergencyEmail(String email, String taskId) async {
    try {
      // Check server connection first
      if (!isServerAvailable && !await _checkServerConnection()) {
        throw Exception('Server is not available. Please check your connection.');
      }

      final uri = Uri.parse('$baseUrl/api/accident/set-emergency-email');
      print('Sending POST request to: $uri');
      
      // Create request body
      final requestBody = {
        'email': email,
        'task_id': taskId
      };
      
      // Send the request
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        print('Emergency email notification sent successfully');
        return decodedResponse;
      } else {
        // Try to decode error message if possible
        try {
          final errorResponse = json.decode(response.body);
          print('Error response: $errorResponse');
          throw Exception('Failed to send emergency notification: ${errorResponse['message'] ?? 'Unknown error'}');
        } catch (decodeError) {
          // If we can't decode the error JSON
          print('Failed to decode error response: $decodeError');
          throw Exception('Failed to send emergency notification: Status code ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error sending emergency notification: $e');
      throw Exception('Error sending emergency notification: $e');
    }
  }

  // Download a video file and save it locally
  Future<String> downloadVideoFile(String url, String filename) async {
    try {
      print('Downloading video from: $url');
      
      final http.Client httpClient = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      
      // Add user agent and headers to help with streaming
      request.headers.addAll({
        'User-Agent': 'Flutter Video Downloader',
        'Accept': '*/*',
      });
      
      final streamedResponse = await httpClient.send(request);
      
      if (streamedResponse.statusCode == 200) {
        // Get directory for storing downloaded files
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$filename';
        
        // Save the file
        final file = File(filePath);
        final fileStream = file.openWrite();
        
        // Download using streaming to handle large files better
        await streamedResponse.stream.pipe(fileStream);
        await fileStream.flush();
        await fileStream.close();
        
        print('Video downloaded and saved to: $filePath');
        return filePath;
      } else {
        print('Failed to download video: ${streamedResponse.statusCode}');
        throw Exception('Failed to download video. Status code: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      print('Error downloading video: $e');
      throw Exception('Error downloading video: $e');
    }
  }
  
  // Download number plate detection video
  Future<String> downloadNumberPlateVideo(String jobId) async {
    final url = '$baseUrl/api/numberplate/download-video/$jobId';
    final filename = 'numberplate_video_$jobId.mp4';
    return downloadVideoFile(url, filename);
  }
  
  // Download accident detection video
  Future<String> downloadAccidentVideo(String taskId) async {
    final url = '$baseUrl/api/accident/video/$taskId';
    final filename = 'accident_video_$taskId.mp4';
    return downloadVideoFile(url, filename);
  }

  // Get the video URL for downloading
  String getProcessedVideoUrl(String taskId) {
    return '$baseUrl/api/accident/video/$taskId';
  }
  
  // Get number plate processed video download URL
  String getNumberPlateVideoUrl(String jobId) {
    return '$baseUrl/api/numberplate/download-video/$jobId';
  }
  
  // Number Plate Detection APIs
  
  // Upload video for number plate detection
  Future<Map<String, dynamic>> detectNumberPlate(File videoFile) async {
    try {
      // Check server connection first
      if (!isServerAvailable && !await _checkServerConnection()) {
        throw Exception('Server is not available. Please check your connection.');
      }

      final uri = Uri.parse('$baseUrl/api/numberplate/detect-video');
      print('Sending POST request to: $uri for number plate detection');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', uri);
      
      // Add video file to the request
      final fileStream = http.ByteStream(videoFile.openRead());
      final fileLength = await videoFile.length();
      
      final multipartFile = http.MultipartFile(
        'video', 
        fileStream, 
        fileLength,
        filename: 'video.mp4',
        contentType: MediaType('video', 'mp4'),
      );
      
      request.files.add(multipartFile);
      print('Uploading video of size: ${fileLength / 1024 / 1024} MB for number plate detection');
      
      // Send the request
      final response = await request.send();
      
      // Get response
      final responseData = await response.stream.bytesToString();
      print('Response status code: ${response.statusCode}');
      print('Response data: $responseData');
      
      final parsedResponse = json.decode(responseData);
      
      if (response.statusCode == 200) {
        print('Video upload successful with job_id: ${parsedResponse['job_id']}');
        return parsedResponse;
      } else {
        print('Failed to upload video for number plate detection: ${parsedResponse['message']}');
        throw Exception('Failed to upload video for number plate detection: ${parsedResponse['message']}');
      }
    } catch (e) {
      print('Error uploading video for number plate detection: $e');
      throw Exception('Error uploading video for number plate detection: $e');
    }
  }
  
  // Get number plate detection job status
  Future<Map<String, dynamic>> getNumberPlateJobStatus(String jobId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/numberplate/job-status/$jobId');
      print('Checking number plate detection job status: $uri');
      
      final response = await http.get(uri);
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        print('Job status response: $decodedResponse');
        
        // Expected fields:
        // job_id, status, processed_frames, total_frames, 
        // detections_count, progress_percentage, error
        
        // Make sure all fields are present or have defaults
        final Map<String, dynamic> jobStatus = {
          'job_id': decodedResponse['job_id'] ?? jobId,
          'status': decodedResponse['status'] ?? 'unknown',
          'processed_frames': decodedResponse['processed_frames'] ?? 0,
          'total_frames': decodedResponse['total_frames'] ?? 0,
          'detections_count': decodedResponse['detections_count'] ?? 0,
          'progress_percentage': decodedResponse['progress_percentage'],
          'error': decodedResponse['error'],
        };
        
        return jobStatus;
      } else {
        // Try to decode error message if possible
        try {
          final errorResponse = json.decode(response.body);
          print('Error response: $errorResponse');
          throw Exception('Failed to get job status: ${errorResponse['message'] ?? 'Unknown error'}');
        } catch (decodeError) {
          // If we can't decode the error JSON
          print('Failed to decode error response: $decodeError');
          throw Exception('Failed to get job status: Status code ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error getting number plate job status: $e');
      throw Exception('Error getting number plate job status: $e');
    }
  }
  
  // Get number plate detection results
  Future<Map<String, dynamic>> getNumberPlateResults(String jobId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/numberplate/results/$jobId');
      print('Getting number plate detection results: $uri');
      
      final response = await http.get(uri);
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        print('Number plate results: $decodedResponse');
        
        // Expected fields:
        // job_id, status, output_video, detections_json, detection_count,
        // keyframes, plate_images, detected_plates, unique_plates_count, message
        
        // Make sure all fields are present or have defaults
        final Map<String, dynamic> jobResults = {
          'job_id': decodedResponse['job_id'] ?? jobId,
          'status': decodedResponse['status'] ?? 'unknown',
          'output_video': decodedResponse['output_video'],
          'detections_json': decodedResponse['detections_json'],
          'detection_count': decodedResponse['detection_count'] ?? 0,
          'keyframes': decodedResponse['keyframes'] ?? [],
          'plate_images': decodedResponse['plate_images'] ?? [],
          'detected_plates': decodedResponse['detected_plates'] ?? [],
          'unique_plates_count': decodedResponse['unique_plates_count'] ?? 0,
          'message': decodedResponse['message'],
        };
        
        return jobResults;
      } else {
        // Try to decode error message if possible
        try {
          final errorResponse = json.decode(response.body);
          print('Error response: $errorResponse');
          throw Exception('Failed to get number plate results: ${errorResponse['message'] ?? 'Unknown error'}');
        } catch (decodeError) {
          // If we can't decode the error JSON
          print('Failed to decode error response: $decodeError');
          throw Exception('Failed to get number plate results: Status code ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error getting number plate results: $e');
      throw Exception('Error getting number plate results: $e');
    }
  }
} 