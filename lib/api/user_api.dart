import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:who_location_app/config/app_config.dart';
import 'package:who_location_app/config/dio_config.dart';

class UserApi {
  final VoidCallback _onUnauthorized;
  late final Dio _dio;

  UserApi(VoidCallback onUnauthorized)
      : _onUnauthorized = onUnauthorized {
    _dio = DioConfig.createDio(onUnauthorized);
  }

  // Function to delete a user given their ID.
  Future<void> deleteUser(int userId) async {
    try {
      final String url = '${AppConfig.deleteUserEndpoint}/$userId';
      debugPrint('Sending DELETE request to $url');
      final response = await _dio.delete(url);
      if (response.statusCode == 401) {
        _onUnauthorized();
      }
      debugPrint('Deletion response: ${response.data}');
      return;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _onUnauthorized();
      }
      debugPrint('Error deleting user: $e');
      throw e;
    } catch (e) {
      debugPrint('Unexpected error in deleteUser: $e');
      throw e;
    }
  }
}
