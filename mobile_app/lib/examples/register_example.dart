import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_service.dart';

class RegisterExample extends StatefulWidget {
  const RegisterExample({super.key});

  @override
  State<RegisterExample> createState() => _RegisterExampleState();
}

class _RegisterExampleState extends State<RegisterExample> {
  final _farmNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  final authService = AuthService();

  @override
  void dispose() {
    _farmNameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (_farmNameController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _passwordConfirmController.text.isEmpty) {
      setState(() => _errorMessage = 'Semua field harus diisi');
      return false;
    }

    if (_passwordController.text.length < 8) {
      setState(() => _errorMessage = 'Password minimal 8 karakter');
      return false;
    }

    if (_passwordController.text != _passwordConfirmController.text) {
      setState(() => _errorMessage = 'Password tidak cocok');
      return false;
    }

    final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      setState(() => _errorMessage = 'Format email tidak valid');
      return false;
    }

    return true;
  }

  void _handleRegister() async {
    setState(() {
      _errorMessage = '';
      _successMessage = '';
    });

    if (!_validateForm()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await authService.registerKeLaravel(
        farmName: _farmNameController.text.trim(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmController.text,
      );

      if (mounted) {
        debugPrint('✅ Register Success!');

        _farmNameController.clear();
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _passwordController.clear();
        _passwordConfirmController.clear();

        setState(() {
          _successMessage = result['message'] as String? ??
              'Registrasi berhasil! Silakan tunggu persetujuan admin.';
        });

        _showSuccessDialog(_successMessage);
      }
    } catch (e) {
      debugPrint('❌ Register Failed: $e');

      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Registrasi Berhasil'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(
              controller: _farmNameController,
              label: 'Nama Farm',
              icon: Icons.agriculture,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Nama Lengkap',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Nomor Telepon',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              label: 'Password (min 8 karakter)',
              icon: Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordConfirmController,
              label: 'Konfirmasi Password',
              icon: Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 24),
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            const SizedBox(height: 16),
            if (_successMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _successMessage,
                  style: TextStyle(color: Colors.green.shade800),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      obscureText: isPassword,
      keyboardType: keyboardType,
    );
  }
}
