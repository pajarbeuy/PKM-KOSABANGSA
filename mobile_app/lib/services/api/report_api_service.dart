import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import 'api_client.dart';

class ReportApiService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>?> getProfitLossReport({int? seasonId}) async {
    try {
      final url = seasonId != null
          ? '${ApiConfig.baseUrl}/reports/profit-loss?season_id=$seasonId'
          : '${ApiConfig.baseUrl}/reports/profit-loss';
      final response = await http
          .get(Uri.parse(url), headers: _client.getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getTargetVsActualReport() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/reports/target-vs-actual'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as List;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<int>?> downloadProfitLossReportPdf({int? seasonId}) async {
    try {
      final url = seasonId != null
          ? '${ApiConfig.baseUrl}/reports/export/profit-loss/pdf?season_id=$seasonId'
          : '${ApiConfig.baseUrl}/reports/export/profit-loss/pdf';
      final response = await http
          .get(Uri.parse(url), headers: _client.getHeaders())
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('pdf') || contentType.contains('octet-stream')) {
          return response.bodyBytes;
        } else {
          throw Exception('Server error: ${response.body}');
        }
      } else {
        try {
          final data = jsonDecode(response.body);
          throw Exception('HTTP ${response.statusCode}: ${data['message'] ?? response.body}');
        } catch (parseErr) {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('downloadProfitLossReportPdf error: $e');
      rethrow;
    }
  }

  Future<List<int>?> downloadTargetVsActualReportPdf() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/reports/export/target-vs-actual/pdf'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('pdf') || contentType.contains('octet-stream')) {
          return response.bodyBytes;
        } else {
          throw Exception('Server error: ${response.body}');
        }
      } else {
        try {
          final data = jsonDecode(response.body);
          throw Exception('HTTP ${response.statusCode}: ${data['message'] ?? response.body}');
        } catch (parseErr) {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('downloadTargetVsActualReportPdf error: $e');
      rethrow;
    }
  }
}
