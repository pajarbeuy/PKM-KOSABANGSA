import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../api_config.dart';
import '../../models/news_article.dart';
import 'api_client.dart';

class NewsApiService {
  final ApiClient _client = ApiClient();

  /// Get public published news articles
  Future<Map<String, dynamic>> getPublicNews({
    int page = 1,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('${ApiConfig.baseUrl}/news')
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
            list = (inner['news'] ?? inner['data'] ?? inner['items']) as List?;
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
                  .map((item) => NewsArticle.fromJson(item))
                  .toList()
              : <NewsArticle>[];

          return {
            'success': true,
            'news': items,
            'pagination': pagination,
          };
        }
      }
      return {
        'success': false,
        'message': 'Gagal mengambil berita',
        'news': <NewsArticle>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'news': <NewsArticle>[],
      };
    }
  }

  /// Get single public news by slug
  Future<NewsArticle?> getPublicNewsBySlug(String slug) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/news/$slug');
      final response = await http
          .get(uri, headers: _client.getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return NewsArticle.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get all news for Super Admin
  Future<Map<String, dynamic>> getSuperAdminNews({
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

      final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/news')
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
            list = (inner['news'] ?? inner['data'] ?? inner['items']) as List?;
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
                  .map((item) => NewsArticle.fromJson(item))
                  .toList()
              : <NewsArticle>[];

          return {
            'success': true,
            'news': items,
            'pagination': pagination,
          };
        }
      }
      return {
        'success': false,
        'message': 'Gagal mengambil data berita',
        'news': <NewsArticle>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'news': <NewsArticle>[],
      };
    }
  }

  /// Create news article
  Future<Map<String, dynamic>> createNews({
    required String title,
    String? slug,
    required String content,
    String status = 'draft',
    String? publishedAt,
    XFile? imageFile,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/news');

      if (imageFile != null) {
        final request = http.MultipartRequest('POST', uri);
        final token = _client.getAuthToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        request.headers['Accept'] = 'application/json';

        request.fields['title'] = title;
        if (slug != null && slug.isNotEmpty) request.fields['slug'] = slug;
        request.fields['content'] = content;
        request.fields['status'] = status;
        if (publishedAt != null && publishedAt.isNotEmpty) {
          request.fields['published_at'] = publishedAt;
        }

        final bytes = await imageFile.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name,
        );
        request.files.add(multipartFile);

        final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
        final response = await http.Response.fromStream(streamedResponse);
        final data = jsonDecode(response.body);

        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': data['message'] ?? 'Berita berhasil dibuat',
            'news': data['data'] != null ? NewsArticle.fromJson(data['data']) : null,
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal membuat berita',
            'errors': data['errors'],
          };
        }
      } else {
        final body = <String, dynamic>{
          'title': title,
          'content': content,
          'status': status,
        };
        if (slug != null && slug.isNotEmpty) body['slug'] = slug;
        if (publishedAt != null && publishedAt.isNotEmpty) body['published_at'] = publishedAt;

        final response = await http
            .post(
              uri,
              headers: _client.getHeaders(),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));

        final data = jsonDecode(response.body);
        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': data['message'] ?? 'Berita berhasil dibuat',
            'news': data['data'] != null ? NewsArticle.fromJson(data['data']) : null,
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal membuat berita',
            'errors': data['errors'],
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Update news article
  Future<Map<String, dynamic>> updateNews({
    required int id,
    required String title,
    String? slug,
    required String content,
    String status = 'draft',
    String? publishedAt,
    XFile? imageFile,
  }) async {
    try {
      if (imageFile != null) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/news/$id');
        final request = http.MultipartRequest('POST', uri);
        final token = _client.getAuthToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        request.headers['Accept'] = 'application/json';
        request.fields['_method'] = 'PUT';

        request.fields['title'] = title;
        if (slug != null && slug.isNotEmpty) request.fields['slug'] = slug;
        request.fields['content'] = content;
        request.fields['status'] = status;
        if (publishedAt != null && publishedAt.isNotEmpty) {
          request.fields['published_at'] = publishedAt;
        }

        final bytes = await imageFile.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name,
        );
        request.files.add(multipartFile);

        final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
        final response = await http.Response.fromStream(streamedResponse);
        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          return {
            'success': true,
            'message': data['message'] ?? 'Berita berhasil diperbarui',
            'news': data['data'] != null ? NewsArticle.fromJson(data['data']) : null,
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal memperbarui berita',
            'errors': data['errors'],
          };
        }
      } else {
        final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/news/$id');
        final body = <String, dynamic>{
          'title': title,
          'content': content,
          'status': status,
        };
        if (slug != null && slug.isNotEmpty) body['slug'] = slug;
        if (publishedAt != null && publishedAt.isNotEmpty) body['published_at'] = publishedAt;

        final response = await http
            .put(
              uri,
              headers: _client.getHeaders(),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));

        final data = jsonDecode(response.body);
        if (response.statusCode == 200) {
          return {
            'success': true,
            'message': data['message'] ?? 'Berita berhasil diperbarui',
            'news': data['data'] != null ? NewsArticle.fromJson(data['data']) : null,
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal memperbarui berita',
            'errors': data['errors'],
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Delete news article
  Future<Map<String, dynamic>> deleteNews(int id) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/news/$id');
      final response = await http
          .delete(uri, headers: _client.getHeaders())
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Berita berhasil dihapus',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menghapus berita',
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
