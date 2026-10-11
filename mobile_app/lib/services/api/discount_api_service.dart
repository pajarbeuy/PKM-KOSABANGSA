import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../models/processed_product_discount.dart';
import 'api_client.dart';

class DiscountApiService {
  final ApiClient _client = ApiClient();

  /// Get discounts for Super Admin
  Future<Map<String, dynamic>> getSuperAdminDiscounts({
    int page = 1,
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
      };
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/discounts')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _client.getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List? list;
          Map<String, dynamic> pagination = {};
          if (data['data'] is Map<String, dynamic>) {
            final inner = data['data'] as Map<String, dynamic>;
            list = (inner['discounts'] ?? inner['data'] ?? inner['items']) as List?;
            pagination = (inner['pagination'] as Map<String, dynamic>?) ?? {
              'current_page': inner['current_page'],
              'last_page': inner['last_page'],
              'total': inner['total'],
              'per_page': inner['per_page'],
            };
          } else if (data['data'] is List) {
            list = data['data'] as List;
          }

          final items = list != null
              ? list
                  .whereType<Map<String, dynamic>>()
                  .map((item) => ProcessedProductDiscount.fromJson(item))
                  .toList()
              : <ProcessedProductDiscount>[];

          return {
            'success': true,
            'discounts': items,
            'pagination': pagination,
          };
        }
      }
      return {
        'success': false,
        'message': 'Gagal mengambil data diskon',
        'discounts': <ProcessedProductDiscount>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'discounts': <ProcessedProductDiscount>[],
      };
    }
  }

  /// Get active public catalog discounts
  Future<List<ProcessedProductDiscount>> getPublicDiscounts() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/catalog/discounts');
      final response = await http
          .get(uri, headers: _client.getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final list = data['data']['discounts'] as List?;
          if (list != null) {
            return list
                .whereType<Map<String, dynamic>>()
                .map((item) => ProcessedProductDiscount.fromJson(item))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Create discount
  Future<Map<String, dynamic>> createDiscount({
    required int processedProductId,
    required double discountPercentage,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/discounts');
      final response = await http
          .post(
            uri,
            headers: _client.getHeaders(),
            body: jsonEncode({
              'processed_product_id': processedProductId,
              'discount_percentage': discountPercentage,
              'start_date': startDate,
              'end_date': endDate,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Diskon berhasil dibuat',
          'discount': data['data'] != null
              ? ProcessedProductDiscount.fromJson(data['data'])
              : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal membuat diskon',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Update discount
  Future<Map<String, dynamic>> updateDiscount({
    required int id,
    required int processedProductId,
    required double discountPercentage,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/discounts/$id');
      final response = await http
          .put(
            uri,
            headers: _client.getHeaders(),
            body: jsonEncode({
              'processed_product_id': processedProductId,
              'discount_percentage': discountPercentage,
              'start_date': startDate,
              'end_date': endDate,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Diskon berhasil diperbarui',
          'discount': data['data'] != null
              ? ProcessedProductDiscount.fromJson(data['data'])
              : null,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memperbarui diskon',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Delete discount
  Future<Map<String, dynamic>> deleteDiscount(int id) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/discounts/$id');
      final response = await http
          .delete(uri, headers: _client.getHeaders())
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Diskon berhasil dihapus',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menghapus diskon',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
