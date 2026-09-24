import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../api_config.dart';
import '../../models/processed_product.dart';
import 'api_client.dart';

class ProcessedProductApiService {
  final ApiClient _client = ApiClient();

  /// Get processed products for authenticated farmer
  Future<List<ProcessedProduct>> getFarmerProcessedProducts({
    int page = 1,
    String? search,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final uri = Uri.parse('${ApiConfig.baseUrl}/processed-products')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _client.getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final list = data['data']['products'] as List?;
          if (list != null) {
            return list
                .whereType<Map<String, dynamic>>()
                .map((item) => ProcessedProduct.fromJson(item))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get all processed products for Super Admin Marketing Management
  Future<List<ProcessedProduct>> getSuperAdminProcessedProducts({
    int page = 1,
    String? search,
    String? status,
    int? ownerId,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (ownerId != null) queryParams['owner_id'] = ownerId.toString();

      final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/processed-products')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _client.getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final list = data['data']['products'] as List?;
          if (list != null) {
            return list
                .whereType<Map<String, dynamic>>()
                .map((item) => ProcessedProduct.fromJson(item))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get public catalog products (active + out_of_stock)
  Future<List<ProcessedProduct>> getPublicCatalog({
    int page = 1,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('${ApiConfig.baseUrl}/catalog/processed-products')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _client.getHeaders(includeAuth: false))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final list = data['data']['products'] as List?;
          if (list != null) {
            return list
                .whereType<Map<String, dynamic>>()
                .map((item) => ProcessedProduct.fromJson(item))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get processed product details
  Future<ProcessedProduct?> getProcessedProduct(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/processed-products/$id'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return ProcessedProduct.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create a new processed product (Farmer)
  Future<Map<String, dynamic>> createProcessedProduct({
    required String name,
    required double price,
    int stock = 0,
    String? unit = 'pcs',
    String? description,
    String? status,
    XFile? photoFile,
  }) async {
    try {
      if (photoFile != null) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/processed-products');
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(_client.getHeaders(forMultipart: true));
        request.fields['name'] = name;
        request.fields['price'] = price.toString();
        request.fields['stock'] = stock.toString();
        if (unit != null && unit.isNotEmpty) request.fields['unit'] = unit;
        if (description != null && description.isNotEmpty) request.fields['description'] = description;
        if (status != null && status.isNotEmpty) request.fields['status'] = status;

        final photoBytes = await photoFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            photoBytes,
            filename: photoFile.name,
          ),
        );

        final streamed = await request.send().timeout(const Duration(seconds: 30));
        final response = await http.Response.fromStream(streamed);
        final data = jsonDecode(response.body);
        if (response.statusCode == 201) {
          return {'success': true, 'data': data['data'], 'message': data['message']};
        }
        return {'success': false, 'message': data['message'] ?? 'Gagal menambahkan produk'};
      }

      final payload = <String, dynamic>{
        'name': name,
        'price': price,
        'stock': stock,
        'unit': unit ?? 'pcs',
      };
      if (description != null && description.isNotEmpty) payload['description'] = description;
      if (status != null && status.isNotEmpty) payload['status'] = status;

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/processed-products'),
            headers: _client.getHeaders(),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data'], 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal menambahkan produk'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Update an existing processed product (Farmer)
  Future<Map<String, dynamic>> updateProcessedProduct(
    int id, {
    String? name,
    double? price,
    int? stock,
    String? unit,
    String? description,
    String? status,
    XFile? photoFile,
  }) async {
    try {
      if (photoFile != null) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/processed-products/$id');
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(_client.getHeaders(forMultipart: true));
        request.fields['_method'] = 'PUT';
        request.headers['X-HTTP-Method-Override'] = 'PUT';

        if (name != null) request.fields['name'] = name;
        if (price != null) request.fields['price'] = price.toString();
        if (stock != null) request.fields['stock'] = stock.toString();
        if (unit != null) request.fields['unit'] = unit;
        if (description != null) request.fields['description'] = description;
        if (status != null) request.fields['status'] = status;

        final photoBytes = await photoFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            photoBytes,
            filename: photoFile.name,
          ),
        );

        final streamed = await request.send().timeout(const Duration(seconds: 30));
        final response = await http.Response.fromStream(streamed);
        final data = jsonDecode(response.body);
        if (response.statusCode == 200) {
          return {'success': true, 'data': data['data'], 'message': data['message']};
        }
        return {'success': false, 'message': data['message'] ?? 'Gagal memperbarui produk'};
      }

      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name;
      if (price != null) payload['price'] = price;
      if (stock != null) payload['stock'] = stock;
      if (unit != null) payload['unit'] = unit;
      if (description != null) payload['description'] = description;
      if (status != null) payload['status'] = status;

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/processed-products/$id'),
            headers: _client.getHeaders(),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data'], 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal memperbarui produk'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Delete a processed product (Farmer)
  Future<bool> deleteProcessedProduct(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/processed-products/$id'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Super Admin toggles/updates product status
  Future<bool> updateStatusBySuperAdmin(int id, String status) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/processed-products/$id/status'),
            headers: _client.getHeaders(),
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
