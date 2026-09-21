import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  String? getAuthToken() {
    return _authToken;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> getHeaders({bool includeAuth = true, bool forMultipart = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
      "ngrok-skip-browser-warning": "true"
    };
    if (!forMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Map<String, dynamic> decodeApiResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data is Map<String, dynamic>) {
          return data;
        }
        throw Exception('Respons API tidak valid.');
      }

      if (data is Map<String, dynamic>) {
        throw Exception(data['message'] ?? 'Server error ${response.statusCode}');
      }
      throw Exception('Server error ${response.statusCode}');
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Respons JSON tidak valid: ${e.message}');
      }
      throw Exception(e.toString());
    }
  }
}
