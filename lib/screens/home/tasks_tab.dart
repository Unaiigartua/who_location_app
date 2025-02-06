import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/models/task.dart';
import 'package:go_router/go_router.dart';
import 'package:who_location_app/providers/task_provider.dart';
import 'package:who_location_app/utils/constants.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:who_location_app/dialogs/add_task_dialog.dart';
import 'package:who_location_app/utils/helpers.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab>
    with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';
  String _statusFilter = 'all';
  Position? _currentPosition;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<TaskProvider>().loadTasks();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Use default location if unable to get current position.
      _currentPosition = Position(
        latitude: 45.4642,
        longitude: 9.1900,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  List<Task> _getFilteredTasks(List<Task> tasks) {
    // Filter tasks based on status and search query.
    return tasks.where((task) {
      if (_statusFilter != 'all' && task.status != _statusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            task.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const Center(
            child: Text('Please login first'),
          );
        }

        return Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            if (taskProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (taskProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load tasks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => taskProvider.loadTasks(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              );
            }

            final filteredTasks = _getFilteredTasks(taskProvider.tasks);

            // Sort tasks from newest to oldest
            filteredTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return Scaffold(
              body: RefreshIndicator(
                onRefresh: () => taskProvider.loadTasks(),
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
                                onSelected: (value) async {
                                  // Load new data first
                                  await context
                                      .read<TaskProvider>()
                                      .loadTasks();

                                  // After data is loaded, update the filter state
                                  if (mounted) {
                                    setState(() {
                                      _statusFilter = value;
                                    });
                                  }
                                },
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
                                    onPressed: () => taskProvider.loadTasks(),
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
                                        backgroundColor:
                                            _getStatusColor(task.status),
                                        labelStyle: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      onTap: () =>
                                          context.go('/tasks/${task.id}'),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              floatingActionButton:
                  authProvider.user?.role == AppConstants.roleAmbulance ||
                          authProvider.user?.role == AppConstants.roleAdmin
                      ? FloatingActionButton(
                          tooltip: 'Add New Task',
                          onPressed: _showAddTaskDialog,
                          child: const Icon(Icons.add_location_alt),
                        )
                      : null,
            );
          },
        );
      },
    );
  }

  void _showAddTaskDialog() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        initialPosition: _currentPosition,
      ),
    );
  }

  String _formatStatus(String status) {
    return formatStatus(status);
  }

  Color _getStatusColor(String status) {
    return getStatusColor(status);
  }
}
