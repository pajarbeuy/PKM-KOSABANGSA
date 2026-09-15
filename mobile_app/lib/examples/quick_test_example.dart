import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const QuickTestApp());
}

class QuickTestApp extends StatelessWidget {
  const QuickTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Service Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final authService = AuthService();
  String _output = '=== TEST OUTPUT ===\n';

  void _addOutput(String message) {
    setState(() {
      _output += '\n$message';
    });
    debugPrint(message);
  }

  void _testCheckLoginStatus() async {
    _addOutput('\n🔵 TEST 1: Check Login Status');
    try {
      final isLoggedIn = await authService.isLoggedIn();
      _addOutput('✅ Is Logged In: $isLoggedIn');
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  void _testGetToken() async {
    _addOutput('\n🔵 TEST 2: Get Token');
    try {
      final token = await authService.getToken();
      if (token != null) {
        _addOutput('✅ Token: ${token.substring(0, 20)}...');
      } else {
        _addOutput('⚠️ No token found');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  void _testGetCurrentUser() async {
    _addOutput('\n🔵 TEST 3: Get Current User');
    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        _addOutput('✅ User: ${user.name} (${user.email})');
      } else {
        _addOutput('⚠️ No user found');
      }
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  void _testLogin() async {
    _addOutput('\n🔵 TEST 4: Login');
    _addOutput('📝 Testing login dengan data test...');

    try {
      await authService.loginKeLaravel(
        email: 'test@example.com',
        password: 'password123',
      );

      _addOutput('✅ Login Success!');
    } catch (e) {
      _addOutput('❌ Login Error: $e');
    }
  }

  void _testRegister() async {
    _addOutput('\n🔵 TEST 5: Register');
    _addOutput('📝 Testing register dengan data baru...');

    try {
      final randomEmail = 'test${DateTime.now().millisecond}@example.com';

      await authService.registerKeLaravel(
        farmName: 'Test Farm',
        name: 'Test User',
        email: randomEmail,
        phone: '08123456789',
        password: 'testpassword123',
        passwordConfirmation: 'testpassword123',
      );

      _addOutput('✅ Register Success!');
      _addOutput('Email: $randomEmail');
    } catch (e) {
      _addOutput('❌ Register Error: $e');
    }
  }

  void _testLogout() async {
    _addOutput('\n🔵 TEST 6: Logout');
    try {
      await authService.logout();
      _addOutput('✅ Logout Success!');

      final isLoggedIn = await authService.isLoggedIn();
      _addOutput('Is Logged In after logout: $isLoggedIn');
    } catch (e) {
      _addOutput('❌ Logout Error: $e');
    }
  }

  void _testClearAllData() async {
    _addOutput('\n🔵 TEST 7: Clear All Local Data');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _addOutput('✅ All data cleared!');
    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  void _clearOutput() {
    setState(() {
      _output = '=== TEST OUTPUT ===\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Service - Quick Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearOutput,
            tooltip: 'Clear output',
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _buildTestButton('Check Login', _testCheckLoginStatus),
                _buildTestButton('Get Token', _testGetToken),
                _buildTestButton('Get User', _testGetCurrentUser),
                _buildTestButton('Login', _testLogin),
                _buildTestButton('Register', _testRegister),
                _buildTestButton('Logout', _testLogout),
                _buildTestButton('Clear Data', _testClearAllData),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey.shade900,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: SelectableText(
                  _output,
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
