// Import material package for IconData and Icons
import 'package:flutter/material.dart';

// Add formatStatus method to format task status
String formatStatus(String status) {
  switch (status.toLowerCase()) {
    case 'new':
      return 'Open';
    case 'in_progress':
      return 'Ongoing';
    case 'issue_reported':
      return 'Blocked';
    case 'completed':
      return 'Closed';
    default:
      return status;
  }
}

// Add getStatusIcon method to get the icon for task status
IconData getStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'new':
      return Icons.local_hospital; // Ambulance new tasks use hospital icon
    case 'in_progress':
      return Icons.cleaning_services; // Cleaning teams use cleaning icon
    case 'issue_reported':
      return Icons.warning; // Issue reported uses warning icon
    case 'completed':
      return Icons.verified; // Completed uses verified icon
    default:
      return Icons.help; // Default uses question mark icon
  }
}

// Add getStatusColor method to get the color for task status
Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'new':
      return Colors.red; // New tasks are represented in red to indicate urgency
    case 'in_progress':
      return Colors
          .amber; // In progress is represented in amber to indicate processing
    case 'issue_reported':
      return Colors
          .deepOrange; // Issues are represented in deep orange to indicate warning
    case 'completed':
      return Colors
          .green; // Completed is represented in green to indicate safety
    default:
      return Colors.grey;
  }
}
