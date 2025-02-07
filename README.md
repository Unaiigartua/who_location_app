# WHO Location Client

[![GitHub Repository](https://img.shields.io/badge/GitHub-Repository-blue.svg)](https://github.com/Unaiigartua/who_location_app)

## Overview

WHO Location Client is a Flutter application for real-time management of reports, tasks, and users. It leverages WebSocket connections for live updates and provides comprehensive features including task management, report generation, and user administration with role-based access control. The app integrates geolocation capabilities for location-based task assignment and server synchronization.

### Purpose
This application is designed to streamline emergency response operations by:
- Facilitating real-time communication between control centers and ambulance teams
- Optimizing resource allocation through location-based task assignment
- Providing comprehensive tracking and reporting capabilities
- Ensuring efficient team coordination during critical situations

### Target Users
- Emergency Response Teams
- Ambulance Staff
- Control Center Operators
- Administrative Personnel
- Emergency Service Managers

## Key Features

### Real-time Communication
- **WebSocket Integration** - Instant notifications for task updates and system events
- **Live Status Updates** - Real-time task status synchronization
- **Push Notifications** - Immediate alerts for critical events and assignments

### User Management
- **Role-based Access Control** - Different permission levels for administrators and ambulance staff
- **Secure Authentication** - Complete login and registration system
- **Profile Management** - User profile customization and settings
- **Team Management** - Administrative tools for managing user accounts and permissions

### Task Management
- **Task Creation & Assignment** - Create and assign tasks to specific ambulance teams
- **Geolocation Integration** - Location-based task assignment and tracking
- **Status Tracking** - Real-time monitoring of task progress and completion
- **Task History** - Comprehensive history of all tasks with filtering capabilities
- **Priority Management** - Task prioritization and emergency handling
- **Notes & Updates** - Ability to add notes and updates to ongoing tasks

### Report System
- **Report Generation** - Create detailed reports for completed tasks
- **File Management** - Local storage and synchronization of reports
- **Download Capabilities** - Export and download reports in multiple formats
- **Automatic Synchronization** - Server-client file synchronization
- **Data Analytics** - Basic statistics and data visualization

### Location Services
- **Real-time Tracking** - Live location tracking for ambulance units
- **Map Integration** - Interactive map interface for task locations
- **Route Optimization** - Suggested routes for task completion
- **Geofencing** - Location-based alerts and notifications

### Technical Features
- **Offline Support** - Basic functionality when offline
- **State Management** - Efficient data handling using Provider pattern
- **Error Handling** - Robust error management and recovery
- **Data Persistence** - Local storage for offline access
- **Responsive Design** - Adaptable UI for different screen sizes

## Core Components

### Screens

#### Authentication Flow
Secure user authentication and access control system.

- **Login Screen**
  - Credential validation & 2FA support
  - Session management & security features
  - Password recovery & remember me
  - Login history & activity tracking
  
- **Register Screen**
  - Smart form validation & verification
  - Role-based registration flow
  - Organization onboarding process
  - Profile setup & customization
  
- **Admin Register Screen**
  - Enhanced security verification
  - Advanced permission configuration
  - Organization management tools
  - Compliance & audit settings

#### Core Interface
Central hub for daily operations and task management.

- **Home Screen**
  - Real-time dashboard & metrics
  - Task overview & quick actions
  - Team status & notifications
  - Emergency alerts & weather info
  
- **Task Detail Screen**
  - Task tracking & management
  - Location & resource monitoring
  - Communication & documentation
  - Status updates & attachments
  
- **Task History Screen**
  - Advanced search & filtering
  - Analytics & reporting tools
  - Performance tracking
  - Resource utilization data

#### Navigation System
Quick access to essential features and information.

- **Tasks Tab**
  - Smart task organization
  - Priority management
  - Team coordination tools
  - Resource planning features
  
- **Map Tab**
  - Multi-layer mapping system
  - Real-time tracking & routes
  - Environmental monitoring
  - Resource distribution view
  
- **Profile Tab**
  - Account management
  - Preferences & notifications
  - Professional records
  - Security settings

#### Administrative Tools
System configuration and management interface.

- **User Management**
  - User administration
  - Role & permission control
  - Activity monitoring
  - Performance evaluation
  
- **Report Center**
  - Custom report generation
  - Data analysis tools
  - Compliance tracking
  - Automated reporting

### Dialogs
- Add Task Dialog
- Complete Task Dialog
- Edit Task Dialog
- Handle Task Dialog
- Report Issues Dialog
- Add Note Dialog

## Architecture

### Core Services
- **Authentication** - Managed by `AuthProvider`
- **Task Operations** - Handled through `TaskProvider` and `TaskService`
- **Report Management** - Implemented via `ReportApi`
- **Real-time Communication** - Powered by `WebSocketService`
- **Navigation** - Utilizing `goRouter`

## Project Structure

```
who_location_app/
├── lib/
│   ├── api/                    # API Integration
│   ├── config/                 # App Configuration
│   ├── dialogs/                # Modal Dialogs
│   ├── models/                 # Data Models
│   ├── providers/              # State Management
│   ├── screens/                # UI Screens
│   │   ├── admin/             # Admin Interfaces
│   │   └── home/              # Main App Screens
│   ├── services/              # External Services
│   ├── utils/                 # Helper Utilities
│   └── widgets/               # Reusable Components
└── README.md
```

## Getting Started

1. **Clone Repository**
```bash
git clone <REPOSITORY_URL>
cd who_location_app
```

2. **Install Dependencies**
```bash
flutter pub get
```

3. **Launch Application**
```bash
flutter run
```

## Technical Requirements

- Flutter SDK
- Dart SDK
- Internet connection for WebSocket functionality
- Location services enabled for geolocation features


