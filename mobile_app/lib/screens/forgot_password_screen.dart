import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _apiService = ApiService();

  int _step = 1; // 1: Minta Token, 2: Input Token & Password Baru
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isAutoFilledToken = false;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ─── Step 1: Kirim Permintaan Token ──────────────────────────────────────────
  Future<void> _sendResetToken() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackbar('Email tidak boleh kosong', Colors.red);
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackbar('Masukkan format email yang valid', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _apiService.sendPasswordResetLink(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final debugToken = result['token'] as String?;
      if (debugToken != null && debugToken.isNotEmpty) {
        _tokenController.text = debugToken;
        _isAutoFilledToken = true;
      }

      _showSnackbar(
        result['message'] ?? 'Instruksi reset password telah diproses.',
        Colors.green,
      );

      // Pindah ke langkah 2 untuk memasukkan token & password baru
      setState(() => _step = 2);
    } else {
      _showSnackbar(
        result['message'] ?? 'Gagal memproses permintaan reset password.',
        Colors.red,
      );
    }
  }

  // ─── Step 2: Reset Password Baru ───────────────────────────────────────────
  Future<void> _submitNewPassword() async {
    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty) {
      _showSnackbar('Email wajib diisi', Colors.red);
      return;
    }
    if (token.isEmpty) {
      _showSnackbar('Token reset password wajib diisi', Colors.red);
      return;
    }
    if (newPassword.isEmpty) {
      _showSnackbar('Password baru wajib diisi', Colors.red);
      return;
    }
    if (newPassword.length < 8) {
      _showSnackbar('Password baru minimal 8 karakter', Colors.red);
      return;
    }
    if (newPassword != confirmPassword) {
      _showSnackbar('Konfirmasi password tidak cocok', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _apiService.resetPassword(
      email: email,
      token: token,
      password: newPassword,
      passwordConfirmation: confirmPassword,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Tampilkan dialog sukses dan arahkan pengguna kembali ke Login Screen (tanpa auto-login)
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF27AE60), size: 28),
              SizedBox(width: 10),
              Text('Password Diperbarui', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text(
            'Password akun Anda telah berhasil direset. Silakan masuk kembali menggunakan password baru Anda.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Masuk ke Akun'),
            ),
          ],
        ),
      );
    } else {
      _showSnackbar(
        result['message'] ?? 'Gagal memperbarui password',
        Colors.red,
      );
    }
  }

  void _showSnackbar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _tokenController.text = data.text!.trim();
        _isAutoFilledToken = false;
      });
      _showSnackbar('Token berhasil ditempel dari clipboard', Colors.blueGrey);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    colors: [Color(0xFF1A7A4A), Color(0xFF27AE60)],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.32)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Back Button
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.grey),
                              onPressed: () {
                                if (_step == 2) {
                                  setState(() => _step = 1);
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                              tooltip: 'Kembali',
                            ),
                          ),

                          // Icon Header
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              _step == 1 ? Icons.lock_reset_rounded : Icons.vpn_key_rounded,
                              size: 38,
                              color: const Color(0xFF27AE60),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title & Description
                          Text(
                            _step == 1 ? 'Lupa Password?' : 'Reset Password Baru',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _step == 1
                                ? 'Masukkan email terdaftar untuk menerima Token Reset Password'
                                : 'Masukkan Token Reset Password dan tentukan password baru akun Anda',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 13.5, height: 1.4),
                          ),
                          const SizedBox(height: 24),

                          // Form Content based on Step
                          if (_step == 1) _buildStep1Form() else _buildStep2Form(),

                          const SizedBox(height: 20),

                          // Back to Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Kembali ke ', style: TextStyle(fontSize: 14)),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                ),
                                child: const Text(
                                  'Halaman Login',
                                  style: TextStyle(
                                    color: Color(0xFF27AE60),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
  }

  // ─── Step 1 UI ─────────────────────────────────────────────────────────────
  Widget _buildStep1Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Terdaftar',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            hintText: 'nama@email.com',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              disabledBackgroundColor: Colors.grey.shade400,
            ),
            onPressed: _isLoading ? null : _sendResetToken,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Kirim Token Reset',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 14),

        Center(
          child: TextButton(
            onPressed: _isLoading ? null : () => setState(() => _step = 2),
            child: const Text(
              'Sudah memiliki Token Reset? Klik di sini',
              style: TextStyle(color: Color(0xFF27AE60), fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Step 2 UI ─────────────────────────────────────────────────────────────
  Widget _buildStep2Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isAutoFilledToken)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Token reset terisi otomatis untuk pengujian lokal.',
                    style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // Email field
        const Text(
          'Email Akun',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 14),

        // Token field
        const Text(
          'Token Reset Password',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _tokenController,
          enabled: !_isLoading,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            hintText: 'Tempel token dari email',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            prefixIcon: const Icon(Icons.key_rounded, color: Colors.grey),
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_paste_rounded, size: 20, color: Color(0xFF27AE60)),
              onPressed: _pasteFromClipboard,
              tooltip: 'Tempel dari Clipboard',
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Password Baru field
        const Text(
          'Password Baru (Minimal 8 Karakter)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          enabled: !_isLoading,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            hintText: 'Minimal 8 karakter',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Konfirmasi Password Baru field
        const Text(
          'Konfirmasi Password Baru',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          enabled: !_isLoading,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            hintText: 'Ulangi password baru',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),
        const SizedBox(height: 22),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              disabledBackgroundColor: Colors.grey.shade400,
            ),
            onPressed: _isLoading ? null : _submitNewPassword,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Perbarui Password',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        Center(
          child: TextButton.icon(
            onPressed: _isLoading ? null : () => setState(() => _step = 1),
            icon: const Icon(Icons.arrow_back, size: 16, color: Colors.grey),
            label: const Text(
              'Ubah Email / Minta Token Baru',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
