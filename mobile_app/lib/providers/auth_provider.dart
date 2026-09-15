import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  bool _isImpersonating = false;

  // Getters
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get isImpersonating => _isImpersonating;

  AuthProvider() {
    _loadStoredSession();
  }

  Future<void> _loadStoredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      _isImpersonating = prefs.containsKey('original_admin_token');

      if (_token != null) {
        _apiService.setAuthToken(_token!);

        // Try to validate token by fetching current user
        final user = await _apiService.getCurrentUser();
        if (user != null) {
          _user = user;
          _isAuthenticated = true;
          notifyListeners();
        } else {
          // Token expired
          await logout();
        }
      }
    } catch (e) {
      debugPrint('Error loading stored session: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.login(email, password);

      if (result['success'] == true) {
        _user = result['user'] as User;
        _token = result['token'] as String?;
        _isAuthenticated = true;
        _errorMessage = null;

        if (_token != null) {
          _apiService.setAuthToken(_token!);
        }

        // Save to SharedPreferences
        if (_token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', _token!);
          await prefs.setString('user_data', jsonEncode(_user!.toJson()));
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Login gagal';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String farmName,
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.register(
        farmName: farmName,
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (result['success'] == true) {
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Registrasi gagal';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> impersonate(int targetUserId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.impersonateUser(targetUserId);

      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();

        // Store original admin data first if we aren't already impersonating
        if (!_isImpersonating) {
          await prefs.setString('original_admin_token', _token!);
          await prefs.setString('original_admin_user', jsonEncode(_user!.toJson()));
        }

        _token = result['token'] as String?;
        _user = result['user'] as User;
        _isImpersonating = true;
        _isAuthenticated = true;

        _apiService.setAuthToken(_token!);
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', jsonEncode(_user!.toJson()));

        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Impersonasi gagal';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> stopImpersonating() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final adminToken = prefs.getString('original_admin_token');
      final adminUserJson = prefs.getString('original_admin_user');

      if (adminToken != null && adminUserJson != null) {
        _token = adminToken;
        final decodedUser = jsonDecode(adminUserJson) as Map<String, dynamic>;
        _user = User.fromJson(decodedUser);
        _isImpersonating = false;
        _isAuthenticated = true;

        _apiService.setAuthToken(_token!);
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', adminUserJson);

        await prefs.remove('original_admin_token');
        await prefs.remove('original_admin_user');

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Error stopping impersonation: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      _user = null;
      _token = null;
      _isAuthenticated = false;
      _errorMessage = null;
      _isImpersonating = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      await prefs.remove('original_admin_token');
      await prefs.remove('original_admin_user');

      _apiService.clearAuthToken();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
