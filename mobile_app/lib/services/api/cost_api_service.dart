import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../models/cost.dart';
import 'api_client.dart';

class CostApiService {
  final ApiClient _client = ApiClient();

  Future<List<Cost>> getCosts({int? seasonId}) async {
    try {
      final queryParams = <String, String>{};
      if (seasonId != null) queryParams['season_id'] = seasonId.toString();

      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/costs',
            ).replace(queryParameters: queryParams),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final listData = data['data'] is Map
              ? (data['data']['costs'] as List?)
              : (data['data'] as List?);
          if (listData != null) {
            return listData
                .whereType<Map<String, dynamic>>()
                .map((item) => Cost.fromJson(item))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createCost({
    required String date,
    int? seasonId,
    required String category,
    required double amount,
    String? notes,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/costs'),
            headers: _client.getHeaders(),
            body: jsonEncode({
              'date': date,
              'season_id': seasonId,
              'category': category,
              'amount': amount,
              'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {'success': true, 'data': Cost.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menambah biaya',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateCost(
    int id, {
    String? date,
    int? seasonId,
    String? category,
    double? amount,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (date != null) body['date'] = date;
      body['season_id'] = seasonId;
      if (category != null) body['category'] = category;
      if (amount != null) body['amount'] = amount;
      body['notes'] = notes;

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/costs/$id'),
            headers: _client.getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': Cost.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengupdate biaya',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteCost(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/costs/$id'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menghapus biaya',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
