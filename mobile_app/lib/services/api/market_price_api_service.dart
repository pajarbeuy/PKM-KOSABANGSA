import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../models/market_price.dart';
import 'api_client.dart';

class MarketPriceApiService {
  final ApiClient _client = ApiClient();

  /// Mengambil daftar harga pasar acuan terpaginasi.
  Future<Map<String, dynamic>> getMarketPrices({
    int? commodityId,
    String? fromDate,
    String? toDate,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (commodityId != null) queryParams['commodity_id'] = commodityId.toString();
      if (fromDate != null && fromDate.isNotEmpty) queryParams['from_date'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) queryParams['to_date'] = toDate;

      final uri = Uri.parse('${ApiConfig.baseUrl}/market-prices').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: _client.getHeaders(),
      );

      final data = _client.decodeApiResponse(response);
      if (data['success'] == true && data['data'] != null) {
        final payload = data['data'];
        final rawPrices = payload['market_prices'];
        final List<MarketPrice> list = (rawPrices is List)
            ? rawPrices.map((item) => MarketPrice.fromJson(item)).toList()
            : [];
        final pagination = payload['pagination'] as Map<String, dynamic>? ?? {};

        return {
          'success': true,
          'market_prices': list,
          'pagination': pagination,
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal memuat harga pasar acuan.',
        'market_prices': <MarketPrice>[],
        'pagination': {},
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
        'market_prices': <MarketPrice>[],
        'pagination': {},
      };
    }
  }

  /// Mengambil harga pasar efektif terkini untuk komoditas tertentu.
  Future<MarketPrice?> getLatestPrice(int commodityId, {String? date}) async {
    try {
      final queryParams = <String, String>{};
      if (date != null && date.isNotEmpty) queryParams['date'] = date;

      final uri = Uri.parse('${ApiConfig.baseUrl}/market-prices/latest/$commodityId').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: _client.getHeaders(),
      );

      final data = _client.decodeApiResponse(response);
      if (data['success'] == true && data['data'] is Map<String, dynamic>) {
        return MarketPrice.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Menambah master harga pasar acuan baru (Super Admin only).
  Future<Map<String, dynamic>> createMarketPrice(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/market-prices'),
        headers: _client.getHeaders(),
        body: jsonEncode(payload),
      );

      final data = _client.decodeApiResponse(response);
      return {
        'success': response.statusCode == 201 || data['success'] == true,
        'message': data['message'] ?? (response.statusCode == 201 ? 'Berhasil menambahkan harga acuan.' : 'Gagal.'),
        'data': data['data'] != null ? MarketPrice.fromJson(data['data']) : null,
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal: $e'};
    }
  }

  /// Memperbarui record harga pasar acuan (Super Admin only).
  Future<Map<String, dynamic>> updateMarketPrice(int id, Map<String, dynamic> payload) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/market-prices/$id'),
        headers: _client.getHeaders(),
        body: jsonEncode(payload),
      );

      final data = _client.decodeApiResponse(response);
      return {
        'success': response.statusCode == 200 || data['success'] == true,
        'message': data['message'] ?? (response.statusCode == 200 ? 'Berhasil memperbarui harga acuan.' : 'Gagal.'),
        'data': data['data'] != null ? MarketPrice.fromJson(data['data']) : null,
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal: $e'};
    }
  }

  /// Menghapus record harga pasar acuan (Super Admin only).
  Future<Map<String, dynamic>> deleteMarketPrice(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/market-prices/$id'),
        headers: _client.getHeaders(),
      );

      final data = _client.decodeApiResponse(response);
      return {
        'success': response.statusCode == 200 || data['success'] == true,
        'message': data['message'] ?? (response.statusCode == 200 ? 'Berhasil menghapus harga acuan.' : 'Gagal.'),
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal: $e'};
    }
  }

  /// Trigger sinkronisasi/ingestion harga pasar (Super Admin only).
  Future<Map<String, dynamic>> triggerIngest({String? date}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/market-prices/ingest'),
        headers: _client.getHeaders(),
        body: jsonEncode(date != null ? {'date': date} : {}),
      );

      final data = _client.decodeApiResponse(response);
      return {
        'success': response.statusCode == 200 || data['success'] == true,
        'message': data['message'] ?? 'Sinkronisasi harga pasar berhasil dijalankan.',
        'data': data['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal: $e'};
    }
  }
}
