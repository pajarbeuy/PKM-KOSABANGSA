import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../models/user.dart';
import '../../models/dashboard.dart';
import 'api_client.dart';

class AuthApiService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: _client.getHeaders(includeAuth: false),
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']['token'] as String?;
        if (token != null) {
          _client.setAuthToken(token);
        }
        return {
          'success': true,
          'user': User.fromJson(data['data']['user'] ?? {}),
          'token': token,
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  String _translateValidationMessage(String raw) {
    if (raw.contains('validation.min.string') || raw.contains('min.string')) {
      return 'Password minimal 8 karakter';
    }
    if (raw.contains('validation.confirmed') || raw.contains('confirmed')) {
      return 'Konfirmasi password tidak cocok';
    }
    if (raw.contains('validation.unique') || raw.contains('unique')) {
      return 'Email sudah terdaftar, gunakan email lain';
    }
    if (raw.contains('validation.email') || raw.contains('email')) {
      return 'Format email tidak valid';
    }
    if (raw.contains('validation.required') || raw.contains('required')) {
      return 'Semua field harus diisi';
    }
    return raw;
  }

  Future<Map<String, dynamic>> register({
    required String farmName,
    required String name,
    required String email,
    required String phone,
    required int farmerGroupId,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/register'),
            headers: _client.getHeaders(includeAuth: false),
            body: jsonEncode({
              'farm_name': farmName,
              'name': name,
              'email': email,
              'phone': phone,
              'farmer_group_id': farmerGroupId,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      String message = data['message'] ?? 'Registrasi gagal';

      if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        final List<String> errorMessages = [];
        for (var key in errors.keys) {
          final value = errors[key];
          if (value is List && value.isNotEmpty) {
            errorMessages.add(_translateValidationMessage(value.first.toString()));
          }
        }
        if (errorMessages.isNotEmpty) {
          message = errorMessages.join(', ');
        }
      } else {
        message = _translateValidationMessage(message);
      }

      return {
        'success': response.statusCode == 201 && data['success'] == true,
        'message': message,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<void> logout() async {
    try {
      await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 10));
    } finally {
      _client.clearAuthToken();
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/auth/me'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return User.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> sendPasswordResetLink(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
            headers: _client.getHeaders(includeAuth: false),
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      String message = data['message'] ?? 'Permintaan reset password telah dikirim.';
      if (data['errors'] != null && data['errors'] is Map) {
        final errMap = data['errors'] as Map;
        final list = <String>[];
        errMap.forEach((_, v) {
          if (v is List) {
            list.addAll(v.map((e) => e.toString()));
          } else {
            list.add(v.toString());
          }
        });
        if (list.isNotEmpty) message = list.join('\n');
      }

      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': message,
        'token': data['data']?['token'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/reset-password'),
            headers: _client.getHeaders(includeAuth: false),
            body: jsonEncode({
              'email': email,
              'token': token,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      String message = data['message'] ?? 'Gagal mereset password.';
      if (data['errors'] != null && data['errors'] is Map) {
        final errMap = data['errors'] as Map;
        final list = <String>[];
        errMap.forEach((_, v) {
          if (v is List) {
            list.addAll(v.map((e) => e.toString()));
          } else {
            list.add(v.toString());
          }
        });
        if (list.isNotEmpty) message = list.join('\n');
      }

      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': message,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan: ${e.toString()}'};
    }
  }

  Future<DashboardData?> getDashboard() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/dashboard'),
            headers: _client.getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return DashboardData.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
