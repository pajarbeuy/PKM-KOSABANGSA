// File: lib/services/auth_service.dart
// Lokasi: mobile_app/lib/services/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Auth Service - Mengelola semua proses authentication
class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  /// Login ke Laravel API
  Future<Map<String, dynamic>> loginKeLaravel({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Attempting login for: $email');

      final body = {
        'email': email,
        'password': password,
      };

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      debugPrint('📤 Login Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

        if (!jsonResponse.containsKey('data')) {
          throw Exception('Invalid response structure: missing "data" field');
        }

        final loginData = jsonResponse['data'] as Map<String, dynamic>;

        // Extract token
        final token = loginData['token'] as String? ?? '';
        final userData = loginData['user'] as Map<String, dynamic>? ?? {};

        // Parse user
        final user = User.fromJson(userData);

        // Simpan token
        await _saveToken(token);
        await _saveUserData(user);

        debugPrint('✅ Login Success: ${user.name}');

        return {
          'success': true,
          'token': token,
          'user': user,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Email atau password salah');
      } else if (response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final message = jsonResponse['message'] as String? ?? 'Account not approved';
        throw Exception(message);
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      debugPrint('❌ Network Error: $e');
      throw Exception('Network error. Check connection.');
    } catch (e) {
      debugPrint('❌ Login Error: $e');
      rethrow;
    }
  }

  /// Register ke Laravel API
  Future<Map<String, dynamic>> registerKeLaravel({
    required String farmName,
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      debugPrint('📏 Attempting registration for: $email');

      final body = {
        'farm_name': farmName,
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      debugPrint('📤 Register Response Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Registration Success!');

        return {
          'success': true,
          'message': jsonResponse['message'] as String? ?? 'Registration successful',
          'data': jsonResponse['data'],
        };
      } else if (response.statusCode == 422) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final errors = jsonResponse['data'] as Map<String, dynamic>? ?? {};

        String errorMessage = 'Validation Failed:\n';
        errors.forEach((key, value) {
          if (value is List) {
            errorMessage += '• ${value.join(', ')}\n';
          }
        });

        throw Exception(errorMessage);
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } catch (e) {
      debugPrint('❌ Register Error: $e');
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      final token = await _getToken();

      if (token != null) {
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
          headers: headers,
        ).timeout(const Duration(seconds: 10));
      }

      await _clearAll();
      debugPrint('✅ Logout Success');
    } catch (e) {
      debugPrint('❌ Logout Error: $e');
      await _clearAll();
    }
  }

  /// Get current user
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');

      if (userJson == null) {
        return null;
      }

      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userData);
    } catch (e) {
      debugPrint('❌ Error getting current user: $e');
      return null;
    }
  }

  /// Check login status
  Future<bool> isLoggedIn() async {
    try {
      final token = await _getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get token
  Future<String?> getToken() async {
    return await _getToken();
  }

  // Private methods

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    debugPrint('✅ Token saved');
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    debugPrint('✅ User data saved');
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_data');
  }
}
