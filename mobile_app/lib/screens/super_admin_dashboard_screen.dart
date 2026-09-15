import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_theme.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/stat_card.dart';
import '../login_screen.dart';
import 'user_management_screen.dart';
import 'landing_editor_screen.dart';
import 'custom_menus_screen.dart';
import 'feedback_management_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  int _totalUsers = 0;
  int _activeUsers = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _apiService.getSuperAdminDashboard();
      if (stats != null) {
        setState(() {
          _totalUsers = stats['totalUsers'] as int? ?? 0;
          _activeUsers = stats['activeUsers'] as int? ?? 0;
        });
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil statistik: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final name = user?.name ?? 'Super Admin';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        Widget buildBody() {
          return RefreshIndicator(
            onRefresh: _loadStats,
            color: AppTheme.green700,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isDesktop ? AppTheme.pageHPad : 16.0),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WelcomeBanner(
                        userName: name,
                        seasonLabel: 'Super Admin Dashboard',
                      ),
                      const SizedBox(height: 24),

                      GridView.count(
                        crossAxisCount: isDesktop ? 2 : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: isDesktop ? 2.0 : 1.9,
                        children: [
                          StatCard(
                            icon: Icons.people_outline,
                            iconBg: AppTheme.blue100,
                            iconColor: AppTheme.blue600,
                            label: 'Total Petani',
                            value: '$_totalUsers',
                            badgeLabel: 'Aktif',
                            badgeBg: AppTheme.green100,
                            badgeTextColor: AppTheme.green700,
                          ),
                          StatCard(
                            icon: Icons.verified_user_outlined,
                            iconBg: AppTheme.green100,
                            iconColor: AppTheme.green700,
                            label: 'Petani Aktif',
                            value: '$_activeUsers',
                            subLabel: 'Dari total pengguna terdaftar',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      SectionCard(
                        title: 'Modul Administrasi',
                        headerAction: TextButton.icon(
                          onPressed: _loadStats,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Muat ulang'),
                        ),
                        child: GridView.count(
                          crossAxisCount: isDesktop ? 4 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                          children: [
                            _buildModuleCard(
                              icon: Icons.manage_accounts_rounded,
                              title: 'Kelola Pengguna',
                              desc: 'Registrasi & Impersonasi',
                              color: AppTheme.green700,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementScreen())).then((_) => _loadStats()),
                            ),
                            _buildModuleCard(
                              icon: Icons.edit_note_rounded,
                              title: 'Edit Landing Page',
                              desc: 'Kelola isi CTA depan',
                              color: AppTheme.blue600,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LandingEditorScreen())).then((_) => _loadStats()),
                            ),
                            _buildModuleCard(
                              icon: Icons.grid_view_rounded,
                              title: 'Kelola Shortcut',
                              desc: 'Modul menu petani',
                              color: AppTheme.amber600,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomMenusScreen())).then((_) => _loadStats()),
                            ),
                            _buildModuleCard(
                              icon: Icons.rate_review_rounded,
                              title: 'Saran & Kritik',
                              desc: 'Aduan & masukan petani',
                              color: AppTheme.purple600,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackManagementScreen())).then((_) => _loadStats()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.pageBg,
          appBar: isDesktop
              ? null
              : AppMobileAppBar(
                  title: 'Super Admin Panel',
                  userInitials: initials,
                  onNotificationTap: _loadStats,
                ),
          drawer: isDesktop
              ? null
              : AppDrawer(
                  userName: name,
                  userEmail: user?.email ?? '',
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: _buildNavItems(context),
                ),
          body: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  userName: name,
                  userEmail: user?.email ?? '',
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: _buildNavItems(context),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop)
                      AppHeader(
                        title: 'Super Admin Panel',
                        subtitle: 'Kelola pengguna dan operasional',
                        userInitials: initials,
                        onRefresh: _loadStats,
                      ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                          : buildBody(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  List<SidebarNavItem> _buildNavItems(BuildContext context) {
    return [
      SidebarNavItem(
        icon: Icons.dashboard,
        label: 'Dashboard',
        isActive: true,
        onTap: _loadStats,
      ),
      SidebarNavItem(
        icon: Icons.manage_accounts,
        label: 'Kelola Pengguna',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementScreen())).then((_) => _loadStats()),
      ),
      SidebarNavItem(
        icon: Icons.edit_note,
        label: 'Edit Landing Page',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LandingEditorScreen())).then((_) => _loadStats()),
      ),
      SidebarNavItem(
        icon: Icons.grid_view,
        label: 'Kelola Menu Shortcut',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomMenusScreen())).then((_) => _loadStats()),
      ),
      SidebarNavItem(
        icon: Icons.rate_review,
        label: 'Saran & Masukan',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackManagementScreen())).then((_) => _loadStats()),
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
}
