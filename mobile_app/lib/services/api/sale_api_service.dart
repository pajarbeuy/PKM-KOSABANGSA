import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../models/sale.dart';
import 'api_client.dart';

class SaleApiService {
  final ApiClient _client = ApiClient();

  Future<List<Sale>> getSales() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/sales'), headers: _client.getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final listData = data['data'] is Map
              ? (data['data']['sales'] as List?)
              : (data['data'] as List?);
          if (listData != null) {
            return listData
                .whereType<Map<String, dynamic>>()
                .map((item) => Sale.fromJson(item))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Sale?> getSale(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/sales/$id'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Sale.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createSale({
    required int quantity,
    required int pricePerUnit,
    required String saleDate,
    required String buyerName,
    String? buyerPhone,
    String? buyerAddress,
    String? notes,
    String? status,
    String? paymentStatus,
    int? seasonId,
  }) async {
    try {
      final body = <String, dynamic>{
        'quantity': quantity,
        'price_per_unit': pricePerUnit,
        'sale_date': saleDate,
        'buyer_name': buyerName,
        'buyer_phone': buyerPhone,
        'buyer_address': buyerAddress,
        'notes': notes,
        'status': status ?? 'completed',
        'payment_status': paymentStatus ?? 'paid',
      };
      
      if (seasonId != null) {
        body['season_id'] = seasonId;
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/sales'),
            headers: _client.getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {'success': true, 'data': Sale.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menambah penjualan',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateSale(
    int id, {
    int? quantity,
    int? pricePerUnit,
    String? saleDate,
    String? buyerName,
    String? buyerPhone,
    String? buyerAddress,
    String? notes,
    String? status,
    String? paymentStatus,
    int? seasonId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (quantity != null) body['quantity'] = quantity;
      if (pricePerUnit != null) body['price_per_unit'] = pricePerUnit;
      if (saleDate != null) body['sale_date'] = saleDate;
      if (buyerName != null) body['buyer_name'] = buyerName;
      body['buyer_phone'] = buyerPhone;
      body['buyer_address'] = buyerAddress;
      body['notes'] = notes;
      if (status != null) body['status'] = status;
      if (paymentStatus != null) body['payment_status'] = paymentStatus;
      if (seasonId != null) body['season_id'] = seasonId;

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/sales/$id'),
            headers: _client.getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': Sale.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengupdate penjualan',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteSale(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/sales/$id'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menghapus penjualan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
