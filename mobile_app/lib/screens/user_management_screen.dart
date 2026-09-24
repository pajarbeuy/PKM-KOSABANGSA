import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_theme.dart';
import '../login_screen.dart';
import '../screens/super_admin_dashboard_screen.dart';
import 'feedback_management_screen.dart';
import 'home_screen.dart';
import '../widgets/users/user_form_bottom_sheet.dart';

class UserManagementScreen extends StatefulWidget {
  final bool isEmbedded;
  const UserManagementScreen({super.key, this.isEmbedded = false});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _apiService.getSuperAdminUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Gagal mengambil data user: $e');
    }
  }

  Future<void> _impersonateUser(int id, String name) async {
    final navigator = Navigator.of(context);
    final auth = context.read<AuthProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Impersonasi Akun'),
        content: Text(
          'Apakah Anda ingin masuk dan bertindak sebagai petani "$name"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Masuk Session',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await auth.impersonate(id);
      if (success) {
        _showSuccess('Impersonasi aktif! Bertindak sebagai $name');
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        setState(() => _isLoading = false);
        _showError('Gagal melakukan impersonasi');
      }
    }
  }

  Future<void> _deleteUser(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun "$name" secara permanen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus Permanen',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final result = await _apiService.deleteSuperAdminUser(id);
      if (result['success'] == true) {
        _showSuccess('Akun berhasil dihapus permanen');
        _loadUsers();
      } else {
        setState(() => _isLoading = false);
        _showError(result['message'] ?? 'Gagal menghapus akun');
      }
    }
  }

  void _showAddEditUserBottomSheet([Map<String, dynamic>? user]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => UserFormBottomSheet(
        apiService: _apiService,
        user: user,
        onSaved: () {
          _loadUsers();
        },
      ),
    );
  }



  void _showSuccess(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  List<dynamic> _getFilteredUsers(int index) {
    if (index == 0) return _users;
    if (index == 1) return _users.where((u) => u['status'] == 'active').toList();
    return _users.where((u) => u['status'] == 'inactive').toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final name = user?.name ?? 'Super Admin';
    final email = user?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    Widget buildMainContent() {
      return Column(
        children: [
          Material(
            color: AppTheme.cardBg,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.textPrimary,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.green700,
              tabs: const [
                Tab(text: 'Semua'),
                Tab(text: 'Aktif'),
                Tab(text: 'Non-aktif'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.green700,
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: List.generate(3, (index) {
                      final filteredList = _getFilteredUsers(index);
                      if (filteredList.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada data akun dalam kategori ini',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 800) {
                            return _buildDesktopLayout(filteredList);
                          }
                          return _buildMobileLayout(filteredList);
                        },
                      );
                    }),
                  ),
          ),
        ],
      );
    }

    if (widget.isEmbedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: buildMainContent(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddEditUserBottomSheet(),
          backgroundColor: AppTheme.green700,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Tambah Akun'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: AppTheme.pageBg,
          appBar: isDesktop
              ? null
              : AppMobileAppBar(
                  title: 'Kelola Pengguna',
                  userInitials: initials,
                  onNotificationTap: _loadUsers,
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
                        title: 'Kelola Pengguna',
                        subtitle: 'Kelola akun petani dan impersonasi',
                        userInitials: initials,
                        onRefresh: _loadUsers,
                      ),
                    Expanded(child: buildMainContent()),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddEditUserBottomSheet(),
            backgroundColor: AppTheme.green700,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Tambah Akun'),
          ),
        );
      },
    );
  }

  List<SidebarNavItem> _buildNavItems(BuildContext context) {
    return [
      SidebarNavItem(
        icon: Icons.dashboard,
        label: 'Dashboard',
        isActive: false,
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const SuperAdminDashboardScreen(),
            ),
          );
        },
      ),
      SidebarNavItem(
        icon: Icons.manage_accounts,
        label: 'Kelola Pengguna',
        isActive: true,
        onTap: () {},
      ),

      SidebarNavItem(
        icon: Icons.rate_review,
        label: 'Saran & Masukan',
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FeedbackManagementScreen()),
        ),
      ),
    ];
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari panel admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
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

  Widget _buildStatusBadge(String status) {
    final color = status == 'active' ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status == 'active' ? 'AKTIF' : 'NON-AKTIF',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> u) {
    final isAdmin = u['role'] == 'super_admin';
    final id = u['id'] as int;
    final name = u['name'] ?? '';

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [
        if (!isAdmin && u['status'] == 'active')
          TextButton.icon(
            onPressed: () => _impersonateUser(id, name),
            icon: const Icon(Icons.login, size: 14, color: Colors.blue),
            label: const Text(
              'Impersonasi',
              style: TextStyle(color: Colors.blue, fontSize: 12),
            ),
          ),
        TextButton.icon(
          onPressed: () => _showAddEditUserBottomSheet(u),
          icon: const Icon(Icons.edit, size: 14, color: Colors.black54),
          label: const Text(
            'Ubah',
            style: TextStyle(color: Colors.black87, fontSize: 12),
          ),
        ),
        TextButton.icon(
          onPressed: () => _deleteUser(id, name),
          icon: const Icon(Icons.delete, size: 14, color: Colors.red),
          label: const Text(
            'Hapus',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(List<dynamic> filteredList) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredList.length,
      separatorBuilder: (context, idx) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final u = filteredList[idx];
        final isAdmin = u['role'] == 'super_admin';

        return Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          (isAdmin ? Colors.amber : const Color(0xFF1A7A4A))
                              .withValues(alpha: 0.1),
                      child: Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person,
                        color: isAdmin
                            ? Colors.amber.shade800
                            : const Color(0xFF1A7A4A),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            u['email'] ?? '',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          if (u['farm_name'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.landscape_rounded,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  u['farm_name'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (u['farmer_group'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.groups_rounded,
                                  size: 12,
                                  color: Color(0xFF1A7A4A),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  u['farmer_group']['name'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A7A4A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [_buildStatusBadge(u['status'])],
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildActionButtons(u as Map<String, dynamic>),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(List<dynamic> filteredList) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daftar Akun Tani',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Total: ${filteredList.length} Akun',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 80,
                  ),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.resolveWith<Color>(
                      (states) => const Color(0xFFF9FAFB),
                    ),
                    dataRowMaxHeight: 70,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Nama & Email',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Nama Lahan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Kelompok Tani',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Nomor Telepon',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Hak Akses',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Persetujuan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Aksi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: filteredList.map((u) {
                      final isAdmin = u['role'] == 'super_admin';
                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  u['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  u['email'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(u['farm_name'] ?? '-')),
                          DataCell(
                            Text(
                              u['farmer_group'] != null
                                  ? (u['farmer_group']['name'] ?? '-')
                                  : '-',
                              style: TextStyle(
                                fontWeight: u['farmer_group'] != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: u['farmer_group'] != null
                                    ? const Color(0xFF1A7A4A)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          DataCell(Text(u['phone'] ?? '-')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isAdmin
                                            ? Colors.amber
                                            : const Color(0xFF1A7A4A))
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isAdmin ? 'Admin' : 'Petani',
                                style: TextStyle(
                                  color: isAdmin
                                      ? Colors.amber.shade900
                                      : const Color(0xFF1A7A4A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          DataCell(_buildStatusBadge(u['status'])),
                          DataCell(_buildStatusBadge(u['status'])),
                          DataCell(
                            _buildActionButtons(u as Map<String, dynamic>),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
