import 'package:dio/dio.dart';
import 'package:who_location_app/config/app_config.dart';

class TaskService {
  final Dio _dio;
  final void Function()? onUnauthorized;

  TaskService(this._dio, [this.onUnauthorized]);

  Future<bool> createTask({
    required String title,
    required double latitude,
    required double longitude,
    String? description,
    String? assignedTo,
  }) async {
    try {
      final response = await _dio.post(
        '/api/tasks',
        data: {
          'title': title,
          'description': description,
          'location': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'assigned_to': assignedTo,
        },
      );
      return response.statusCode == 201;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        onUnauthorized?.call();
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserByRole(String token, String? role) async {
    try {
      Response response;
      final String url = '${AppConfig.apiBaseUrl}/api/auth/users';
      if (role != null) {
        response = await _dio.get(
          url,
          queryParameters: {'role': role},
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      } else {
        response = await _dio.get(
          url,
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      }
      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        return data.map((user) => {
          'id': user['id'],
          'username': user['username'],
          'role': user['role'],
        }).toList();
      } else if (response.statusCode == 401) {
        onUnauthorized?.call();
        return [];
      } else {
        throw Exception('Failed to load Users');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        onUnauthorized?.call();
      }
      rethrow;
    }
  }

  Future<bool> updateTask({
    required int taskId,
    required String token,
    String? status,
    String? assignedTo,
    String? note,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/tasks/$taskId',
        data: {
          if (status != null) 'status': status,
          if (assignedTo != null) 'assigned_to': assignedTo,
          if (note != null) 'note': note,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        onUnauthorized?.call();
      }
      rethrow;
    }
  }
}
