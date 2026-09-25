import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../models/season.dart';
import 'api_client.dart';

class SeasonApiService {
  final ApiClient _client = ApiClient();

  Future<List<Season>> getSeasons({String? search, String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (search != null) queryParams['search'] = search;
      if (status != null) queryParams['status'] = status;

      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/seasons',
            ).replace(queryParameters: queryParams),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Season.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error in getSeasons: $e');
      return [];
    }
  }

  Future<Season?> getSeason(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/seasons/$id'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Season.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createSeason({
    required String name,
    int? commodityId,
    required String startDate,
    required String endDate,
    required String status,
    required double targetKg,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'name': name,
        'start_date': startDate,
        'end_date': endDate,
        'status': status,
        'target_kg': targetKg,
        'notes': notes,
      };
      if (commodityId != null) {
        body['commodity_id'] = commodityId;
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/seasons'),
            headers: _client.getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'season': Season.fromJson(data['data'] ?? {}),
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menambahkan musim tanam',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateSeason(
    int id, {
    required String name,
    int? commodityId,
    required String startDate,
    required String endDate,
    required String status,
    required double targetKg,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'name': name,
        'start_date': startDate,
        'end_date': endDate,
        'status': status,
        'target_kg': targetKg,
        'notes': notes,
      };
      if (commodityId != null) {
        body['commodity_id'] = commodityId;
      }

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/seasons/$id'),
            headers: _client.getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'season': Season.fromJson(data['data'] ?? {}),
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengubah musim tanam',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteSeason(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/seasons/$id'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menghapus musim tanam',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
