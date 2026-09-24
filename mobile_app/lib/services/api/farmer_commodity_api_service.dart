import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../models/farmer_commodity.dart';
import 'api_client.dart';

class FarmerCommodityApiService {
  final ApiClient _client = ApiClient();

  /// Get list of commodities belonging to the current farmer.
  Future<List<FarmerCommodity>> getFarmerCommodities({bool activeOnly = false}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/commodities').replace(
        queryParameters: activeOnly ? {'active_only': '1'} : null,
      );

      final response = await http.get(
        uri,
        headers: _client.getHeaders(),
      );

      final data = _client.decodeApiResponse(response);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => FarmerCommodity.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get details of a single commodity.
  Future<FarmerCommodity?> getCommodityDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/commodities/$id'),
        headers: _client.getHeaders(),
      );

      final data = _client.decodeApiResponse(response);
      if (data['success'] == true && data['data'] is Map<String, dynamic>) {
        return FarmerCommodity.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create a new commodity for the farmer.
  Future<Map<String, dynamic>> createCommodity(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/commodities'),
        headers: _client.getHeaders(),
        body: jsonEncode(payload),
      );

      final data = _client.decodeApiResponse(response);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Komoditas hasil tani berhasil ditambahkan.',
        'data': data['data'] != null ? FarmerCommodity.fromJson(data['data']) : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// Update an existing commodity.
  Future<Map<String, dynamic>> updateCommodity(int id, Map<String, dynamic> payload) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/commodities/$id'),
        headers: _client.getHeaders(),
        body: jsonEncode(payload),
      );

      final data = _client.decodeApiResponse(response);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Komoditas hasil tani berhasil diperbarui.',
        'data': data['data'] != null ? FarmerCommodity.fromJson(data['data']) : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// Delete a commodity.
  Future<Map<String, dynamic>> deleteCommodity(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/commodities/$id'),
        headers: _client.getHeaders(),
      );

      final data = _client.decodeApiResponse(response);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Komoditas hasil tani berhasil dihapus.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// Super Admin: Get all commodities across all farmers with filters.
  Future<List<FarmerCommodity>> getSuperAdminCommodities({
    int? userId,
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['user_id'] = userId.toString();
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/commodities').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: _client.getHeaders(),
      );

      final data = _client.decodeApiResponse(response);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => FarmerCommodity.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Super Admin: Update a farmer's commodity for administrative/monitoring purposes.
  Future<Map<String, dynamic>> updateSuperAdminCommodity(int id, Map<String, dynamic> payload) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/super-admin/commodities/$id'),
        headers: _client.getHeaders(),
        body: jsonEncode(payload),
      );

      final data = _client.decodeApiResponse(response);
      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Komoditas berhasil diperbarui oleh Admin.',
        'data': data['data'] != null ? FarmerCommodity.fromJson(data['data']) : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }
}
