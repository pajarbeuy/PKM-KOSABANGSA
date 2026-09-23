import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/dashboard.dart';
import '../login_screen.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/harvest_chart.dart';
import '../widgets/charts/processed_sales_chart.dart';
import '../widgets/app_bottom_nav.dart';
import 'super_admin_dashboard_screen.dart';
import '../utils/navigation_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ─── Business Logic (unchanged) ──────────────────────────────────────────────
  late ApiService _apiService;
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _apiService.getDashboard();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });

        if (_dashboardData != null) {
          // No minimum stock notification on mobile dashboard.
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _parseHexColor(String hexStr) {
    try {
      return Color(int.parse('FF${hexStr.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFF27AE60);
    }
  }

  IconData _parseIcon(String iconName) {
    const map = {
      'spa': Icons.spa,
      'agriculture': Icons.agriculture,
      'inventory': Icons.inventory,
      'shopping_cart': Icons.shopping_cart,
      'person': Icons.person,
      'category': Icons.category,
      'monetization_on': Icons.monetization_on,
      'settings': Icons.settings,
      'help': Icons.help,
    };
    return map[iconName] ?? Icons.widgets;
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final auth = context.read<AuthProvider>();
              nav.pop();
              await auth.logout();
              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }



  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        if (isDesktop) {
          return _buildDesktop(context);
        }
        return _buildMobile(context);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // DESKTOP
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildDesktop(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.name ?? 'User';
    final email = auth.user?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final now = DateTime.now();
    final dateStr = DateFormat('d MMM yyyy', 'id').format(now);

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      body: Row(
        children: [
          // ── Sidebar ───────────────────────────────────────────────────────
          AppSidebar(
            userName: name,
            userEmail: email,
            userInitials: initials,
            onLogout: () => _showLogoutDialog(context),
            navItems: _buildNavItems(context, isActive: 'dashboard'),
            secondaryItems: _buildSecondaryNavItems(context),
          ),

          // ── Main ──────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  title: 'Dashboard',
                  subtitle: 'Musim 1 · $dateStr',
                  userInitials: initials,
                  onRefresh: _loadDashboard,
                ),
                if (auth.isImpersonating) _buildImpersonationBar(auth),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.green700,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadDashboard,
                          color: AppTheme.green700,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(AppTheme.pageHPad),
                            child: _buildContent(context, isDesktop: true),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // MOBILE
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildMobile(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.name ?? 'User';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppMobileAppBar(title: 'Dashboard', userInitials: initials),
      body: Column(
        children: [
          if (auth.isImpersonating) _buildImpersonationBar(auth),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.green700),
                  )
                : RefreshIndicator(
                    onRefresh: _loadDashboard,
                    color: AppTheme.green700,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
                      child: _buildContent(context, isDesktop: false),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  // ─── Nav Items ─────────────────────────────────────────────────────────────

  List<SidebarNavItem> _buildNavItems(
    BuildContext context, {
    required String isActive,
  }) {
    return NavigationHelper.buildNavItems(context, isActive);
  }

  List<SidebarNavItem> _buildSecondaryNavItems(BuildContext context) {
    return NavigationHelper.buildSecondaryNavItems(context, 'dashboard');
  }

  // ─── Main content ────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, {required bool isDesktop}) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.name ?? 'User';
    final farmName = auth.user?.farmName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Banner
        WelcomeBanner(userName: name, farmName: farmName),

        // Error
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          AlertBanner(
            message: 'Gagal memuat data',
            detail: _errorMessage,
            icon: Icons.error_outline_rounded,
            bgColor: AppTheme.red100,
            borderColor: AppTheme.red600,
            textColor: const Color(0xFF7F1D1D),
            iconColor: AppTheme.red600,
          ),
        ],

        if (_dashboardData != null) ...[
          const SizedBox(height: 24),

          // Stat cards
          _buildStatCards(context, isDesktop: isDesktop),

          const SizedBox(height: 24),

          // ── Two Dedicated Charts ─────────────────────────────────────────────
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildRawMaterialChartSection()),
                const SizedBox(width: AppTheme.cardGap),
                Expanded(child: _buildProcessedProductChartSection()),
              ],
            )
          else ...[
            _buildRawMaterialChartSection(),
            const SizedBox(height: 16),
            _buildProcessedProductChartSection(),
          ],

          const SizedBox(height: 24),

          // ── Financial Summary & Transactions ─────────────────────────────────
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _buildFinancialSummary()),
                const SizedBox(width: AppTheme.cardGap),
                Expanded(flex: 7, child: _buildTransactionsSection()),
              ],
            )
          else ...[
            _buildFinancialSummary(),
            const SizedBox(height: 16),
            _buildTransactionsSection(),
          ],
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Stat Cards ──────────────────────────────────────────────────────────────

  Widget _buildStatCards(BuildContext context, {required bool isDesktop}) {
    final stok = _dashboardData!.totalStok;
    final panen = _dashboardData!.totalPanen;
    final rev = _dashboardData!.totalPenjualan;
    final profit = rev - _dashboardData!.totalBiaya;
    final txCount = _dashboardData!.transactions.length;
    final isLow = _dashboardData!.minStock > 0
        ? stok <= _dashboardData!.minStock
        : stok < 5000;
    final minStok = _dashboardData!.minStock;
    final maxStok = _dashboardData!.maxStock;
    final stokProg = ((stok - minStok) / (maxStok - minStok)).clamp(0.0, 1.0);

    final cards = [
      StatCard(
        icon: Icons.inventory_2_outlined,
        iconBg: AppTheme.amber100,
        iconColor: AppTheme.amber600,
        value: '${_formatNumber(stok)} kg',
        label: 'Stok Gudang',
        badgeLabel: isLow ? 'Perhatian' : 'Normal',
        badgeBg: isLow ? AppTheme.amber100 : AppTheme.green100,
        badgeTextColor: isLow ? AppTheme.amber600 : AppTheme.green700,
        badgeIcon: isLow
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline,
        subLabel: 'Maks: 15.000 kg',
        progressValue: stokProg,
        progressColor: isLow ? AppTheme.amber600 : AppTheme.green500,
        progressMin: '0',
        progressMax: '15.000',
      ),
      StatCard(
        icon: Icons.eco_outlined,
        iconBg: AppTheme.green100,
        iconColor: AppTheme.green700,
        value: '${_formatNumber(panen)} kg',
        label: 'Total Panen',
        badgeLabel: '+8%',
        badgeBg: AppTheme.green100,
        badgeTextColor: AppTheme.green700,
        badgeIcon: Icons.trending_up_rounded,
        subLabel: 'Musim 1 · ${DateTime.now().year}',
      ),
      StatCard(
        icon: Icons.attach_money_rounded,
        iconBg: AppTheme.blue100,
        iconColor: AppTheme.blue600,
        value: _formatCurrencyShort(rev),
        label: 'Total Pendapatan',
        badgeLabel: '$txCount transaksi',
        badgeBg: AppTheme.blue100,
        badgeTextColor: AppTheme.blue600,
        subLabel: 'Musim ini',
      ),
      StatCard(
        icon: Icons.query_stats_rounded,
        iconBg: profit >= 0 ? AppTheme.green100 : AppTheme.red100,
        iconColor: profit >= 0 ? AppTheme.green700 : AppTheme.red600,
        value: _formatCurrencyShort(profit),
        label: 'Estimasi Untung',
        valueColor: profit >= 0 ? AppTheme.green700 : AppTheme.red600,
        subLabel: 'Musim 1 · ${DateTime.now().year}',
      ),
    ];

    if (isDesktop) {
      return Wrap(
        spacing: AppTheme.cardGap,
        runSpacing: AppTheme.cardGap,
        children: cards.map((c) => SizedBox(width: 270, child: c)).toList(),
      );
    }

    return Column(
      children: cards
          .map(
            (c) =>
                Padding(padding: const EdgeInsets.only(bottom: 12), child: c),
          )
          .toList(),
    );
  }

  Widget _buildRawMaterialChartSection() {
    final stats = _dashboardData!.monthlyStats;
    final harvests = stats.map((s) => s.harvestKg).toList();
    final sales = stats.map((s) => s.harvestSalesKg).toList();
    final labels = stats.map((s) => s.label).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.card,
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: HarvestSalesChart(
        harvestData: harvests,
        salesData: sales,
        labels: labels,
      ),
    );
  }

  Widget _buildProcessedProductChartSection() {
    return ProcessedSalesChart(
      monthlyStats: _dashboardData!.monthlyStats,
    );
  }

  // ─── Financial Summary ───────────────────────────────────────────────────────────────

  Widget _buildFinancialSummary() {
    final revenue = _dashboardData!.totalPenjualan;
    final cost = _dashboardData!.totalBiaya;
    final profit = revenue - cost;

    return SectionCard(
      title: 'Ringkasan Keuangan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _financeTile(
            label: 'Total Pendapatan',
            value: _formatCurrency(revenue),
            color: AppTheme.green700,
            bgColor: AppTheme.green100,
            icon: Icons.trending_up_rounded,
          ),
          const SizedBox(height: 12),
          _financeTile(
            label: 'Biaya Produksi',
            value: _formatCurrency(cost),
            color: AppTheme.red600,
            bgColor: AppTheme.red100,
            icon: Icons.money_off,
          ),
          const SizedBox(height: 12),
          _financeTile(
            label: 'Estimasi Untung',
            value: _formatCurrency(profit),
            color: profit >= 0 ? AppTheme.green700 : AppTheme.red600,
            bgColor: profit >= 0 ? AppTheme.green100 : AppTheme.red100,
            icon: Icons.pie_chart_outline,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _financeTile({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.card,
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Transactions Section ─────────────────────────────────────────────────────

  Widget _buildTransactionsSection() {
    final txns = _dashboardData!.transactions.take(5).toList();

    return SectionCard(
      title: 'Transaksi Stok Terbaru',
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: txns.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada transaksi.', style: AppTheme.bodySmall),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: txns.length,
              separatorBuilder: (_, b) =>
                  const Divider(height: 1, color: AppTheme.cardBorder),
              itemBuilder: (_, i) {
                final txn = txns[i];
                final isIn = txn.type == 'in';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isIn ? AppTheme.green100 : AppTheme.red100,
                          borderRadius: AppTheme.tag,
                        ),
                        child: Text(
                          isIn ? 'Masuk' : 'Keluar',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isIn ? AppTheme.green700 : AppTheme.red600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${txn.quantity} ${txn.unit}',
                          style: AppTheme.labelBold,
                        ),
                      ),
                      Text(
                        DateFormat('d MMM').format(_safeDate(txn.createdAt)),
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ─── Impersonation Bar ────────────────────────────────────────────────────────

  Widget _buildImpersonationBar(AuthProvider authProvider) {
    return Container(
      color: Colors.amber.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      width: double.infinity,
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Impersonasi: ${authProvider.user?.name}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              final success = await context
                  .read<AuthProvider>()
                  .stopImpersonating();
              if (success && mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SuperAdminDashboardScreen(),
                  ),
                  (_) => false,
                );
              }
            },
            icon: const Icon(Icons.exit_to_app, color: Colors.white, size: 16),
            label: const Text(
              'Keluar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ─── Helpers ─────────────────────────────────────────────────────────────────

  String _formatCurrency(int value) =>
      'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  String _formatCurrencyShort(int value) {
    if (value.abs() >= 1000000000) {
      return 'Rp ${(value / 1000000000).toStringAsFixed(1)} M';
    }
    if (value.abs() >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)} jt';
    }
    return _formatCurrency(value);
  }

  String _formatNumber(int value) => value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => '.',
      );

  DateTime _safeDate(String? s) => s != null && s.isNotEmpty
      ? (DateTime.tryParse(s) ?? DateTime.now())
      : DateTime.now();

  // Legacy helpers preserved for API compatibility
  // ignore: unused_element
  Color parseHexColor(String hexStr) => _parseHexColor(hexStr);
  // ignore: unused_element
  IconData parseIcon(String iconName) => _parseIcon(iconName);
}

// ─── Custom Menu Card ──────────────────────────────────────────────────────────
class _CustomMenuCard extends StatefulWidget {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _CustomMenuCard({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_CustomMenuCard> createState() => _CustomMenuCardState();
}

class _CustomMenuCardState extends State<_CustomMenuCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.08)
                : AppTheme.cardBg,
            border: Border(left: BorderSide(color: widget.color, width: 4)),
            borderRadius: AppTheme.tag,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: AppTheme.labelBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.description,
                      style: AppTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: widget.color,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
