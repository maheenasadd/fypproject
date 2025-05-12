# Accident Detection System Documentation

## Project Overview
The Accident Detection System is a Flutter-based mobile application designed to detect and manage road accidents through video analysis. The system uses computer vision and machine learning to analyze video footage, detect accidents, and provide emergency notifications.

## System Architecture

### 1. Frontend (Flutter Mobile App)
The application is built using Flutter and consists of several key components:

#### Main Components:
- **Accident Detection Page**: Core functionality for video upload and analysis
- **History Screen**: View and manage past accident records
- **Notification Screen**: Real-time accident notifications and management
- **Global Controller**: State management using GetX

### 2. Backend Services
The system communicates with a backend server for:
- Video analysis
- Accident detection
- Number plate recognition
- Emergency notifications

## Key Features

### 1. Video Analysis
- Upload video files for accident detection
- Real-time analysis status monitoring
- Support for multiple video formats
- Progress tracking with task IDs

### 2. Accident Detection
- Automated accident detection in video footage
- Confidence scoring for detected accidents
- Timestamp tracking for accident occurrences
- Location tracking (when available)

### 3. Emergency Notifications
- Email-based emergency notifications
- Configurable emergency contact settings
- Notification status tracking
- Real-time notification delivery

### 4. Number Plate Recognition
- Automated license plate detection
- Plate number extraction
- Image capture of detected plates
- Historical record keeping

### 5. Data Management
- Local SQLite database for data persistence
- Accident history tracking
- Notification management
- Video storage and retrieval

## Technical Implementation

### Database Schema
The system uses SQLite with two main tables:

1. **Accidents Table**
   - Task ID
   - Timestamp
   - Location
   - Accident Type
   - Confidence Score
   - Video Path
   - Notification Status
   - Resolution Status

2. **Number Plates Table**
   - Job ID
   - Plate Number
   - Plate Image
   - Video Timestamp
   - Detection Timestamp

### API Integration
The system communicates with a backend server through RESTful APIs:

1. **Video Analysis**
   - Endpoint: `/api/accident/analyze`
   - Method: POST
   - Purpose: Upload and analyze video for accidents

2. **Results Retrieval**
   - Endpoint: `/api/accident/results/{taskId}`
   - Method: GET
   - Purpose: Get analysis results for a specific task

3. **Emergency Notifications**
   - Endpoint: `/api/accident/set-emergency-email`
   - Method: POST
   - Purpose: Configure and send emergency notifications

## User Interface

### Main Screens

1. **Accident Detection Page**
   - Video upload interface
   - Analysis controls
   - Emergency email configuration
   - Real-time status updates

2. **History Screen**
   - List of past accidents
   - Detailed accident information
   - Resolution management
   - Video playback

3. **Notification Screen**
   - Active notifications
   - Emergency contact management
   - Status updates
   - Resolution tracking

## Error Handling

The system implements comprehensive error handling for:
- Server connectivity issues
- Video upload failures
- Analysis errors
- Notification delivery problems
- Database operations

## Security Features

1. **Data Protection**
   - Local database encryption
   - Secure API communication
   - Protected video storage

2. **Access Control**
   - User authentication
   - Permission management
   - Secure emergency notifications

## Future Enhancements

1. **Planned Features**
   - Real-time video analysis
   - Enhanced number plate recognition
   - Multiple emergency contact support
   - Advanced accident classification

2. **Technical Improvements**
   - Performance optimization
   - Enhanced error recovery
   - Extended API capabilities
   - Improved user interface

## System Requirements

### Mobile App
- Flutter SDK
- Android 5.0+ / iOS 10.0+
- Camera access
- Storage permissions
- Internet connectivity

### Server
- RESTful API support
- Video processing capabilities
- Email service integration
- Database management system

## Installation and Setup

1. **Prerequisites**
   - Flutter development environment
   - Backend server setup
   - Database configuration
   - API endpoint configuration

2. **Configuration**
   - Server URL setup
   - Database initialization
   - Email service configuration
   - Permission settings

## Troubleshooting

Common issues and solutions:
1. **Server Connectivity**
   - Check network connection
   - Verify server status
   - Confirm API endpoints

2. **Video Analysis**
   - Verify video format
   - Check file size
   - Confirm upload status

3. **Notifications**
   - Verify email configuration
   - Check server status
   - Confirm delivery status

## Support and Maintenance

1. **Regular Maintenance**
   - Database optimization
   - Server monitoring
   - Performance checks
   - Security updates

2. **Technical Support**
   - Error logging
   - User feedback
   - System updates
   - Performance monitoring 