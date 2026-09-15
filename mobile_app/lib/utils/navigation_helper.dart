import 'package:flutter/material.dart';
import '../widgets/app_sidebar.dart';
import '../screens/home_screen.dart';
import '../screens/season_screen.dart';
import '../screens/harvest_screen.dart';
import '../screens/stock_screen.dart';
import '../screens/sales_screen.dart';
import '../screens/buyers_screen.dart';
import '../screens/costs_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/target_screen.dart';
import '../screens/chatbot_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/feedback_screen.dart';

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
        icon: Icons.shopping_cart_outlined,
        label: 'Penjualan',
        isActive: currentScreen == 'sales',
        onTap: () {
          if (currentScreen != 'sales') {
            navigateTo(context, const SalesScreen());
          }
        },
      ),
      SidebarNavItem(
        icon: Icons.people_alt_outlined,
        label: 'Data Pembeli',
        isActive: currentScreen == 'buyers',
        onTap: () {
          if (currentScreen != 'buyers') {
            navigateTo(context, const BuyersScreen());
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
      SidebarNavItem(
        icon: Icons.smart_toy_outlined,
        label: 'TaniBot AI',
        isActive: currentScreen == 'chatbot',
        onTap: () {
          if (currentScreen != 'chatbot') {
            navigateTo(context, const ChatbotScreen());
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
