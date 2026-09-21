import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/harvest_screen.dart';
import '../screens/stock_screen.dart';
import '../screens/processed_products_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/season_screen.dart';
import '../screens/target_screen.dart';
import '../screens/costs_screen.dart';
import '../screens/buyers_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/settings_screen.dart';
import '../utils/navigation_helper.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    
    switch (index) {
      case 0:
        NavigationHelper.navigateTo(context, const HomeScreen());
        break;
      case 1:
        NavigationHelper.navigateTo(context, const HarvestScreen());
        break;
      case 2:
        NavigationHelper.navigateTo(context, const StockScreen());
        break;
      case 3:
        NavigationHelper.navigateTo(context, const ProcessedProductsScreen());
        break;
      case 4:
        NavigationHelper.navigateTo(context, const ReportsScreen());
        break;
      case 5:
        _showMobileMore(context);
        break;
    }
  }

  void _showMobileMore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Menu Lainnya',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildMoreItem(
                context,
                'Musim Tanam',
                Icons.calendar_month_outlined,
                () => NavigationHelper.navigateTo(context, const SeasonScreen()),
              ),
              _buildMoreItem(
                context,
                'Target Panen',
                Icons.track_changes_outlined,
                () => NavigationHelper.navigateTo(context, const TargetScreen()),
              ),
              _buildMoreItem(
                context,
                'Biaya Produksi',
                Icons.attach_money_rounded,
                () => NavigationHelper.navigateTo(context, const CostsScreen()),
              ),
              _buildMoreItem(
                context,
                'Data Pembeli',
                Icons.people_alt_outlined,
                () => NavigationHelper.navigateTo(context, const BuyersScreen()),
              ),
              const Divider(),
              _buildMoreItem(
                context,
                'Kirim Ulasan',
                Icons.feedback_outlined,
                () => NavigationHelper.navigateTo(context, const FeedbackScreen()),
              ),
              _buildMoreItem(
                context,
                'Pengaturan',
                Icons.settings_outlined,
                () => NavigationHelper.navigateTo(context, const SettingsScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.green100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.green700, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.cardBg,
      selectedItemColor: AppTheme.green700,
      unselectedItemColor: AppTheme.textSecondary,
      selectedLabelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
      currentIndex: currentIndex.clamp(0, 5),
      onTap: (index) => _onTap(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.agriculture_outlined),
          label: 'Panen',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          label: 'Stok',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.storefront_outlined),
          label: 'Olahan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded),
          label: 'Laporan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz_rounded),
          label: 'Lainnya',
        ),
      ],
    );
  }
}
