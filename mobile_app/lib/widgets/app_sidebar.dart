import 'package:flutter/material.dart';
import 'app_theme.dart';

// ─── Sidebar Nav Item Model ───────────────────────────────────────────────────
class SidebarNavItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? accentColor;

  const SidebarNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.accentColor,
  });
}

// ─── App Sidebar ──────────────────────────────────────────────────────────────
/// Collapsible sidebar with AnimatedContainer. Used on Desktop/Tablet.
/// On mobile, use [AppDrawer] instead via Scaffold.drawer.
class AppSidebar extends StatefulWidget {
  final List<SidebarNavItem> navItems;
  final List<SidebarNavItem>? secondaryItems;
  final String userName;
  final String userEmail;
  final String userInitials;
  final VoidCallback onLogout;
  final bool initiallyCollapsed;
  final ValueChanged<bool>? onCollapseChanged;

  const AppSidebar({
    super.key,
    required this.navItems,
    this.secondaryItems,
    required this.userName,
    required this.userEmail,
    required this.userInitials,
    required this.onLogout,
    this.initiallyCollapsed = false,
    this.onCollapseChanged,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> with SingleTickerProviderStateMixin {
  bool _isCollapsed = false;
  late AnimationController _animCtrl;
  late Animation<double> _labelOpacity;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.initiallyCollapsed;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: _isCollapsed ? 0.0 : 1.0,
    );
    _labelOpacity = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    if (!_isCollapsed) _animCtrl.value = 1.0;
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isCollapsed = !_isCollapsed);
    if (_isCollapsed) {
      _animCtrl.reverse();
    } else {
      _animCtrl.forward();
    }
    widget.onCollapseChanged?.call(_isCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: _isCollapsed ? AppTheme.sidebarCollapsedW : AppTheme.sidebarExpandedW,
      decoration: BoxDecoration(
        color: AppTheme.sidebarBg,
        boxShadow: AppTheme.sidebarShadow,
      ),
      child: Column(
        children: [
          // ── Logo / Brand ──────────────────────────────────────────────────
          SizedBox(
            height: AppTheme.headerH,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _LogoMark(),
                  FadeTransition(
                    opacity: _labelOpacity,
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _isCollapsed
                          ? const SizedBox.shrink()
                          : const Padding(
                              padding: EdgeInsets.only(left: 12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SIMHPSK',
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                                  ),
                                  Text('Pencatatan Pertanian',
                                    style: TextStyle(color: AppTheme.sidebarText, fontSize: 10, letterSpacing: 0.2),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(color: AppTheme.sidebarDivider, height: 1),

          // ── Nav items ────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Column(
                children: [
                  ...widget.navItems.map((item) => _SidebarItem(
                    item: item,
                    isCollapsed: _isCollapsed,
                    labelOpacity: _labelOpacity,
                  )),

                  if (widget.secondaryItems != null && widget.secondaryItems!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(color: AppTheme.sidebarDivider),
                    const SizedBox(height: 4),
                    if (!_isCollapsed)
                      FadeTransition(
                        opacity: _labelOpacity,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 6),
                            child: Text('MENU LAINNYA',
                              style: TextStyle(color: AppTheme.sidebarText.withValues(alpha: 0.5), fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ...widget.secondaryItems!.map((item) => _SidebarItem(
                      item: item,
                      isCollapsed: _isCollapsed,
                      labelOpacity: _labelOpacity,
                    )),
                  ],
                ],
              ),
            ),
          ),

          const Divider(color: AppTheme.sidebarDivider, height: 1),

          // ── User avatar + collapse button ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _isCollapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: _UserRowExpanded(
                initials: widget.userInitials,
                name: widget.userName,
                email: widget.userEmail,
                onLogout: widget.onLogout,
              ),
              secondChild: _UserRowCollapsed(
                initials: widget.userInitials,
                onLogout: widget.onLogout,
              ),
            ),
          ),

          // ── Collapse toggle button ────────────────────────────────────────
          GestureDetector(
            onTap: _toggle,
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppTheme.sidebarDivider,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2A4A3A), width: 1.5),
              ),
              child: AnimatedRotation(
                turns: _isCollapsed ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(Icons.chevron_left_rounded, color: AppTheme.sidebarText, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo mark widget ──────────────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.green500, AppTheme.green700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
    );
  }
}

// ── Sidebar nav item ──────────────────────────────────────────────────────────
class _SidebarItem extends StatefulWidget {
  final SidebarNavItem item;
  final bool isCollapsed;
  final Animation<double> labelOpacity;

  const _SidebarItem({
    required this.item,
    required this.isCollapsed,
    required this.labelOpacity,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.item.isActive;
    final col = widget.item.accentColor ?? AppTheme.sidebarText;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.item.onTap,
        child: Tooltip(
          message: widget.isCollapsed ? widget.item.label : '',
          preferBelow: false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.sidebarActiveBg
                  : _isHovered
                      ? AppTheme.sidebarDivider.withValues(alpha: 0.8)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border(left: BorderSide(color: AppTheme.green500, width: 3))
                  : const Border(),
            ),
            child: Row(
              children: [
                Icon(
                  widget.item.icon,
                  size: 20,
                  color: isActive
                      ? AppTheme.green500
                      : _isHovered
                          ? Colors.white.withValues(alpha: 0.8)
                          : col,
                ),
                FadeTransition(
                  opacity: widget.labelOpacity,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: widget.isCollapsed
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              widget.item.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                color: isActive ? AppTheme.sidebarTextActive : AppTheme.sidebarText,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── User row expanded ─────────────────────────────────────────────────────────
class _UserRowExpanded extends StatelessWidget {
  final String initials;
  final String name;
  final String email;
  final VoidCallback onLogout;

  const _UserRowExpanded({
    required this.initials,
    required this.name,
    required this.email,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(initials: initials, radius: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              Text(email, style: const TextStyle(color: AppTheme.sidebarText, fontSize: 11), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: AppTheme.sidebarText, size: 17),
          onPressed: onLogout,
          tooltip: 'Logout',
          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

// ── User row collapsed ────────────────────────────────────────────────────────
class _UserRowCollapsed extends StatelessWidget {
  final String initials;
  final VoidCallback onLogout;

  const _UserRowCollapsed({required this.initials, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Center(child: _Avatar(initials: initials, radius: 18));
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String initials;
  final double radius;

  const _Avatar({required this.initials, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.green500,
      child: Text(
        initials,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: radius * 0.7),
      ),
    );
  }
}

// ─── App Drawer (Mobile) ──────────────────────────────────────────────────────
/// Full-width drawer for mobile. Wrap in Scaffold.drawer.
class AppDrawer extends StatelessWidget {
  final List<SidebarNavItem> navItems;
  final List<SidebarNavItem>? secondaryItems;
  final String userName;
  final String userEmail;
  final String userInitials;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.navItems,
    this.secondaryItems,
    required this.userName,
    required this.userEmail,
    required this.userInitials,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.sidebarBg,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _LogoMark(),
                  const SizedBox(width: 12),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SIMHPSK', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                      Text('Pencatatan Pertanian', style: TextStyle(color: AppTheme.sidebarText, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.sidebarDivider, height: 1),
            // User info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  _Avatar(initials: userInitials, radius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15), overflow: TextOverflow.ellipsis),
                        Text(userEmail, style: const TextStyle(color: AppTheme.sidebarText, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.sidebarDivider, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                children: [
                  ...navItems.map((item) => ListTile(
                    leading: Icon(item.icon, size: 20,
                      color: item.isActive ? AppTheme.green500 : AppTheme.sidebarText),
                    title: Text(item.label,
                      style: TextStyle(fontSize: 14,
                        fontWeight: item.isActive ? FontWeight.w700 : FontWeight.w500,
                        color: item.isActive ? Colors.white : AppTheme.sidebarText)),
                    tileColor: item.isActive ? AppTheme.sidebarActiveBg : Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: () { Navigator.pop(context); item.onTap(); },
                  )),
                  if (secondaryItems != null && secondaryItems!.isNotEmpty) ...[
                    const Divider(color: AppTheme.sidebarDivider),
                    ...secondaryItems!.map((item) => ListTile(
                      leading: Icon(item.icon, size: 20,
                        color: item.accentColor ?? AppTheme.sidebarText),
                      title: Text(item.label,
                        style: TextStyle(fontSize: 14, color: item.accentColor ?? AppTheme.sidebarText)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onTap: () { Navigator.pop(context); item.onTap(); },
                    )),
                  ],
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFFFF6B6B)),
                    title: const Text('Logout', style: TextStyle(fontSize: 14, color: Color(0xFFFF6B6B), fontWeight: FontWeight.w600)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
