import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../api_config.dart';
import '../../models/harvest.dart';
import 'api_client.dart';

class HarvestApiService {
  final ApiClient _client = ApiClient();

  Future<List<Harvest>> getHarvests({int? seasonId}) async {
    try {
      final queryParams = <String, String>{};
      if (seasonId != null) queryParams['season_id'] = seasonId.toString();

      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/harvests',
            ).replace(queryParameters: queryParams),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final listData = data['data'] is Map
              ? (data['data']['harvests'] as List?)
              : (data['data'] as List?);
          if (listData != null) {
            return listData
                .whereType<Map<String, dynamic>>()
                .map((item) => Harvest.fromJson(item))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Harvest?> getHarvest(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/harvests/$id'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Harvest.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createHarvest({
    required int seasonId,
    int? commodityId,
    required String harvestDate,
    required int quantity,
    String? unit,
    required double weightKg,
    String? notes,
    String? status,
    XFile? photoFile,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/harvests');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_client.getHeaders(forMultipart: true));
      request.fields['season_id'] = seasonId.toString();
      if (commodityId != null) {
        request.fields['commodity_id'] = commodityId.toString();
      }
      request.fields['harvest_date'] = harvestDate;
      request.fields['quantity'] = quantity.toString();
      if (unit != null && unit.isNotEmpty) {
        request.fields['unit'] = unit;
      }
      request.fields['weight_kg'] = weightKg.toString();
      if (notes != null) {
        request.fields['notes'] = notes;
      }
      request.fields['status'] = status ?? 'recorded';

      if (photoFile != null) {
        final photoBytes = await photoFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            photoBytes,
            filename: photoFile.name,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {'success': true, 'data': Harvest.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menambah panen',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateHarvest(
    int id, {
    int? seasonId,
    int? commodityId,
    String? harvestDate,
    int? quantity,
    String? unit,
    double? weightKg,
    String? notes,
    String? status,
    XFile? photoFile,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/harvests/$id');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_client.getHeaders(forMultipart: true));
      request.fields['_method'] = 'PUT';
      request.headers['X-HTTP-Method-Override'] = 'PUT';

      if (seasonId != null) request.fields['season_id'] = seasonId.toString();
      if (commodityId != null) request.fields['commodity_id'] = commodityId.toString();
      if (harvestDate != null) request.fields['harvest_date'] = harvestDate;
      if (quantity != null) request.fields['quantity'] = quantity.toString();
      if (unit != null && unit.isNotEmpty) request.fields['unit'] = unit;
      if (weightKg != null) request.fields['weight_kg'] = weightKg.toString();
      if (notes != null) request.fields['notes'] = notes;
      if (status != null) request.fields['status'] = status;

      if (photoFile != null) {
        final photoBytes = await photoFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            photoBytes,
            filename: photoFile.name,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': Harvest.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengupdate panen',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteHarvest(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/harvests/$id'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menghapus panen',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
