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
import 'feedback_management_screen.dart';
import 'super_admin_marketing_screen.dart';
import 'super_admin_orders_screen.dart';
import 'sales_screen.dart';
import 'super_admin_profit_loss_screen.dart';
import 'chatbot_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  final int initialTabIndex;
  const SuperAdminDashboardScreen({super.key, this.initialTabIndex = 0});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  
  late int _selectedIndex;
  bool _isLoading = true;
  int _totalUsers = 0;
  int _activeUsers = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
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

  String get _currentTitle {
    switch (_selectedIndex) {
      case 0:
        return 'Super Admin Panel';
      case 1:
        return 'Pesanan Pelanggan';
      case 2:
        return 'Kelola Pengguna';
      case 3:
        return 'Saran & Masukan';
      case 4:
        return 'Manajemen Pemasaran';
      case 5:
        return 'Penjualan Terpusat';
      case 6:
        return 'Laba/Rugi Agregat';
      case 7:
        return 'TaniBot AI (Operasional)';
      default:
        return 'Super Admin Panel';
    }
  }

  String get _currentSubtitle {
    switch (_selectedIndex) {
      case 0:
        return 'Kelola pengguna dan operasional sistem SumberTani berbasis AI';
      case 1:
        return 'Tracking dan pemrosesan pesanan produk olahan dari katalog publik';
      case 2:
        return 'Kelola akun petani, hak akses, dan impersonasi';
      case 3:
        return 'Kelola saran, kritik, dan laporan dari petani';
      case 4:
        return 'Katalog publik web dan integrasi nomor pemesanan WhatsApp';
      case 5:
        return 'Pencatatan dan rekonsiliasi penjualan komoditas & produk olahan';
      case 6:
        return 'Rekapitulasi total pendapatan, biaya, dan laba/rugi petani';
      case 7:
        return 'Asisten cerdas analisis pemasaran, stok petani, dan operasional';
      default:
        return '';
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

        Widget buildDashboardOverview() {
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

                      LayoutBuilder(
                        builder: (context, boxConstraints) {
                          final double cardWidth;
                          if (isDesktop) {
                            if (boxConstraints.maxWidth >= 1050) {
                              cardWidth = (boxConstraints.maxWidth - (3 * 16)) / 4;
                            } else {
                              cardWidth = (boxConstraints.maxWidth - 16) / 2;
                            }
                          } else {
                            cardWidth = boxConstraints.maxWidth > 550
                                ? (boxConstraints.maxWidth - 16) / 2
                                : boxConstraints.maxWidth;
                          }

                          final cards = [
                            StatCard(
                              icon: Icons.people_outline,
                              iconBg: AppTheme.blue100,
                              iconColor: AppTheme.blue600,
                              label: 'Total Petani',
                              value: '$_totalUsers',
                              badgeLabel: 'Terdaftar',
                              badgeBg: AppTheme.blue100,
                              badgeTextColor: AppTheme.blue600,
                            ),
                            StatCard(
                              icon: Icons.verified_user_outlined,
                              iconBg: AppTheme.green100,
                              iconColor: AppTheme.green700,
                              label: 'Petani Aktif',
                              value: '$_activeUsers',
                              badgeLabel: 'Aktif',
                              badgeBg: AppTheme.green100,
                              badgeTextColor: AppTheme.green700,
                            ),
                            StatCard(
                              icon: Icons.cloud_done_outlined,
                              iconBg: AppTheme.amber100,
                              iconColor: AppTheme.amber600,
                              label: 'Status Layanan',
                              value: 'Online',
                              subLabel: 'API & Server Terhubung',
                            ),
                            StatCard(
                              icon: Icons.security_outlined,
                              iconBg: AppTheme.purple100,
                              iconColor: AppTheme.purple600,
                              label: 'Hak Akses',
                              value: 'Super Admin',
                              subLabel: 'Akses Penuh Sistem',
                            ),
                          ];

                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: cards
                                 .map((c) => SizedBox(width: cardWidth, child: c))
                                 .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Modul Operasional Super Admin',
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dark900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, moduleConstraints) {
                          final double mWidth = isDesktop
                              ? (moduleConstraints.maxWidth - 24) / 2
                              : moduleConstraints.maxWidth;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildQuickNavCard(
                                title: 'Pesanan Pelanggan',
                                desc: 'Kelola order masuk, verifikasi status, dan selesaikan transaksi',
                                icon: Icons.receipt_long_rounded,
                                color: Colors.orange.shade800,
                                bg: Colors.orange.shade50,
                                width: mWidth,
                                onTap: () => setState(() => _selectedIndex = 1),
                              ),
                              _buildQuickNavCard(
                                title: 'Manajemen Pemasaran',
                                desc: 'Katalog publik web, stok produk olahan, dan kontak WhatsApp',
                                icon: Icons.storefront_rounded,
                                color: AppTheme.green700,
                                bg: AppTheme.green100,
                                width: mWidth,
                                onTap: () => setState(() => _selectedIndex = 4),
                              ),
                              _buildQuickNavCard(
                                title: 'Penjualan Terpusat',
                                desc: 'Pencatatan transaksi panen & produk olahan atas nama petani',
                                icon: Icons.point_of_sale_rounded,
                                color: AppTheme.blue600,
                                bg: AppTheme.blue100,
                                width: mWidth,
                                onTap: () => setState(() => _selectedIndex = 5),
                              ),
                              _buildQuickNavCard(
                                title: 'Laba / Rugi Agregat',
                                desc: 'Rekapitulasi total pendapatan, biaya operasional, dan margin',
                                icon: Icons.analytics_rounded,
                                color: Colors.purple,
                                bg: AppTheme.purple100,
                                width: mWidth,
                                onTap: () => setState(() => _selectedIndex = 6),
                              ),
                              _buildQuickNavCard(
                                title: 'TaniBot AI Asisten',
                                desc: 'Asisten cerdas analisis pemasaran, stok petani, dan FAQ platform',
                                icon: Icons.smart_toy_rounded,
                                color: AppTheme.amber600,
                                bg: AppTheme.amber100,
                                width: mWidth,
                                onTap: () => setState(() => _selectedIndex = 7),
                              ),
                            ],
                          );
                        },
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
                  title: _currentTitle,
                  userInitials: initials,
                  onNotificationTap: () {
                    if (_selectedIndex == 0) _loadStats();
                  },
                ),
          drawer: isDesktop
              ? null
              : AppDrawer(
                  userName: name,
                  userEmail: user?.email ?? '',
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: _buildDrawerNavItems(context),
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
                        title: _currentTitle,
                        subtitle: _currentSubtitle,
                        userInitials: initials,
                        onRefresh: () {
                          if (_selectedIndex == 0) _loadStats();
                        },
                      ),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: [
                          _isLoading
                              ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                              : buildDashboardOverview(),
                          const SuperAdminOrdersScreen(isEmbedded: true),
                          const UserManagementScreen(isEmbedded: true),
                          const FeedbackManagementScreen(isEmbedded: true),
                          SuperAdminMarketingScreen(
                            isEmbedded: true,
                            onOpenOrders: () => setState(() => _selectedIndex = 1),
                          ),
                          const SalesScreen(isEmbedded: true),
                          const SuperAdminProfitLossScreen(isEmbedded: true),
                          const ChatbotScreen(isEmbedded: true),
                        ],
                      ),
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

  Widget _buildQuickNavCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required Color bg,
    required double width,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dark900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  List<SidebarNavItem> _buildNavItems(BuildContext context) {
    return [
      SidebarNavItem(
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
        isActive: _selectedIndex == 0,
        onTap: () {
          setState(() => _selectedIndex = 0);
          _loadStats();
        },
      ),
      SidebarNavItem(
        icon: Icons.receipt_long_rounded,
        label: 'Pesanan Masuk',
        isActive: _selectedIndex == 1,
        onTap: () => setState(() => _selectedIndex = 1),
      ),
      SidebarNavItem(
        icon: Icons.manage_accounts_rounded,
        label: 'Kelola Pengguna',
        isActive: _selectedIndex == 2,
        onTap: () => setState(() => _selectedIndex = 2),
      ),
      SidebarNavItem(
        icon: Icons.rate_review_rounded,
        label: 'Saran & Masukan',
        isActive: _selectedIndex == 3,
        onTap: () => setState(() => _selectedIndex = 3),
      ),
      SidebarNavItem(
        icon: Icons.storefront_rounded,
        label: 'Pemasaran & Katalog',
        isActive: _selectedIndex == 4,
        onTap: () => setState(() => _selectedIndex = 4),
      ),
      SidebarNavItem(
        icon: Icons.point_of_sale_rounded,
        label: 'Penjualan Terpusat',
        isActive: _selectedIndex == 5,
        onTap: () => setState(() => _selectedIndex = 5),
      ),
      SidebarNavItem(
        icon: Icons.analytics_rounded,
        label: 'Laba/Rugi Agregat',
        isActive: _selectedIndex == 6,
        onTap: () => setState(() => _selectedIndex = 6),
      ),
      SidebarNavItem(
        icon: Icons.smart_toy_rounded,
        label: 'TaniBot AI',
        isActive: _selectedIndex == 7,
        onTap: () => setState(() => _selectedIndex = 7),
      ),
    ];
  }

  List<SidebarNavItem> _buildDrawerNavItems(BuildContext context) {
    return [
      SidebarNavItem(
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
        isActive: _selectedIndex == 0,
        onTap: () {
          Navigator.pop(context);
          setState(() => _selectedIndex = 0);
          _loadStats();
        },
      ),
      SidebarNavItem(
        icon: Icons.receipt_long_rounded,
        label: 'Pesanan Masuk',
        isActive: _selectedIndex == 1,
        onTap: () {
          Navigator.pop(context);
          setState(() => _selectedIndex = 1);
        },
      ),
      SidebarNavItem(
        icon: Icons.manage_accounts_rounded,
        label: 'Kelola Pengguna',
        isActive: _selectedIndex == 2,
        onTap: () {
          Navigator.pop(context);
          setState(() => _selectedIndex = 2);
        },
      ),
      SidebarNavItem(
        icon: Icons.rate_review_rounded,
        label: 'Saran & Masukan',
        isActive: _selectedIndex == 3,
        onTap: () {
          Navigator.pop(context);
          setState(() => _selectedIndex = 3);
        },
      ),
      SidebarNavItem(
        icon: Icons.storefront_rounded,
        label: 'Pemasaran & Katalog',
        isActive: _selectedIndex == 4,
        onTap: () {
          Navigator.pop(context);
          setState(() => _selectedIndex = 4);
        },
      ),
      SidebarNavItem(
        icon: Icons.point_of_sale_rounded,
        label: 'Penjualan Terpusat',
        isActive: _selectedIndex == 5,
        onTap: () {
          Navigator.pop(context);
          setState(() => _selectedIndex = 5);
        },
      ),
      SidebarNavItem(
        icon: Icons.analytics_rounded,
        label: 'Laba/Rugi Agregat',
        isActive: _selectedIndex == 6,
        onTap: () {
          Navigator.pop(context);
          setState(() => _selectedIndex = 6);
        },
      ),
      SidebarNavItem(
        icon: Icons.smart_toy_rounded,
        label: 'TaniBot AI',
        isActive: _selectedIndex == 7,
        onTap: () {
          Navigator.pop(context);
          setState(() => _selectedIndex = 7);
        },
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
