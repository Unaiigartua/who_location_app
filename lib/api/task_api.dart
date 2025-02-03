import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:who_location_app/config/app_config.dart';
import 'package:who_location_app/config/dio_config.dart';
import 'package:who_location_app/models/task.dart';

class TaskApi {
  final Dio _dio;
  final VoidCallback onUnauthorized;

  TaskApi(this.onUnauthorized)
      : _dio = DioConfig.createDio(onUnauthorized) {
    // Allow status codes less than 500.
    _dio.options.validateStatus = (status) {
      return status != null && status < 500;
    };
  }

  Future<List<Task>> getTasks() async {
    try {
      debugPrint('Fetching tasks from: ${AppConfig.tasksEndpoint}');
      final response = await _dio.get(AppConfig.tasksEndpoint);
      debugPrint('Response: ${response.data}');
      
      final List<dynamic> data = response.data['data'] as List;
      if (response.statusCode == 401) {
        onUnauthorized();
      }
      return data.map((json) => Task.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        onUnauthorized(); // Callback invoked to handle 401 responses
      }
      debugPrint('Error loading tasks: $e');
      debugPrint('DioError details: ${e.response?.data}');
      debugPrint('DioError message: ${e.message}');
      debugPrint('DioError type: ${e.type}');
      throw 'Failed to load tasks: ${e.toString()}';
    }
  }

  Future<Task> getTaskById(String id) async {
    try {
      final response = await _dio.get('${AppConfig.tasksEndpoint}/$id');
      if (response.statusCode == 401) {
        onUnauthorized();
      }
      return Task.fromJson(response.data['data']['task']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        onUnauthorized();
      }
      debugPrint('Error loading task details: $e');
      throw 'Failed to load task details';
    }
  }

  Future<Map<String, dynamic>> syncTasks({int currentVersion = 0}) async {
    try {
      final response = await _dio.get(
        AppConfig.syncroniceTasksEndpoint,
        queryParameters: {'version': currentVersion},
      );
      if (response.statusCode == 304) {
        // No update required.
        return {'needs_sync': false, 'version': currentVersion};
      }else if (response.statusCode == 401) {
        onUnauthorized();
      }
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        onUnauthorized();
      }
      throw 'Failed to sync tasks: ${e.toString()}';
    }
  }
}
