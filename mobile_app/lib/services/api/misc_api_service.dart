import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import 'api_client.dart';

class MiscApiService {
  final ApiClient _client = ApiClient();

  // ==================== SETTINGS & PROFILE ====================

  Future<Map<String, dynamic>?> getSettings() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/settings'),
          headers: _client.getHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    final data = _client.decodeApiResponse(response);
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    }

    throw Exception(data['message'] ?? 'Gagal mengambil pengaturan');
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? farmName,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/settings/profile'),
            headers: _client.getHeaders(),
            body: jsonEncode({
              'name': name,
              'email': email,
              'phone': phone,
              'farm_name': farmName,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Profil gagal diperbarui',
        'data': data['data'],
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/settings/password'),
            headers: _client.getHeaders(),
            body: jsonEncode({
              'current_password': currentPassword,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Password gagal diperbarui',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/settings/account'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Akun gagal dihapus',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateWarehouseThresholds({
    required int minStock,
    required int maxStock,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/settings/gudang'),
            headers: _client.getHeaders(),
            body: jsonEncode({'min_stock': minStock, 'max_stock': maxStock}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Ambang batas gudang gagal diperbarui',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateNotifications({
    required bool notifyLowStock,
    required bool notifyNewSale,
    required bool notifyCost,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/settings/notifications'),
            headers: _client.getHeaders(),
            body: jsonEncode({
              'notify_low_stock': notifyLowStock,
              'notify_new_sale': notifyNewSale,
              'notify_cost': notifyCost,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Konfigurasi notifikasi gagal diperbarui',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== NOTIFICATIONS ====================

  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/notifications'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final dataMap = data['data'] as Map<String, dynamic>;
          final items = (dataMap['items'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ?? [];
          final unreadCount = dataMap['unread_count'] as int? ??
              items.where((item) => item['is_read'] == false).length;
          return {
            'items': items,
            'unread_count': unreadCount,
          };
        }
      }
      return {'items': [], 'unread_count': 0};
    } catch (e) {
      return {'items': [], 'unread_count': 0};
    }
  }

  Future<bool> markNotificationsAsRead({int? notificationId}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/notifications/read');
      final response = await http
          .post(
            uri,
            headers: _client.getHeaders(),
            body: jsonEncode({
              'notification_id': notificationId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ==================== FEEDBACK (USER) ====================

  Future<Map<String, dynamic>> sendFeedback(String message) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/feedback'),
            headers: _client.getHeaders(),
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success':
            response.statusCode >= 200 &&
            response.statusCode < 300 &&
            data['success'] == true,
        'message': data['message'] ?? 'Feedback gagal dikirim',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== CHATBOT ====================

  Future<Map<String, dynamic>> sendChatMessage(String message) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/chat'),
            headers: _client.getHeaders(includeAuth: false),
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'reply': data['reply'] ?? 'Maaf, terjadi kesalahan.',
        };
      } else {
        return {
          'success': false,
          'reply': data['reply'] ?? 'Maaf, terjadi kesalahan.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'reply': 'Gagal terhubung ke server. Pastikan server Laravel aktif.',
      };
    }
  }
}
