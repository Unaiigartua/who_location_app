import 'package:flutter/material.dart';
import 'package:who_location_app/api/task_api.dart';
import 'package:who_location_app/models/task.dart';
import 'package:who_location_app/services/task_service.dart';
import 'package:who_location_app/config/dio_config.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/services/navigation_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskApi _taskApi;
  final TaskService _taskService;
  final VoidCallback onUnauthorized;
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  Task? _currentTask;
  bool _isLoadingDetails = false;
  Timer? _refreshTimer;
  int _version = 0;

  TaskProvider(this.onUnauthorized)
      : _taskApi = TaskApi(onUnauthorized),
        _taskService = TaskService(DioConfig.createDio(onUnauthorized));

  // Public method to start periodic task synchronization.
  void startPeriodicSync() {
    if (_refreshTimer == null) {
      _startPeriodicRefresh();
    }
  }

  void _startPeriodicRefresh() {
    debugPrint('Starting periodic refresh every 15 seconds.');
    _refreshTimer = Timer.periodic(const Duration(seconds: 120), (_) {
      debugPrint('Executing task synchronization');
      syncTaskUpdates();
    });
  }

  Future<void> syncTaskUpdates() async {
    debugPrint(
        'Starting syncTasks call in syncTaskUpdates (version: $_version)');
    bool hasChanged = false;
    try {
      final data = await _taskApi.syncTasks(currentVersion: _version);

      if (data['needs_sync'] == true) {
        final List<dynamic> tasksData = data['tasks'] as List<dynamic>;
        _tasks = tasksData
            .map((json) => Task.fromJson(json as Map<String, dynamic>))
            .toList();
        _version = data['version'];
        debugPrint(
            'Number of tasks synchronized: ${_tasks.length} | New version: $_version');
        hasChanged = true;
      } else {
        debugPrint('Client version is up-to-date, no changes.');
      }

      if (hasChanged) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Synchronization error: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Task? get currentTask => _currentTask;
  bool get isLoadingDetails => _isLoadingDetails;

  Future<void> loadTasks() async {
    if (navigatorKey.currentContext != null) {
      final authProvider = Provider.of<AuthProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      if (!authProvider.isAuthenticated) {
        return;
      }
    }

    if (_isLoading) return;

    scheduleMicrotask(() {
      if (!_isLoading) {
        _isLoading = true;
        _error = null;
        notifyListeners();
      }
    });

    debugPrint('loadTasks: Checking authentication status.');
    try {
      debugPrint('loadTasks: User is authenticated, proceeding to load tasks.');
      debugPrint('loadTasks: Starting task synchronization.');
      final data = await _taskApi.syncTasks();
      if (data['needs_sync'] == true) {
        final List<dynamic> tasksData = data['tasks'] as List<dynamic>;
        _tasks = tasksData
            .map((json) => Task.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      debugPrint('loadTasks: Task synchronization completed.');

      scheduleMicrotask(() {
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint(
          'loadTasks: Error occurred during task synchronization: $_error');
      scheduleMicrotask(() {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<Task?> getTaskById(String id) async {
    try {
      return await _taskApi.getTaskById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> loadTaskDetails(String taskId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final details = await _taskApi.getTaskById(taskId);
      _currentTask = details;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> createTask({
    required String title,
    required double latitude,
    required double longitude,
    String? description,
    String? assignedTo,
  }) async {
    try {
      _setLoading(true);
      final success = await _taskService.createTask(
        title: title,
        latitude: latitude,
        longitude: longitude,
        description: description,
        assignedTo: assignedTo,
      );
      if (success) {
        await loadTasks();
      }
      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTask({
    required int taskId,
    required String token,
    String? status,
    String? assignedTo,
    String? note,
  }) async {
    try {
      _setLoading(true);
      final success = await _taskService.updateTask(
        taskId: taskId,
        token: token,
        status: status,
        assignedTo: assignedTo,
        note: note,
      );
      if (success) {
        await loadTaskDetails(taskId.toString());
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getUserByRole(String token,
      [String? role]) async {
    try {
      return await _taskService.getUserByRole(token, role);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // Reset the provider state, stopping refresh and clearing tasks.
  void reset() {
    stopPeriodicRefresh();
    _tasks = [];
    _isLoading = false;
    _error = null;
    _currentTask = null;
    _isLoadingDetails = false;
    notifyListeners();
  }
}
