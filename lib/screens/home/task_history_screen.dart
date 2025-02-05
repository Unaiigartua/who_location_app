import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/task_provider.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/models/task.dart';
import 'package:go_router/go_router.dart';

class TaskHistoryScreen extends StatefulWidget {
  const TaskHistoryScreen({super.key});

  @override
  State<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    // Only load data once when initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  List<Task> _getFilteredTasks(
      List<Task> tasks, String? userRole, int? userId) {
    // Filter tasks based on user role, status, and search query.
    return tasks.where((task) {
      // Filter by user role first.
      bool isUserTask = false;
      switch (userRole) {
        case 'ambulance':
          isUserTask = task.createdBy == userId;
          break;
        case 'cleaning_team':
          isUserTask = task.assignedTo == userId;
          break;
        case 'admin':
          isUserTask = true;
          break;
        default:
          isUserTask = false;
      }

      // Then filter by status.
      if (_statusFilter != 'all' && task.status != _statusFilter) {
        return false;
      }

      // Finally, filter by search query.
      if (_searchQuery.isNotEmpty) {
        return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            task.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }

      return isUserTask;
    }).toList();
  }

  String _formatStatus(String status) {
    // Format the task status for display.
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

  void _onFilterChanged(String value) async {
    // Load new data first
    await context.read<TaskProvider>().loadTasks();

    // After data is loaded, update the filter state
    if (mounted) {
      setState(() {
        _statusFilter = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the UI for the task history screen, including task list and filters.
    final user = context.watch<AuthProvider>().user;
    final tasks = context.watch<TaskProvider>().tasks;
    final filteredTasks = _getFilteredTasks(tasks, user?.role, user?.id);

    return Scaffold(
      appBar: AppBar(
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Text(
              authProvider.user?.role == 'admin' ? 'All Tasks' : 'My Tasks',
            );
          },
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<TaskProvider>().loadTasks(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search tasks...',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.filter_list),
                        onSelected: _onFilterChanged,
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'all',
                            child: Text('All Tasks'),
                          ),
                          const PopupMenuItem(
                            value: 'new',
                            child: Text('Open'),
                          ),
                          const PopupMenuItem(
                            value: 'in_progress',
                            child: Text('Ongoing'),
                          ),
                          const PopupMenuItem(
                            value: 'issue_reported',
                            child: Text('Blocked'),
                          ),
                          const PopupMenuItem(
                            value: 'completed',
                            child: Text('Closed'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filteredTasks.isEmpty
                    ? const Center(
                        child: Text('No tasks found'),
                      )
                    : ListView.builder(
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return Card(
                            child: ListTile(
                              title: Text(task.title),
                              subtitle: Text(task.description),
                              trailing: Chip(
                                label: Text(_formatStatus(task.status)),
                                backgroundColor: _getStatusColor(task.status),
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                              ),
                              onTap: () => context.go('/tasks/${task.id}'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'issue_reported':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
