import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_theme.dart';
import '../login_screen.dart';
import 'super_admin_dashboard_screen.dart';
import 'user_management_screen.dart';
import 'landing_editor_screen.dart';
import 'feedback_management_screen.dart';

class CustomMenusScreen extends StatefulWidget {
  const CustomMenusScreen({super.key});

  @override
  State<CustomMenusScreen> createState() => _CustomMenusScreenState();
}

class _CustomMenusScreenState extends State<CustomMenusScreen> {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _menus = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    setState(() => _isLoading = true);
    try {
      final menus = await _apiService.getDashboardMenus();
      setState(() {
        _menus = menus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Gagal mengambil data menu: $e');
    }
  }

  Future<void> _deleteMenu(int id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Menu Shortcut'),
        content: Text('Apakah Anda yakin ingin menghapus menu "$title" dari dashboard petani?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final result = await _apiService.deleteDashboardMenu(id);
      if (result['success'] == true) {
        _showSuccess('Menu berhasil dihapus');
        _loadMenus();
      } else {
        setState(() => _isLoading = false);
        _showError(result['message'] ?? 'Gagal menghapus menu');
      }
    }
  }

  void _showAddEditMenuBottomSheet([Map<String, dynamic>? menu]) {
    final isEdit = menu != null;
    final titleController = TextEditingController(text: menu?['title'] ?? '');
    final iconController = TextEditingController(text: menu?['icon'] ?? 'agriculture');
    final descController = TextEditingController(text: menu?['description'] ?? '');
    final orderController = TextEditingController(text: (menu?['sort_order'] ?? 1).toString());
    final menuColor = menu?['color'] ?? '#27AE60';
    
    bool isActive = menu?['is_active'] == 1 || menu?['is_active'] == true;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24, left: 24, right: 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Ubah Menu Shortcut' : 'Tambah Menu Shortcut Baru',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Menu',
                    hintText: 'Contoh: Pupuk Organik',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Nama menu wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: iconController,
                  decoration: const InputDecoration(
                    labelText: 'Icon Name (Material)',
                    hintText: 'Contoh: spa, agriculture, inventory, shopping_cart, etc.',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Nama icon wajib diisi' : null,
                ),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan Singkat',
                    hintText: 'Contoh: Untuk mencatat log pembelian pupuk',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Keterangan wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: orderController,
                  decoration: const InputDecoration(
                    labelText: 'Urutan Tampil (Sort Order)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || int.tryParse(val) == null ? 'Urutan tampil harus berupa angka' : null,
                ),
                if (isEdit) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Status Menu Aktif', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    value: isActive,
                    activeThumbColor: const Color(0xFF135835),
                    onChanged: (val) => setState(() => isActive = val),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF135835),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(context);
                      setState(() => _isLoading = true);

                      final dataMap = {
                        'title': titleController.text.trim(),
                        'icon': iconController.text.trim(),
                        'color': menuColor,
                        'description': descController.text.trim(),
                        'sort_order': int.parse(orderController.text),
                      };
                      if (isEdit) {
                        dataMap['is_active'] = isActive;
                      }

                      final Map<String, dynamic> res;
                      if (isEdit) {
                        res = await _apiService.updateDashboardMenu(menu['id'] as int, dataMap);
                      } else {
                        res = await _apiService.createDashboardMenu(dataMap);
                      }

                      if (res['success'] == true) {
                        _showSuccess(isEdit ? 'Menu shortcut berhasil diperbarui' : 'Menu shortcut baru ditambahkan');
                        _loadMenus();
                      } else {
                        setState(() => _isLoading = false);
                        _showError(res['message'] ?? 'Gagal memproses menu');
                      }
                    },
                    child: Text(isEdit ? 'Perbarui Menu' : 'Tambahkan Menu'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _parseHexColor(String hexStr) {
    try {
      final cleanHex = hexStr.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return const Color(0xFF27AE60);
    }
  }

  List<SidebarNavItem> _buildNavItems(BuildContext context) {
    return [
      SidebarNavItem(
        icon: Icons.dashboard,
        label: 'Dashboard',
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuperAdminDashboardScreen())),
      ),
      SidebarNavItem(
        icon: Icons.manage_accounts,
        label: 'Kelola Pengguna',
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserManagementScreen())),
      ),
      SidebarNavItem(
        icon: Icons.edit_note,
        label: 'Edit Landing Page',
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LandingEditorScreen())),
      ),
      SidebarNavItem(
        icon: Icons.grid_view,
        label: 'Kelola Menu Shortcut',
        isActive: true,
        onTap: () {},
      ),
      SidebarNavItem(
        icon: Icons.rate_review,
        label: 'Saran & Masukan',
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FeedbackManagementScreen())),
      ),
    ];
  }

  IconData _parseIcon(String iconName) {
    switch (iconName) {
      case 'spa': return Icons.spa;
      case 'agriculture': return Icons.agriculture;
      case 'inventory': return Icons.inventory;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'person': return Icons.person;
      case 'category': return Icons.category;
      case 'monetization_on': return Icons.monetization_on;
      case 'settings': return Icons.settings;
      case 'help': return Icons.help;
      default: return Icons.widgets;
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari panel admin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final auth = context.read<AuthProvider>();
              navigator.pop();
              await auth.logout();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final name = auth.user?.name ?? 'Super Admin';
    final email = auth.user?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: AppTheme.pageBg,
          appBar: isDesktop
              ? null
              : AppMobileAppBar(
                  title: 'Kelola Shortcut',
                  userInitials: initials,
                  onNotificationTap: _loadMenus,
                ),
          drawer: isDesktop
              ? null
              : AppDrawer(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: _buildNavItems(context),
                ),
          body: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: _buildNavItems(context),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop)
                      AppHeader(
                        title: 'Kelola Shortcut',
                        subtitle: 'Atur menu pintasan pengguna',
                        userInitials: initials,
                        onRefresh: _loadMenus,
                      ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                          : RefreshIndicator(
                              onRefresh: _loadMenus,
                              color: AppTheme.green700,
                              child: _menus.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.widgets_outlined, size: 64, color: Colors.grey.shade300),
                                          const SizedBox(height: 12),
                                          const Text('Belum ada menu shortcut tambahan', style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    )
                                  : LayoutBuilder(
                                      builder: (context, constraints) {
                                        final isDesktopContent = constraints.maxWidth > 800;
                                        if (isDesktopContent) {
                                          return GridView.builder(
                                            physics: const AlwaysScrollableScrollPhysics(),
                                            padding: const EdgeInsets.all(24),
                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: constraints.maxWidth > 1200 ? 3 : 2,
                                              crossAxisSpacing: 16,
                                              mainAxisSpacing: 16,
                                              childAspectRatio: 2.2,
                                            ),
                                            itemCount: _menus.length,
                                            itemBuilder: (context, index) {
                                              return _buildMenuTile(_menus[index]);
                                            },
                                          );
                                        }
                                        return ListView.separated(
                                          padding: const EdgeInsets.all(16),
                                          itemCount: _menus.length,
                                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                                          itemBuilder: (context, index) {
                                            return _buildMenuTile(_menus[index]);
                                          },
                                        );
                                      },
                                    ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddEditMenuBottomSheet(),
            backgroundColor: AppTheme.green700,
            icon: const Icon(Icons.add_box_rounded),
            label: const Text('Tambah Menu'),
          ),
        );
      },
    );
  }

  Widget _buildMenuTile(dynamic m) {
    final color = _parseHexColor(m['color'] ?? '#27AE60');
    final isActive = m['is_active'] == 1 || m['is_active'] == true;

    return Card(
      elevation: 0.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Center(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _parseIcon(m['icon'] ?? 'widgets'),
              color: color,
              size: 24,
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  m['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isActive ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'AKTIF' : 'NON-AKTIF',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.grey,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m['description'] ?? '',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.sort_rounded, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Urutan: ${m['sort_order'] ?? 1}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                    if (m['url'] != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.link_rounded, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          m['url'],
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'edit') {
                _showAddEditMenuBottomSheet(m as Map<String, dynamic>);
              } else if (val == 'delete') {
                _deleteMenu(m['id'] as int, m['title'] ?? '');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Ubah')]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
