import 'package:flutter/material.dart';
import '../../models/farmer_group.dart';
import '../../services/api_service.dart';
import '../app_theme.dart';

/// Modal form for adding or updating user account.
/// Extracted from user_management_screen.dart to modularize code.
class UserFormBottomSheet extends StatefulWidget {
  final ApiService apiService;
  final Map<String, dynamic>? user;
  final VoidCallback onSaved;

  const UserFormBottomSheet({
    super.key,
    required this.apiService,
    this.user,
    required this.onSaved,
  });

  @override
  State<UserFormBottomSheet> createState() => _UserFormBottomSheetState();
}

class _UserFormBottomSheetState extends State<UserFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _farmNameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;

  late String _role;
  late String _status;
  int? _selectedFarmerGroupId;
  List<FarmerGroup> _farmerGroups = [];
  bool _isLoadingPoktan = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameController = TextEditingController(text: u?['name'] ?? '');
    _emailController = TextEditingController(text: u?['email'] ?? '');
    _phoneController = TextEditingController(text: u?['phone'] ?? '');
    _farmNameController = TextEditingController(text: u?['farm_name'] ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _role = u?['role'] ?? 'user';
    _status = u?['status'] ?? 'active';
    _selectedFarmerGroupId = u?['farmer_group_id'] is int
        ? u!['farmer_group_id']
        : int.tryParse(u?['farmer_group_id']?.toString() ?? '');

    _loadFarmerGroups();
  }

  Future<void> _loadFarmerGroups() async {
    try {
      final groups = await widget.apiService.getActiveFarmerGroups();
      if (mounted) {
        setState(() {
          _farmerGroups = groups;
          if (_selectedFarmerGroupId == null && _farmerGroups.isNotEmpty) {
            _selectedFarmerGroupId = _farmerGroups.first.id;
          }
          _isLoadingPoktan = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPoktan = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _farmNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final isEdit = widget.user != null;
    final dataMap = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'farm_name': _farmNameController.text.trim(),
      'farmer_group_id': _role == 'user' ? _selectedFarmerGroupId : null,
      'role': _role,
      'status': _status,
    };
    final pass = _passwordController.text.trim();
    final passConfirm = _confirmPasswordController.text.trim();
    if (!isEdit) {
      dataMap['password'] = pass;
      dataMap['password_confirmation'] = passConfirm;
    } else if (pass.isNotEmpty) {
      dataMap['password'] = pass;
      dataMap['password_confirmation'] = passConfirm;
    }

    try {
      final Map<String, dynamic> res;
      if (isEdit) {
        res = await widget.apiService.updateSuperAdminUser(
          widget.user!['id'] as int,
          dataMap,
        );
      } else {
        res = await widget.apiService.createSuperAdminUser(dataMap);
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (res['success'] == true) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEdit ? 'Data akun berhasil diperbarui' : 'Akun baru berhasil diregistrasikan',
              ),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSaved();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Gagal memproses akun'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Ubah Akun Petani' : 'Registrasi Akun Baru',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || val.isEmpty ? 'Email wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: isEdit
                      ? 'Reset Password Baru (Opsional)'
                      : 'Password (Minimal 8 Karakter)',
                  helperText: isEdit
                      ? 'Kosongkan jika tidak ingin mengubah password akun ini'
                      : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (val) {
                  if (!isEdit && (val == null || val.isEmpty)) {
                    return 'Password wajib diisi';
                  }
                  if (val != null && val.isNotEmpty && val.length < 8) {
                    return 'Password minimal 8 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: isEdit
                      ? 'Konfirmasi Password Baru'
                      : 'Konfirmasi Password',
                  helperText: isEdit && _passwordController.text.isEmpty
                      ? 'Hanya diisi jika Anda mengganti password di atas'
                      : null,
                ),
                validator: (val) {
                  final pass = _passwordController.text;
                  if (!isEdit && (val == null || val.isEmpty)) {
                    return 'Konfirmasi password wajib diisi';
                  }
                  if (pass.isNotEmpty && val != pass) {
                    return 'Konfirmasi password tidak cocok dengan password di atas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.isEmpty ? 'Nomor telepon wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _farmNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kelompok Tani / Lahan',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Nama lahan wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: const InputDecoration(
                        labelText: 'Hak Akses',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('Petani')),
                        DropdownMenuItem(value: 'super_admin', child: Text('Admin')),
                      ],
                      onChanged: (val) => setState(() => _role = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Aktif')),
                        DropdownMenuItem(value: 'inactive', child: Text('Non-aktif')),
                      ],
                      onChanged: (val) => setState(() => _status = val!),
                    ),
                  ),
                ],
              ),
              if (_role == 'user') ...[
                const SizedBox(height: 16),
                _isLoadingPoktan
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text('Memuat Kelompok Tani...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                      )
                    : DropdownButtonFormField<int>(
                        initialValue: _selectedFarmerGroupId,
                        decoration: const InputDecoration(
                          labelText: 'Kelompok Tani (Poktan) *',
                          prefixIcon: Icon(Icons.groups_outlined, color: AppTheme.green700),
                        ),
                        items: _farmerGroups.map((g) {
                          return DropdownMenuItem<int>(
                            value: g.id,
                            child: Text('${g.code} - ${g.name}', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedFarmerGroupId = val);
                        },
                        validator: (val) {
                          if (_role == 'user' && val == null) {
                            return 'Kelompok Tani wajib dipilih untuk akun Petani';
                          }
                          return null;
                        },
                      ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Perbarui Akun' : 'Daftarkan Akun'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
