import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/task_provider.dart';
import 'package:who_location_app/models/task.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/widgets/task_details_widget.dart';
import 'package:who_location_app/dialogs/add_note_dialog.dart';
import 'package:who_location_app/dialogs/handle_task_dialog.dart';
import 'package:who_location_app/dialogs/report_issues_dialog.dart';
import 'package:who_location_app/dialogs/edit_task_dialog.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTaskDetails();
    });
  }

  Future<void> _loadTaskDetails() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await taskProvider.loadTaskDetails(widget.taskId);
    if (!mounted) return; // Make sure the widget is still mounted
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true); // When returning, pass true to refresh
          },
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoadingDetails) {
            return const Center(child: CircularProgressIndicator());
          }
          // Load task details for the task detail screen in _currentTask
          final task = taskProvider.currentTask;
          if (task == null) {
            return const Center(child: Text('Task not found'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TaskInfoWidget(task: task),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Task History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildActionButton(task),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: TaskLogsWidget(
                  task: task,
                  onRefresh: () async {
                    await context
                        .read<TaskProvider>()
                        .loadTaskDetails(widget.taskId);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton(Task task) {
    final userRole = context.read<AuthProvider>().user?.role;
    final userId = context.read<AuthProvider>().user?.id;

    if (task.status == 'completed') {
      return Container(); // No mostrar botón
    }

    if (task.status == 'new') {
      if (userRole == 'ambulance') {
        return task.assignedTo == userId
            ? _buildAddNoteButton(task)
            : Container();
      } else if (userRole == 'cleaning_team') {
        return _buildHandleButton(task); // Permitir manejar la tarea
      }
    }

    if (task.status == 'in_progress') {
      if (userRole == 'cleaning_team') {
        return task.assignedTo == userId
            ? Row(
                children: [
                  _buildAddNoteButton(task),
                  const SizedBox(width: 8),
                  _buildReportIssuesButton(task),
                ],
              )
            : Container();
      }
    }

    if (task.status == 'issue_reported') {
      if (userRole == 'cleaning_team') {
        return task.assignedTo == userId
            ? _buildAddNoteButton(task)
            : _buildHandleButton(task);
      }
    }

    if (userRole == 'admin') {
      return Row(
        children: [
          _buildAddNoteButton(task),
          const SizedBox(width: 8),
          _buildEditTaskButton(task),
        ],
      );
    }

    return Container(); // Default, no mostrar botón
  }

  Widget _buildAddNoteButton(Task task) {
    return ElevatedButton(
      onPressed: () => showAddNoteDialog(context, task, widget.taskId),
      child: const Text('Add Note'),
    );
  }

  Widget _buildHandleButton(Task task) {
    return ElevatedButton(
      onPressed: () => showHandleTaskDialog(context, task, widget.taskId),
      child: const Text('Handle'),
    );
  }

  Widget _buildReportIssuesButton(Task task) {
    return ElevatedButton(
      onPressed: () => showReportIssuesDialog(context, task, widget.taskId),
      child: const Text('Report Issues'),
    );
  }

  Widget _buildEditTaskButton(Task task) {
    return ElevatedButton(
      onPressed: () => showEditTaskDialog(context, task, widget.taskId),
      child: const Text('Edit Task'),
    );
  }
}
