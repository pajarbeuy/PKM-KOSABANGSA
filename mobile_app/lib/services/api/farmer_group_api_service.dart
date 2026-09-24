import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../models/farmer_group.dart';
import 'api_client.dart';

class FarmerGroupApiService {
  final ApiClient _client = ApiClient();

  /// Get all active farmer groups (public or authenticated)
  Future<List<FarmerGroup>> getActiveFarmerGroups() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/farmer-groups'),
        headers: _client.getHeaders(includeAuth: false),
      );

      final data = _client.decodeApiResponse(response);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => FarmerGroup.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Super Admin: Get all farmer groups with member counts
  Future<List<FarmerGroup>> getSuperAdminFarmerGroups() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/super-admin/farmer-groups'),
        headers: _client.getHeaders(),
      );

      final data = _client.decodeApiResponse(response);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => FarmerGroup.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Super Admin: Get single farmer group with members
  Future<Map<String, dynamic>?> getFarmerGroupDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/super-admin/farmer-groups/$id'),
        headers: _client.getHeaders(),
      );

      final data = _client.decodeApiResponse(response);
      if (data['success'] == true && data['data'] is Map<String, dynamic>) {
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Super Admin: Assign/Move farmer to a Poktan
  Future<Map<String, dynamic>> assignMember(int userId, int farmerGroupId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/super-admin/users/$userId/assign-poktan'),
        headers: _client.getHeaders(),
        body: jsonEncode({'farmer_group_id': farmerGroupId}),
      );

      final data = _client.decodeApiResponse(response);
      return {
        'success': data['success'] ?? true,
        'message': data['message'] ?? 'Berhasil mengubah Kelompok Tani.',
        'data': data['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }
}
