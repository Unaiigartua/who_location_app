import 'package:dio/dio.dart';
import 'package:who_location_app/config/app_config.dart';
import 'package:who_location_app/config/dio_config.dart';
import 'package:who_location_app/models/user.dart';
import 'package:flutter/material.dart';

class AuthApi {
  late final Dio _dio;

  AuthApi(VoidCallback onUnauthorized) {
    _dio = DioConfig.createDio(onUnauthorized);
  }

  Future<User> login(String username, String password) async {
    try {
      debugPrint('Attempting login for user: $username');
      final response = await _dio.post(AppConfig.loginEndpoint, data: {
        'username': username,
        'password': password,
      });
      debugPrint('Login response: ${response.data}');
      debugPrint('Token from response: ${response.data['data']['token']}');

      return User.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('Login error: $e');
      if (e is DioException) {
        debugPrint('DioError details: ${e.response?.data}');
        if (e.response?.statusCode == 401) {
          throw 'Invalid username or password';
        }
      }
      throw 'Failed to login. Please try again.';
    }
  }

  Future<User> register(String username, String password, String role) async {
    try {
      debugPrint('Attempting register for user: $username with role: $role');
      final response = await _dio.post(AppConfig.registerEndpoint, data: {
        'username': username,
        'password': password,
        'role': role,
      });
      debugPrint('Register response: ${response.data}');

      return User.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('Register error: $e');
      if (e is DioException) {
        debugPrint('DioError details: ${e.response?.data}');
        if (e.response?.statusCode == 400) {
          throw 'Username already exists';
        }
      }
      throw 'Failed to register. Please try again.';
    }
  }
}
