# Fish Tracker

A Swift-based iOS application for tracking and cataloging fish photos with automatic species detection.

## Features

### 🐟 Fish Detection & Classification
- Automatic fish species detection using machine learning (Resnet50)
- High accuracy species identification
- Manual confirmation option for edge cases

### 📸 Photo Management
- Import photos from device gallery
- Automatic metadata extraction (location, date, time)
- Duplicate detection using both exact and perceptual hashing
- Secure local storage of photos and metadata

### 📍 Location Tracking
- Automatic GPS coordinates extraction from photo metadata
- Reverse geocoding for human-readable locations
- Interactive map view of all photo locations
- Location-based photo organization

### 🗺️ Map Features
- Visual representation of all photo locations
- Interactive markers with photo previews
- Zoom and pan controls
- Cluster view for multiple photos in the same area

### 📊 Photo Organization
- Chronological photo sorting
- Species-based filtering
- Location-based grouping
- Search functionality

## Technical Details

### Core Technologies
- SwiftUI for the user interface
- Core ML for fish species detection
- Vision framework for image analysis
- MapKit for location visualization
- Core Location for geocoding
- PhotoKit for photo access and management

### Data Management
- Local file system storage for photos
- Structured metadata storage
- Efficient caching system
- Duplicate detection algorithms

## Privacy

- All processing happens on-device
- No data is sent to external servers
- Photos are accessed only with explicit user permission
- Location data is used only within the app

## Requirements

- iOS 18.0 or later
- iPhone or iPad
- Camera access (optional)
- Photo library access
- Location services (optional)

## Installation

1. Clone the repository
2. Open the project in Xcode
3. Install any required dependencies
4. Build and run on your device

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
