import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool _isSavingPassword = false;
  bool _isSavingGudang = false;
  bool _isSavingNotif = false;
  bool _isSendingFeedback = false;

  // Password forms
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Gudang forms
  final _gudangFormKey = GlobalKey<FormState>();
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();

  // Notifications toggles
  bool _notifyNewSale = true;
  bool _notifyCost = true;

  // Feedback form
  final _feedbackFormKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }



  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getSettings();
      if (data != null) {
        _minStockController.text = (data['min_stock'] ?? 100).toString();
        _maxStockController.text = (data['max_stock'] ?? 5000).toString();

        _notifyNewSale = data['notify_new_sale'] as bool? ?? true;
        _notifyCost = data['notify_cost'] as bool? ?? true;
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Gagal mengambil pengaturan: $e');
    }
  }



  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSavingPassword = true);

    final result = await _apiService.updatePassword(
      currentPassword: _currentPasswordController.text,
      password: _newPasswordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    setState(() => _isSavingPassword = false);
    if (result['success'] == true) {
      _showSuccess(result['message'] ?? 'Password berhasil diperbarui');
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } else {
      _showError(result['message'] ?? 'Gagal memperbarui password');
    }
  }

  Future<void> _saveGudang() async {
    if (!_gudangFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSavingGudang = true);

    final min = int.tryParse(_minStockController.text) ?? 100;
    final max = int.tryParse(_maxStockController.text) ?? 5000;

    final result = await _apiService.updateWarehouseThresholds(
      minStock: min,
      maxStock: max,
    );

    setState(() => _isSavingGudang = false);
    if (result['success'] == true) {
      _showSuccess(result['message'] ?? 'Ambang batas gudang diperbarui');
    } else {
      _showError(result['message'] ?? 'Gagal memperbarui ambang batas');
    }
  }

  Future<void> _saveNotifications() async {
    setState(() => _isSavingNotif = true);

    final result = await _apiService.updateNotifications(
      notifyLowStock: false,
      notifyNewSale: _notifyNewSale,
      notifyCost: _notifyCost,
    );

    setState(() => _isSavingNotif = false);
    if (result['success'] == true) {
      _showSuccess(result['message'] ?? 'Konfigurasi notifikasi disimpan');
    } else {
      _showError(result['message'] ?? 'Gagal menyimpan notifikasi');
    }
  }

  Future<void> _sendFeedback() async {
    FocusScope.of(context).unfocus();
    if (!_feedbackFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSendingFeedback = true);

    final result = await _apiService.sendFeedback(
      _feedbackController.text.trim(),
    );

    setState(() => _isSendingFeedback = false);
    if (result['success'] == true) {
      _showSuccess('Saran Anda berhasil dikirim ke Admin kelompok tani!');
      _feedbackController.clear();
    } else {
      _showError(result['message'] ?? 'Gagal mengirim saran');
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        return AppShell(
          currentRoute: 'settings',
          title: 'Pengaturan',
          subtitle: 'Atur profil, keamanan, dan notifikasi',
          onRefresh: _loadSettings,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.green700,
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 1200 : 700,
                      ),
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildPasswordCard(),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildGudangCard(),
                                      const SizedBox(height: 20),
                                      _buildNotificationCard(),
                                      const SizedBox(height: 20),
                                      _buildFeedbackCard(),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildPasswordCard(),
                                const SizedBox(height: 16),
                                _buildGudangCard(),
                                const SizedBox(height: 16),
                                _buildNotificationCard(),
                                const SizedBox(height: 16),
                                _buildFeedbackCard(),
                                const SizedBox(height: 24),
                              ],
                            ),
                    ),
                  ),
                ),
        );
      },
    );
  }



  Widget _buildPasswordCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                Icons.lock_outline,
                'Keamanan (Ubah Password)',
                Colors.blue,
              ),
              const Divider(height: 24),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Password Saat Ini',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Password lama wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password baru wajib diisi';
                  }
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Konfirmasi password tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSavingPassword ? null : _savePassword,
                  child: _isSavingPassword
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Ubah Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGudangCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _gudangFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                Icons.warehouse_outlined,
                'Ambang Batas Gudang',
                Colors.orange,
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Batas Stok Min (kg)',
                      ),
                      validator: (value) =>
                          value == null || int.tryParse(value) == null
                          ? 'Wajib diisi'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxStockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Batas Stok Maks (kg)',
                      ),
                      validator: (value) =>
                          value == null || int.tryParse(value) == null
                          ? 'Wajib diisi'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSavingGudang ? null : _saveGudang,
                  child: _isSavingGudang
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Perbarui Ambang Batas'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              Icons.notifications_active_outlined,
              'Preferensi Notifikasi',
              Colors.purple,
            ),
            const Divider(height: 24),
            SwitchListTile(
              title: const Text(
                'Penjualan Baru',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Text(
                'Notifikasi tiap kali ada penjualan hasil panen yang tercatat',
                style: TextStyle(fontSize: 11),
              ),
              value: _notifyNewSale,
              activeThumbColor: Colors.purple,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _notifyNewSale = val),
            ),
            SwitchListTile(
              title: const Text(
                'Biaya Lahan Baru',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Text(
                'Notifikasi pengingat pengeluaran baru kelompok tani',
                style: TextStyle(fontSize: 11),
              ),
              value: _notifyCost,
              activeThumbColor: Colors.purple,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _notifyCost = val),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isSavingNotif ? null : _saveNotifications,
                child: _isSavingNotif
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Simpan Preferensi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _feedbackFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                Icons.feedback_outlined,
                'Kirim Masukan & Saran',
                Colors.teal,
              ),
              const Divider(height: 24),
              TextFormField(
                controller: _feedbackController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Tulis kritik, saran, masukan, atau kendala Anda di sini...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Masukan tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSendingFeedback ? null : _sendFeedback,
                  child: _isSendingFeedback
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Kirim Masukan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
