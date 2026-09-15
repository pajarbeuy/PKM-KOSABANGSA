import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../utils/navigation_helper.dart';
import 'app_header.dart';
import 'app_sidebar.dart';
import 'app_theme.dart';

/// Centralized Responsive Shell Scaffold for PKM Mobile Screens.
/// Eliminates massive LayoutBuilder & AppSidebar / AppDrawer duplicate boilerplate across 15+ screens.
class AppShell extends StatelessWidget {
  /// Nav key matching NavigationHelper (e.g. 'season', 'harvest', 'stock', etc.)
  final String currentRoute;

  /// Title displayed on Mobile AppBar and Desktop AppHeader
  final String title;

  /// Subtitle shown on Desktop AppHeader
  final String? subtitle;

  /// Main content of the screen
  final Widget child;

  /// Optional custom floating action button
  final Widget? floatingActionButton;

  /// Callback when user triggers refresh or notification icon
  final VoidCallback? onRefresh;

  /// Optional actions widget list for Desktop AppHeader
  final List<Widget>? headerActions;

  /// Optional custom bottom navigation bar override
  final Widget? bottomNavigationBar;

  /// Optional background color (defaults to AppTheme.pageBg)
  final Color? backgroundColor;

  const AppShell({
    super.key,
    required this.currentRoute,
    required this.title,
    this.subtitle,
    required this.child,
    this.floatingActionButton,
    this.onRefresh,
    this.headerActions,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari panel admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red600),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final auth = context.read<AuthProvider>();
              await auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name = user?.name ?? 'Super Admin';
    final email = user?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final navItems = NavigationHelper.buildNavItems(context, currentRoute);
        final secondaryItems = NavigationHelper.buildSecondaryNavItems(context, currentRoute);

        return Scaffold(
          backgroundColor: backgroundColor ?? AppTheme.pageBg,
          appBar: isDesktop
              ? null
              : AppMobileAppBar(
                  title: title,
                  userInitials: initials,
                  onNotificationTap: onRefresh,
                ),
          drawer: isDesktop
              ? null
              : AppDrawer(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: navItems,
                  secondaryItems: secondaryItems,
                ),
          body: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: navItems,
                  secondaryItems: secondaryItems,
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop)
                      AppHeader(
                        title: title,
                        subtitle: subtitle,
                        userInitials: initials,
                        onRefresh: onRefresh,
                        actions: headerActions,
                      ),
                    Expanded(
                      child: child,
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: isDesktop ? null : bottomNavigationBar,
        );
      },
    );
  }
}
