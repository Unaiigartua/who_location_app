class TaskLog {
  final int id;
  final int taskId;
  final String status;
  final int? assignedTo;
  final int modifiedBy;
  final String note;
  final DateTime timestamp;
  final String? modifiedByUsername;
  final String? assignedToUsername;

  TaskLog({
    required this.id,
    required this.taskId,
    required this.status,
    this.assignedTo,
    required this.modifiedBy,
    required this.note,
    required this.timestamp,
    this.modifiedByUsername,
    this.assignedToUsername,
  });

  factory TaskLog.fromJson(Map<String, dynamic> json) {
    return TaskLog(
      id: json['id'],
      taskId: json['task_id'],
      status: json['status'],
      assignedTo: json['assigned_to'],
      modifiedBy: json['modified_by'],
      note: json['note'],
      timestamp: DateTime.parse(json['timestamp']),
      modifiedByUsername: json['modified_by_username'],
      assignedToUsername: json['assigned_to_username'],
    );
  }
}
