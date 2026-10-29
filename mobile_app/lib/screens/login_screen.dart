import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'super_admin_dashboard_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text,
      _passwordController.text,
    );

    if (success) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Berhasil!'), backgroundColor: Colors.green),
      );
      final role = authProvider.user?.role;
      final targetScreen = role == 'super_admin' ? const SuperAdminDashboardScreen() : const HomeScreen();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
      );
    } else {
      if (!context.mounted) return;
      final errorMessage = authProvider.errorMessage ?? 'Login gagal';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loginWithGoogle(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.loginWithGoogle();

    if (result['success'] == true) {
      if (!context.mounted) return;

      // Email Google belum terdaftar -> Arahkan ke form registrasi
      if (result['needs_registration'] == true) {
        final data = result['data'] as Map<String, dynamic>? ?? {};
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email Google belum terdaftar. Silakan lengkapi form pendaftaran.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterScreen(
              initialName: data['name'] as String?,
              initialEmail: data['email'] as String?,
              googleSub: data['google_sub'] as String?,
            ),
          ),
        );
        return;
      }

      // Email Google sudah terdaftar -> Langsung masuk
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login dengan Google Berhasil!'),
          backgroundColor: Colors.green,
        ),
      );
      final role = authProvider.user?.role;
      final targetScreen = role == 'super_admin'
          ? const SuperAdminDashboardScreen()
          : const HomeScreen();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
      );
    } else {
      if (!context.mounted) return;
      final errorMessage = authProvider.errorMessage;
      if (errorMessage != null && errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/auth_bg.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1A7A4A),
                          Color(0xFF27AE60),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.28),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo
                              Image.asset(
                                'assets/images/logo_nama.png',
                                width: 140,
                                height: 140,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                              const SizedBox(height: 16),
                              // Titles
                              const Text(
                                'Login SumberTani',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Masuk ke akun Anda untuk melanjutkan',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              
                              // Email Field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Email', style: TextStyle(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    enabled: !authProvider.isLoading,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Password Field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Password', style: TextStyle(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    enabled: !authProvider.isLoading,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      hintText: 'Masukkan password Anda',
                                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: authProvider.isLoading
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                                          );
                                        },
                                  child: const Text(
                                    'Lupa Password?',
                                    style: TextStyle(
                                      color: Color(0xFF27AE60),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Error Message
                              if (authProvider.errorMessage != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    border: Border.all(color: Colors.red.shade200),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    authProvider.errorMessage!,
                                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                  ),
                                ),
                              if (authProvider.errorMessage != null) const SizedBox(height: 16),
                              
                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF27AE60),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: authProvider.isLoading ? null : () => _login(context),
                                  child: authProvider.isLoading 
                                      ? const SizedBox(
                                          width: 24, height: 24, 
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                        ) 
                                      : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.grey.shade300)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'atau',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey.shade300)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    backgroundColor: Colors.white,
                                  ),
                                  onPressed: authProvider.isLoading ? null : () => _loginWithGoogle(context),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.network(
                                        'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                                        width: 20,
                                        height: 20,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.g_mobiledata,
                                          size: 26,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Masuk dengan Google',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Belum punya akun? '),
                                  GestureDetector(
                                    onTap: authProvider.isLoading
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                            );
                                          },
                                    child: const Text(
                                      'Daftar',
                                      style: TextStyle(
                                        color: Color(0xFF27AE60),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
