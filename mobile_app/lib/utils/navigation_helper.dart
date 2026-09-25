import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_sidebar.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/season_screen.dart';
import '../screens/harvest_screen.dart';
import '../screens/stock_screen.dart';
import '../screens/processed_products_screen.dart';
import '../screens/costs_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/target_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/farmer_commodity_screen.dart';
import '../screens/super_admin_dashboard_screen.dart';
import '../screens/market_price_screen.dart';

class NavigationHelper {
  static void navigateTo(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: const Duration(milliseconds: 150),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  static List<SidebarNavItem> buildNavItems(BuildContext context, String currentScreen) {
    final auth = context.read<AuthProvider>();
    final isSuperAdmin = auth.user?.role == 'super_admin';

    if (isSuperAdmin) {
      return [
        SidebarNavItem(
          icon: Icons.dashboard_rounded,
          label: 'Dashboard',
          isActive: currentScreen == 'super_admin_dashboard',
          onTap: () => navigateTo(context, const SuperAdminDashboardScreen(initialTabIndex: 0)),
        ),
        SidebarNavItem(
          icon: Icons.manage_accounts_rounded,
          label: 'Kelola Pengguna',
          isActive: false,
          onTap: () => navigateTo(context, const SuperAdminDashboardScreen(initialTabIndex: 1)),
        ),
        SidebarNavItem(
          icon: Icons.rate_review_rounded,
          label: 'Saran & Masukan',
          isActive: false,
          onTap: () => navigateTo(context, const SuperAdminDashboardScreen(initialTabIndex: 2)),
        ),
        SidebarNavItem(
          icon: Icons.storefront_rounded,
          label: 'Pemasaran & Katalog',
          isActive: currentScreen == 'super_admin_marketing',
          onTap: () => navigateTo(context, const SuperAdminDashboardScreen(initialTabIndex: 3)),
        ),
        SidebarNavItem(
          icon: Icons.point_of_sale_rounded,
          label: 'Penjualan Terpusat',
          isActive: currentScreen == 'sales',
          onTap: () => navigateTo(context, const SuperAdminDashboardScreen(initialTabIndex: 4)),
        ),
        SidebarNavItem(
          icon: Icons.analytics_rounded,
          label: 'Laba/Rugi Agregat',
          isActive: currentScreen == 'super_admin_profit_loss',
          onTap: () => navigateTo(context, const SuperAdminDashboardScreen(initialTabIndex: 5)),
        ),
        SidebarNavItem(
          icon: Icons.smart_toy_rounded,
          label: 'TaniBot AI',
          isActive: currentScreen == 'chatbot',
          onTap: () => navigateTo(context, const SuperAdminDashboardScreen(initialTabIndex: 6)),
        ),
        SidebarNavItem(
          icon: Icons.trending_up_rounded,
          label: 'Harga Acuan Pasar',
          isActive: currentScreen == 'market_prices',
          onTap: () => navigateTo(context, const MarketPriceScreen()),
        ),
      ];
    }

    // Farmer Navigation (Produk Olahan included; Penjualan and TaniBot managed centrally by Super Admin)
    return [
      SidebarNavItem(
        icon: Icons.grid_view_rounded,
        label: 'Dashboard',
        isActive: currentScreen == 'dashboard',
        onTap: () {
          if (currentScreen != 'dashboard') {
            navigateTo(context, const HomeScreen());
          }
        },
      ),
      SidebarNavItem(
        icon: Icons.grass_rounded,
        label: 'Hasil Tani',
        isActive: currentScreen == 'commodities',
        onTap: () {
          if (currentScreen != 'commodities') {
            navigateTo(context, const FarmerCommodityScreen());
          }
        },
      ),
      SidebarNavItem(
        icon: Icons.trending_up_rounded,
        label: 'Harga Acuan',
        isActive: currentScreen == 'market_prices',
        onTap: () {
          if (currentScreen != 'market_prices') {
            navigateTo(context, const MarketPriceScreen());
          }
        },
      ),
      SidebarNavItem(
        icon: Icons.calendar_month_outlined,
        label: 'Musim Tanam',
        isActive: currentScreen == 'season',
        onTap: () {
          if (currentScreen != 'season') {
            navigateTo(context, const SeasonScreen());
          }
        },
      ),
      SidebarNavItem(
        icon: Icons.agriculture_outlined,
        label: 'Pencatatan Panen',
        isActive: currentScreen == 'harvest',
        onTap: () {
          if (currentScreen != 'harvest') {
            navigateTo(context, const HarvestScreen());
          }
        },
      ),
      SidebarNavItem(
        icon: Icons.inventory_2_outlined,
        label: 'Stok Gudang',
        isActive: currentScreen == 'stock',
        onTap: () {
          if (currentScreen != 'stock') {
            navigateTo(context, const StockScreen());
          }
        },
      ),
      SidebarNavItem(
        icon: Icons.storefront_outlined,
        label: 'Produk Olahan',
        isActive: currentScreen == 'processed_products',
        onTap: () {
          if (currentScreen != 'processed_products') {
            navigateTo(context, const ProcessedProductsScreen());
          }
        },
      ),
      SidebarNavItem(
        icon: Icons.attach_money_rounded,
        label: 'Biaya Produksi',
        isActive: currentScreen == 'costs',
        onTap: () {
          if (currentScreen != 'costs') {
            navigateTo(context, const CostsScreen());
          }
        },
      ),
      SidebarNavItem(
        icon: Icons.bar_chart_rounded,
        label: 'Laporan',
        isActive: currentScreen == 'reports',
        onTap: () {
          if (currentScreen != 'reports') {
            navigateTo(context, const ReportsScreen());
          }
        },
      ),
      SidebarNavItem(
        icon: Icons.track_changes_rounded,
        label: 'Target Panen',
        isActive: currentScreen == 'target',
        onTap: () {
          if (currentScreen != 'target') {
            navigateTo(context, const TargetScreen());
          }
        },
      ),
    ];
  }

  static List<SidebarNavItem> buildSecondaryNavItems(BuildContext context, String currentScreen) {
    return [
      SidebarNavItem(
        icon: Icons.settings_outlined,
        label: 'Pengaturan',
        isActive: currentScreen == 'settings',
        onTap: () {
          if (currentScreen != 'settings') {
            navigateTo(context, const SettingsScreen());
          }
        },
      ),
      SidebarNavItem(
        icon: Icons.person_outline,
        label: 'Profil',
        isActive: currentScreen == 'profile',
        onTap: () {
          if (currentScreen != 'profile') {
            navigateTo(context, const ProfileScreen());
          }
        },
      ),
      SidebarNavItem(
        icon: Icons.feedback_outlined,
        label: 'Kirim Ulasan',
        isActive: currentScreen == 'feedback',
        onTap: () {
          if (currentScreen != 'feedback') {
            navigateTo(context, const FeedbackScreen());
          }
        },
      ),
    ];
  }
}
