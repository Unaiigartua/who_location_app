import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/models/task.dart';
import 'package:go_router/go_router.dart';
import 'package:who_location_app/providers/task_provider.dart';
import 'package:who_location_app/utils/constants.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:who_location_app/widgets/add_task_dialog.dart';

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
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当 tab 切换到任务列表时刷新任务
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
      // 状态过滤
      if (_statusFilter != 'all' && task.status != _statusFilter) {
        return false;
      }
      // 搜索过滤
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
                    Text(taskProvider.error!),
                    ElevatedButton(
                      onPressed: () => taskProvider.loadTasks(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final filteredTasks = _getFilteredTasks(taskProvider.tasks);

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
                                onSelected: (value) {
                                  setState(() {
                                    _statusFilter = value;
                                  });
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
                          onPressed: _showAddTaskDialog,
                          child: const Icon(Icons.add_location_alt),
                          tooltip: 'Add New Task',
                        )
                      : null,
            );
          },
        );
      },
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
      default:
        return Colors.grey;
    }
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
}
