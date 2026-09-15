import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import 'custom_menus_screen.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() => _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  List<dynamic> _feedbacks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to filter list
    });
    _fetchFeedbacks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFeedbacks() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getFeedbacks();
      setState(() {
        _feedbacks = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<dynamic> get _filteredFeedbacks {
    if (_tabController.index == 0) {
      return _feedbacks;
    } else if (_tabController.index == 1) {
      return _feedbacks.where((f) => f['status'] == 'unread').toList();
    } else {
      return _feedbacks.where((f) => f['status'] == 'read').toList();
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      final res = await _apiService.markFeedbackAsRead(id);
      if (res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Feedback ditandai sudah dibaca'),
              backgroundColor: Color(0xFF27AE60),
            ),
          );
        }
        _fetchFeedbacks();
      } else {
        throw Exception(res['message'] ?? 'Gagal memperbarui status');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFeedback(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Feedback'),
        content: const Text('Apakah Anda yakin ingin menghapus feedback ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await _apiService.deleteFeedback(id);
      if (res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Feedback berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _fetchFeedbacks();
      } else {
        throw Exception(res['message'] ?? 'Gagal menghapus');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFeedbackDetail(dynamic feedback) {
    final user = feedback['user'] ?? {};
    final userName = user['name'] ?? 'Petani Anonim';
    final userEmail = user['email'] ?? '-';
    final farmName = user['farm_name'] ?? 'Pertanian Kentang';
    final phone = user['phone'] ?? '-';
    final dateStr = feedback['created_at'] ?? '';
    final message = feedback['message'] ?? '';
    
    DateTime? parsedDate;
    if (dateStr.isNotEmpty) {
      parsedDate = DateTime.tryParse(dateStr);
    }
    final formattedDate = parsedDate != null 
        ? DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(parsedDate)
        : dateStr;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detail Masukan / Feedback',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF135835),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF27AE60).withValues(alpha: 0.1),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        color: Color(0xFF27AE60),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          farmName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoRow(Icons.email_outlined, 'Email', userEmail),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.phone_outlined, 'Telepon', phone),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.calendar_today_outlined, 'Tanggal Kirim', formattedDate),
              const SizedBox(height: 20),
              const Text(
                'Pesan / Saran:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (feedback['status'] == 'unread') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _markAsRead(feedback['id']);
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Tandai Dibaca'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteFeedback(feedback['id']);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
                  title: 'Saran & Masukan',
                  userInitials: initials,
                  onNotificationTap: _fetchFeedbacks,
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
                        title: 'Saran & Masukan',
                        subtitle: 'Kelola masukan pengguna',
                        userInitials: initials,
                        onRefresh: _fetchFeedbacks,
                      ),
                    Material(
                      color: AppTheme.cardBg,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.textPrimary,
                        unselectedLabelColor: AppTheme.textSecondary,
                        indicatorColor: AppTheme.green700,
                        indicatorWeight: 3.0,
                        tabs: const [
                          Tab(text: 'Semua'),
                          Tab(text: 'Belum Dibaca'),
                          Tab(text: 'Sudah Dibaca'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                          : RefreshIndicator(
                              onRefresh: _fetchFeedbacks,
                              color: AppTheme.green700,
                              child: _filteredFeedbacks.isEmpty
                                  ? _buildEmptyState()
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
                                              childAspectRatio: 1.5,
                                            ),
                                            itemCount: _filteredFeedbacks.length,
                                            itemBuilder: (context, index) {
                                              final feedback = _filteredFeedbacks[index];
                                              return _buildFeedbackCard(feedback);
                                            },
                                          );
                                        }
                                        return ListView.builder(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.all(16),
                                          itemCount: _filteredFeedbacks.length,
                                          itemBuilder: (context, index) {
                                            final feedback = _filteredFeedbacks[index];
                                            return _buildFeedbackCard(feedback);
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
        );
      },
    );
  }

  Widget _buildFeedbackCard(dynamic feedback) {
    final user = feedback['user'] ?? {};
    final userName = user['name'] ?? 'Petani Anonim';
    final farmName = user['farm_name'] ?? 'Pertanian Kentang';
    final message = feedback['message'] ?? '';
    final isUnread = feedback['status'] == 'unread';
    final dateStr = feedback['created_at'] ?? '';
    
    DateTime? parsedDate;
    if (dateStr.isNotEmpty) {
      parsedDate = DateTime.tryParse(dateStr);
    }
    
    String relativeTime = '';
    if (parsedDate != null) {
      final diff = DateTime.now().difference(parsedDate);
      if (diff.inDays > 0) {
        relativeTime = '${diff.inDays} hari yang lalu';
      } else if (diff.inHours > 0) {
        relativeTime = '${diff.inHours} jam yang lalu';
      } else if (diff.inMinutes > 0) {
        relativeTime = '${diff.inMinutes} menit yang lalu';
      } else {
        relativeTime = 'Baru saja';
      }
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUnread ? const Color(0xFF27AE60).withValues(alpha: 0.3) : Colors.grey.shade200,
          width: isUnread ? 1.5 : 1.0,
        ),
      ),
      color: isUnread ? const Color(0xFF27AE60).withValues(alpha: 0.04) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showFeedbackDetail(feedback),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isUnread 
                        ? const Color(0xFF27AE60).withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
                      style: TextStyle(
                        color: isUnread ? const Color(0xFF135835) : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isUnread ? const Color(0xFF135835) : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUnread)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF27AE60),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Baru',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          farmName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: isUnread ? Colors.black87 : Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    relativeTime,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Row(
                    children: [
                      if (isUnread) ...[
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.check_circle_outline, color: Color(0xFF27AE60), size: 20),
                          tooltip: 'Tandai sudah dibaca',
                          onPressed: () => _markAsRead(feedback['id']),
                        ),
                        const SizedBox(width: 12),
                      ],
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        tooltip: 'Hapus',
                        onPressed: () => _deleteFeedback(feedback['id']),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rate_review_outlined,
                  size: 80,
                  color: Color(0xFF27AE60),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Belum Ada Ulasan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Semua saran, kritik, dan masukan dari petani akan muncul di halaman ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135835),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _fetchFeedbacks,
                icon: const Icon(Icons.refresh),
                label: const Text('Perbarui Data'),
              ),
            ],
          ),
        ),
      ),
    );
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
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomMenusScreen())),
      ),
      SidebarNavItem(
        icon: Icons.rate_review,
        label: 'Saran & Masukan',
        isActive: true,
        onTap: () {},
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
