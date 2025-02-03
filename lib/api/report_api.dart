import 'package:dio/dio.dart';
import 'package:who_location_app/config/app_config.dart';
import 'package:who_location_app/config/dio_config.dart';

class ReportApi {
  final void Function() _onUnauthorized;
  late final Dio _dio;

  ReportApi(void Function() onUnauthorized)
      : _onUnauthorized = onUnauthorized {
    _dio = DioConfig.createDio(onUnauthorized);
  }

  // List available reports.
  Future<List<dynamic>> listReports() async {
    try {
      final String url = AppConfig.listReportsEndpoint;
      final response = await _dio.get(url);
      if (response.statusCode == 401) {
        _onUnauthorized();
      }

      // If the server indicates no reports exist, return an empty list.
      if (response.data['message'] != null &&
          response.data['message'].toString().toLowerCase() == "no reports found") {
        return [];
      }
      
      final dynamic data = response.data['data'];
      
      if (data is Map<String, dynamic> && data.containsKey('files')) {
        final files = data['files'];
        if (files is List) {
          return files.whereType<Map<String, dynamic>>().toList();
        }
        return [];
      }
      
      if (data is String) {
        return [];
      } else if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      } else if (data is Map<String, dynamic>) {
        return data.values.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _onUnauthorized();
      }
      rethrow;
    }
  }

  // Download a report given its filename.
  Future<String> downloadReport(String filename) async {
    try {
      final String url = "${AppConfig.downloadReportEndpoint}/$filename";
      final response = await _dio.get(url);
      if (response.statusCode == 401) {
        _onUnauthorized();
      }
      if (response.data is Map<String, dynamic>) {
        return response.data['report_text'];
      } else if (response.data is String) {
        return response.data;
      }
      throw Exception("Unexpected response format");
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _onUnauthorized();
      }
      rethrow;
    }
  }

  // Delete a report (admin only).
  Future<void> deleteReport(String filename) async {
    try {
      final String url = "${AppConfig.deleteReportEndpoint}/$filename";
      await _dio.delete(url);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _onUnauthorized();
      }
      rethrow;
    }
  }

  // Generate a new report (admin only).
  // Accepts an optional DateTime and uses GET instead of POST.
  Future<Map<String, dynamic>> generateReport({DateTime? reportDate}) async {
    try {
      String url = AppConfig.generateReportEndpoint;
      if (reportDate != null) {
        final dateStr = "${reportDate.year.toString().padLeft(4, '0')}-${reportDate.month.toString().padLeft(2, '0')}-${reportDate.day.toString().padLeft(2, '0')}";
        url += "?date=$dateStr";
      }
      final response = await _dio.get(url);

      if (response.statusCode == 401) {
        _onUnauthorized();
      }
      return response.data['data'];
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _onUnauthorized();
      }
      rethrow;
    }
  }
}
