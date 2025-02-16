import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/task_provider.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/models/task.dart';
import 'package:who_location_app/utils/helpers.dart';
import 'package:who_location_app/screens/home/task_detail_screen.dart';

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
        case 'cleaning_team':
          isUserTask = task.historicalAssignees.contains(userId);
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

    // Sort tasks from newest to oldest
    filteredTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tasks found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () =>
                                context.read<TaskProvider>().loadTasks(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return Card(
                            child: ListTile(
                              title: Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                task.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Chip(
                                label: Text(_formatStatus(task.status)),
                                backgroundColor: _getStatusColor(task.status),
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TaskDetailScreen(
                                        taskId: task.id.toString()),
                                  ),
                                ).then((result) {
                                  if (result == true) {
                                    // 如果返回结果为true，刷新任务列表
                                    context.read<TaskProvider>().loadTasks();
                                  }
                                });
                              },
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
    return getStatusColor(status);
  }

  String _formatStatus(String status) {
    return formatStatus(status);
  }
}
