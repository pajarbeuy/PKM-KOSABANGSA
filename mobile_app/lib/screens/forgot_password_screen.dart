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
  final _apiService = ApiService();

  // Mode: 0 = Verifikasi Admin/Poktan (Default & Ramah Petani), 1 = Reset via Email
  int _recoveryMode = 0;

  // Sub-step untuk Mode 0: 1 = Formulir Pengajuan, 2 = Masukkan Token 5 Menit & Password Baru
  int _adminSubStep = 1;

  // Controllers untuk Mode 0 (Verifikasi Admin)
  final _nameController = TextEditingController();
  final _farmerGroupController = TextEditingController();
  final _contactController = TextEditingController();
  final _fiveMinTokenController = TextEditingController();
  final _adminNewPasswordController = TextEditingController();
  final _adminConfirmPasswordController = TextEditingController();

  // Controllers untuk Mode 1 (Email)
  final _emailController = TextEditingController();
  final _emailTokenController = TextEditingController();
  final _emailNewPasswordController = TextEditingController();
  final _emailConfirmPasswordController = TextEditingController();
  int _emailStep = 1; // 1: Minta Token, 2: Input Token & Password Baru
  bool _isAutoFilledEmailToken = false;

  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _farmerGroupController.dispose();
    _contactController.dispose();
    _fiveMinTokenController.dispose();
    _adminNewPasswordController.dispose();
    _adminConfirmPasswordController.dispose();

    _emailController.dispose();
    _emailTokenController.dispose();
    _emailNewPasswordController.dispose();
    _emailConfirmPasswordController.dispose();
    super.dispose();
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

  // ═══════════════════════════════════════════════════════════════════════════
  // ALUR VERIFIKASI ADMIN / POKTAN (RAMAH PETANI)
  // ═══════════════════════════════════════════════════════════════════════════

  // Step 1: Ajukan Permintaan Pemulihan Akun
  Future<void> _submitAdminRecoveryRequest() async {
    final name = _nameController.text.trim();
    final group = _farmerGroupController.text.trim();
    final contact = _contactController.text.trim();

    if (name.isEmpty) {
      _showSnackbar('Nama lengkap/akun wajib diisi', Colors.red);
      return;
    }
    if (group.isEmpty) {
      _showSnackbar('Nama kelompok tani (Poktan) wajib diisi', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final res = await _apiService.createPasswordResetRequest(
      name: name,
      farmerGroup: group,
      contactInfo: contact.isNotEmpty ? contact : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF27AE60), size: 28),
              SizedBox(width: 10),
              Text('Permintaan Terkirim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                res['message'] ??
                    'Permintaan pemulihan akun Anda telah dicatat oleh sistem.',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Silakan hubungi Super Admin atau Ketua Poktan. Setelah permohonan disetujui, Anda akan menerima Token Reset 5 Menit.',
                        style: TextStyle(fontSize: 12.5, color: Colors.amber.shade900, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _adminSubStep = 2);
              },
              child: const Text('Masukkan Token 5 Menit'),
            ),
          ],
        ),
      );
    } else {
      _showSnackbar(
        res['message'] ?? 'Gagal mengirim permintaan pemulihan.',
        Colors.red,
      );
    }
  }

  // Step 2: Konfirmasi Token 5 Menit & Set Password Baru
  Future<void> _submitAdminConfirmToken() async {
    final token = _fiveMinTokenController.text.trim();
    final newPassword = _adminNewPasswordController.text;
    final confirmPassword = _adminConfirmPasswordController.text;

    if (token.isEmpty) {
      _showSnackbar('Token reset 5 menit wajib diisi', Colors.red);
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

    final res = await _apiService.confirmPasswordResetWithToken(
      token: token,
      password: newPassword,
      passwordConfirmation: confirmPassword,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
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
            'Selamat! Kata sandi akun Anda telah berhasil diperbarui menggunakan verifikasi Super Admin. Silakan masuk kembali dengan kata sandi baru Anda.',
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
        res['message'] ?? 'Token tidak valid atau sudah kedaluwarsa.',
        Colors.red,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ALUR EMAIL LAMA (ALTERNATIF)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _sendEmailResetToken() async {
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
        _emailTokenController.text = debugToken;
        _isAutoFilledEmailToken = true;
      }

      _showSnackbar(
        result['message'] ?? 'Instruksi reset password telah diproses.',
        Colors.green,
      );
      setState(() => _emailStep = 2);
    } else {
      _showSnackbar(
        result['message'] ?? 'Gagal memproses permintaan reset password.',
        Colors.red,
      );
    }
  }

  Future<void> _submitEmailNewPassword() async {
    final email = _emailController.text.trim();
    final token = _emailTokenController.text.trim();
    final newPassword = _emailNewPasswordController.text;
    final confirmPassword = _emailConfirmPasswordController.text;

    if (email.isEmpty || token.isEmpty || newPassword.isEmpty) {
      _showSnackbar('Semua field wajib diisi', Colors.red);
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

  Future<void> _pasteToController(TextEditingController ctrl) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        ctrl.text = data.text!.trim();
      });
      _showSnackbar('Token berhasil ditempel dari clipboard', Colors.blueGrey);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════════════════

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
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Bar: Back & Mode indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: Colors.grey),
                                onPressed: () {
                                  if (_recoveryMode == 0 && _adminSubStep == 2) {
                                    setState(() => _adminSubStep = 1);
                                  } else if (_recoveryMode == 1 && _emailStep == 2) {
                                    setState(() => _emailStep = 1);
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                                tooltip: 'Kembali',
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _recoveryMode == 0 ? 'Verifikasi Lapangan' : 'Metode Email',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A7A4A),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Icon Header
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF27AE60).withValues(alpha: 0.12),
                            ),
                            child: Icon(
                              _recoveryMode == 0
                                  ? (_adminSubStep == 1 ? Icons.assignment_ind_rounded : Icons.vpn_key_rounded)
                                  : (_emailStep == 1 ? Icons.mark_email_read_rounded : Icons.key_rounded),
                              size: 34,
                              color: const Color(0xFF27AE60),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Title & Subtitle
                          Text(
                            _recoveryMode == 0
                                ? (_adminSubStep == 1 ? 'Pemulihan Akun Petani' : 'Masukkan Token 5 Menit')
                                : (_emailStep == 1 ? 'Reset via Email' : 'Konfirmasi Token Email'),
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _recoveryMode == 0
                                ? (_adminSubStep == 1
                                    ? 'Ajukan permohonan ke Super Admin dengan memasukkan nama dan kelompok tani Anda.'
                                    : 'Masukkan token reset 5 menit yang diberikan Super Admin beserta kata sandi baru.')
                                : (_emailStep == 1
                                    ? 'Masukkan alamat email terdaftar untuk menerima link/token pemulihan akun.'
                                    : 'Masukkan token dari email dan buat password baru Anda.'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 18),

                          // Mode Switcher Tabs
                          _buildModeSwitcher(),
                          const SizedBox(height: 20),

                          // Form Content based on recoveryMode
                          if (_recoveryMode == 0)
                            (_adminSubStep == 1 ? _buildAdminStep1Form() : _buildAdminStep2Form())
                          else
                            (_emailStep == 1 ? _buildEmailStep1Form() : _buildEmailStep2Form()),

                          const SizedBox(height: 20),

                          // Back to Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Sudah ingat password? ', style: TextStyle(fontSize: 13.5)),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                ),
                                child: const Text(
                                  'Masuk di Sini',
                                  style: TextStyle(
                                    color: Color(0xFF27AE60),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
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

  // ─── Mode Switcher Bar ───────────────────────────────────────────────────────
  Widget _buildModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _recoveryMode = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _recoveryMode == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _recoveryMode == 0
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: 16,
                      color: _recoveryMode == 0 ? const Color(0xFF1A7A4A) : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Verifikasi Admin',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _recoveryMode == 0 ? FontWeight.bold : FontWeight.w500,
                        color: _recoveryMode == 0 ? const Color(0xFF1A7A4A) : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _recoveryMode = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _recoveryMode == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _recoveryMode == 1
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      size: 16,
                      color: _recoveryMode == 1 ? const Color(0xFF1A7A4A) : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reset via Email',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _recoveryMode == 1 ? FontWeight.bold : FontWeight.w500,
                        color: _recoveryMode == 1 ? const Color(0xFF1A7A4A) : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mode 0 Step 1: Form Pengajuan Verifikasi Admin ─────────────────────────
  Widget _buildAdminStep1Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nama Lengkap / Nama Akun *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          enabled: !_isLoading,
          decoration: _inputDecoration('Misal: Pajar Sidik', Icons.person_outline),
        ),
        const SizedBox(height: 14),

        const Text(
          'Nama Kelompok Tani (Poktan) *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _farmerGroupController,
          enabled: !_isLoading,
          decoration: _inputDecoration('Misal: Poktan Sukamaju', Icons.groups_outlined),
        ),
        const SizedBox(height: 14),

        const Text(
          'No. WhatsApp / Kontak (Opsional)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _contactController,
          keyboardType: TextInputType.phone,
          enabled: !_isLoading,
          decoration: _inputDecoration('081234567890', Icons.phone_android_outlined),
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
            ),
            onPressed: _isLoading ? null : _submitAdminRecoveryRequest,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Kirim Permintaan Pemulihan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        Center(
          child: TextButton(
            onPressed: _isLoading ? null : () => setState(() => _adminSubStep = 2),
            child: const Text(
              'Sudah menerima Token 5 Menit? Masukkan di sini',
              style: TextStyle(color: Color(0xFF1A7A4A), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Mode 0 Step 2: Form Input Token 5 Menit & Password Baru ───────────────
  Widget _buildAdminStep2Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Security info banner
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            children: [
              Icon(Icons.timer_outlined, size: 20, color: Color(0xFF1D4ED8)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Token reset berlaku tepat 5 MENIT sejak dibuat oleh Super Admin dan hanya bisa digunakan sekali.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.3),
                ),
              ),
            ],
          ),
        ),

        const Text(
          'Token Reset 5 Menit *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _fiveMinTokenController,
          enabled: !_isLoading,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            hintText: 'Tempel token dari Admin (cth: a1b2c3d4...)',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            prefixIcon: const Icon(Icons.key_rounded, color: Colors.grey),
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_paste_rounded, size: 20, color: Color(0xFF27AE60)),
              onPressed: () => _pasteToController(_fiveMinTokenController),
              tooltip: 'Tempel dari Clipboard',
            ),
          ),
        ),
        const SizedBox(height: 14),

        const Text(
          'Password Baru (Minimal 8 Karakter) *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _adminNewPasswordController,
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

        const Text(
          'Konfirmasi Password Baru *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _adminConfirmPasswordController,
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
            ),
            onPressed: _isLoading ? null : _submitAdminConfirmToken,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Perbarui Password Sekarang',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        Center(
          child: TextButton.icon(
            onPressed: _isLoading ? null : () => setState(() => _adminSubStep = 1),
            icon: const Icon(Icons.arrow_back, size: 16, color: Colors.grey),
            label: const Text(
              'Belum punya token? Ajukan formulir dulu',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Mode 1 Step 1: Form Kirim Link/Token Email ─────────────────────────────
  Widget _buildEmailStep1Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Terdaftar',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          decoration: _inputDecoration('nama@email.com', Icons.email_outlined),
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
            ),
            onPressed: _isLoading ? null : _sendEmailResetToken,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Kirim Token Reset',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        Center(
          child: TextButton(
            onPressed: _isLoading ? null : () => setState(() => _emailStep = 2),
            child: const Text(
              'Sudah memiliki Token Reset Email? Klik di sini',
              style: TextStyle(color: Color(0xFF27AE60), fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Mode 1 Step 2: Form Reset via Email Token ──────────────────────────────
  Widget _buildEmailStep2Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isAutoFilledEmailToken)
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
                    'Token reset terisi otomatis untuk pengujian.',
                    style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        const Text(
          'Email Akun',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          decoration: _inputDecoration('nama@email.com', Icons.email_outlined),
        ),
        const SizedBox(height: 14),

        const Text(
          'Token Reset Password',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailTokenController,
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
              onPressed: () => _pasteToController(_emailTokenController),
              tooltip: 'Tempel dari Clipboard',
            ),
          ),
        ),
        const SizedBox(height: 14),

        const Text(
          'Password Baru (Minimal 8 Karakter)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailNewPasswordController,
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

        const Text(
          'Konfirmasi Password Baru',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailConfirmPasswordController,
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
            ),
            onPressed: _isLoading ? null : _submitEmailNewPassword,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Perbarui Password',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        Center(
          child: TextButton.icon(
            onPressed: _isLoading ? null : () => setState(() => _emailStep = 1),
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

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[50],
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
    );
  }
}
