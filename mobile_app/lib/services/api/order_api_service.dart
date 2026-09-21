import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../models/order_model.dart';
import 'api_client.dart';

class OrderApiService {
  final ApiClient _client = ApiClient();

  /// Super Admin: List orders with optional status filter and search query.
  Future<List<OrderModel>> getSuperAdminOrders({
    String? status,
    String? search,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
      };
      if (status != null && status.isNotEmpty && status != 'all') {
        queryParams['status'] = status;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/orders')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _client.getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final listData = data['data'] is Map
              ? (data['data']['orders'] as List?)
              : (data['data'] as List?);

          if (listData != null) {
            return listData
                .whereType<Map<String, dynamic>>()
                .map((item) => OrderModel.fromJson(item))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Super Admin: Get single order detail.
  Future<OrderModel?> getSuperAdminOrderDetail(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/orders/$id'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return OrderModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Super Admin: Update status to 'confirmed' or 'processing'.
  Future<Map<String, dynamic>> updateOrderStatus(int id, String status) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/orders/$id/status'),
            headers: _client.getHeaders(),
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? (response.statusCode == 200 ? 'Status berhasil diperbarui' : 'Gagal memperbarui status'),
        'data': data['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal memperbarui status: $e'};
    }
  }

  /// Super Admin: Complete order (creates Sale and decrements stock atomically).
  Future<Map<String, dynamic>> completeOrder(int id) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/orders/$id/complete'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? (response.statusCode == 200 ? 'Pesanan berhasil diselesaikan' : 'Gagal menyelesaikan pesanan'),
        'data': data['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal menyelesaikan pesanan: $e'};
    }
  }

  /// Super Admin: Cancel order.
  Future<Map<String, dynamic>> cancelOrder(int id) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/orders/$id/cancel'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? (response.statusCode == 200 ? 'Pesanan berhasil dibatalkan' : 'Gagal membatalkan pesanan'),
        'data': data['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal membatalkan pesanan: $e'};
    }
  }
}
