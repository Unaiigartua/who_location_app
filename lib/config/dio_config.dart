import 'package:dio/dio.dart';
import 'package:who_location_app/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:who_location_app/config/auth_interceptor.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/services/navigation_service.dart';

class DioConfig {
  // 添加静态实例变量
  static Dio? _instance;

  static Dio createDio(VoidCallback onUnauthorized) {
    // 如果实例已存在，只更新 baseUrl
    if (_instance != null) {
      _instance!.options.baseUrl = AppConfig.apiBaseUrl;
      return _instance!;
    }

    // 否则创建新实例
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        contentType: 'application/json',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );

    // Add logging interceptor: logs request and response details if logging is enabled to aid debugging.
    if (AppConfig.enableLogging) {
      dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (object) {
          debugPrint('DIO LOG: $object');
        },
      ));
    }

    // Add authentication interceptor to automatically include token in request headers.
    dio.interceptors.add(AuthInterceptor());

    // Global error interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          // Skip error handling for login and register endpoints
          final String requestPath = error.requestOptions.path;
          if (requestPath.contains(AppConfig.loginEndpoint) ||
              requestPath.contains(AppConfig.registerEndpoint)) {
            return handler.next(error);
          }

          final context = navigatorKey.currentContext;
          if (context == null) return handler.next(error);

          // Handle 401 unauthorized error, redirect to login page
          if (error.response?.statusCode == 401) {
            debugPrint('Auth error detected: ${error.type}');
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            await authProvider.handleUnauthorized();
            return handler.reject(error);
          }

          // Show error message for all other errors
          _showErrorMessage(context, error);
          return handler.next(error);
        },
      ),
    );

    _instance = dio;
    return dio;
  }

  // Show error message
  static void _showErrorMessage(BuildContext context, DioException error) {
    String message;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout, please check your network settings';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Server response timeout, please try again later';
        break;
      case DioExceptionType.connectionError:
        message =
            'Unable to connect to server, please check your network connection';
        break;
      case DioExceptionType.badResponse:
        switch (error.response?.statusCode) {
          case 403:
            message = 'You do not have permission to access this resource';
            break;
          case 404:
            message = 'The requested resource does not exist';
            break;
          case 500:
            message = 'Internal server error';
            break;
          default:
            message = 'An error occurred: ${error.response?.statusCode}';
        }
        break;
      default:
        message = 'An unknown error occurred';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
