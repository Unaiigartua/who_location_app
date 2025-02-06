import 'package:who_location_app/models/task_log.dart';

class Task {
  final int id;
  final String title;
  final String description;
  final String status;
  final Map<String, double> location;
  final int createdBy;
  final int? assignedTo;
  final List<int> historicalAssignees;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<TaskLog>? logs;

  Task({
    required this.id,
    required this.title,
    String? description,
    required this.status,
    required this.location,
    required this.createdBy,
    this.assignedTo,
    List<int>? historicalAssignees,
    required this.createdAt,
    this.updatedAt,
    this.logs,
  })  : description = description ?? '',
        historicalAssignees = historicalAssignees ?? [];

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'],
      status: json['status'] as String,
      location: {
        'latitude': json['location']['latitude'].toDouble(),
        'longitude': json['location']['longitude'].toDouble(),
      },
      createdBy: json['created_by'] as int,
      assignedTo: json['assigned_to'] as int?,
      historicalAssignees: (json['historical_assignees'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      logs: json['logs'] != null
          ? (json['logs'] as List).map((log) => TaskLog.fromJson(log)).toList()
          : null,
    );
  }
}
