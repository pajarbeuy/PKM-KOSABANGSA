import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../models/user.dart';
import 'api_client.dart';

class SuperAdminApiService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>?> getSuperAdminDashboard() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/super-admin/dashboard'),
          headers: _client.getHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    final data = _client.decodeApiResponse(response);
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    }

    throw Exception(data['message'] ?? 'Gagal mengambil data dashboard super admin');
  }

  Future<List<dynamic>> getSuperAdminUsers() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/users'),
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

  Future<Map<String, dynamic>> createSuperAdminUser(
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/users'),
            headers: _client.getHeaders(),
            body: jsonEncode(userData),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201 && data['success'] == true,
        'message': data['message'] ?? 'Gagal membuat user',
        'data': data['data'],
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateSuperAdminUser(
    int id,
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/users/$id'),
            headers: _client.getHeaders(),
            body: jsonEncode(userData),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Gagal memperbarui user',
        'data': data['data'],
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteSuperAdminUser(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/users/$id'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Gagal menghapus user',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> impersonateUser(int id) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/users/$id/impersonate'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'token': data['data']['token'],
          'user': User.fromJson(data['data']['user']),
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal masuk sebagai user tersebut',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> getLandingContent() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/landing'),
          headers: _client.getHeaders(includeAuth: false),
        )
        .timeout(const Duration(seconds: 15));

    final data = _client.decodeApiResponse(response);
    if (data['success'] == true) {
      final rawData = data['data'];
      if (rawData is Map<String, dynamic>) {
        return rawData;
      }
      return <String, dynamic>{};
    }

    throw Exception(data['message'] ?? 'Gagal mengambil konten landing page');
  }

  Future<Map<String, dynamic>> updateLandingContent(
    Map<String, String> landingData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/landing'),
            headers: _client.getHeaders(),
            body: jsonEncode(landingData),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Gagal memperbarui landing page',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<dynamic>> getDashboardMenus() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/menus'),
          headers: _client.getHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    final data = _client.decodeApiResponse(response);
    if (data['success'] == true && data['data'] != null) {
      return data['data'] as List;
    }

    throw Exception(data['message'] ?? 'Gagal mengambil daftar menu dashboard');
  }

  Future<Map<String, dynamic>> createDashboardMenu(
    Map<String, dynamic> menuData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/menus'),
            headers: _client.getHeaders(),
            body: jsonEncode(menuData),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201 && data['success'] == true,
        'message': data['message'] ?? 'Gagal membuat menu',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateDashboardMenu(
    int id,
    Map<String, dynamic> menuData,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/menus/$id'),
            headers: _client.getHeaders(),
            body: jsonEncode(menuData),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Gagal memperbarui menu',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteDashboardMenu(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/menus/$id'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Gagal menghapus menu',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<dynamic>> getFeedbacks() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/feedbacks'),
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

  Future<Map<String, dynamic>> markFeedbackAsRead(int id) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/feedbacks/$id/read'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Gagal menandai feedback sudah dibaca',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteFeedback(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/feedbacks/$id'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Gagal menghapus feedback',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
