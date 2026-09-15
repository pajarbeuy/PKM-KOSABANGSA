import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../models/stock.dart';
import 'api_client.dart';

class StockApiService {
  final ApiClient _client = ApiClient();

  Future<StockData?> getStock() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/stock'), headers: _client.getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return StockData.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> addStockTransaction({
    required String type, // 'in' or 'out'
    required int amount,
    String? notes,
  }) async {
    try {
      final endpoint = type == 'in' ? '/stock/in' : '/stock/out';
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: _client.getHeaders(),
            body: jsonEncode({
              'amount': amount,
              'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menyimpan transaksi stok',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
