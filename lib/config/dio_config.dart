import 'package:dio/dio.dart';
import 'package:who_location_app/config/app_config.dart';
import 'package:who_location_app/utils/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:who_location_app/config/auth_interceptor.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/services/navigation_service.dart';

class DioConfig {
  static Dio createDio(VoidCallback onUnauthorized) {
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

    // Global error interceptor handles errors (including 401 Unauthorized).
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final String requestPath = error.requestOptions.path;
            // If the requested URL is not for login or register, call the unauthorized callback.
            if (!requestPath.contains(AppConfig.loginEndpoint) &&
                !requestPath.contains(AppConfig.registerEndpoint)) {
              debugPrint('Handling 401 error globally for path: $requestPath');
              final context = navigatorKey.currentContext;
              if (context != null) {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.handleUnauthorized();
              }
            }
            return handler.reject(error);
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}
