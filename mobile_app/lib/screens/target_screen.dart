import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/season.dart';
import '../models/harvest.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_theme.dart';
import '../utils/navigation_helper.dart';
import '../login_screen.dart';

class TargetScreen extends StatefulWidget {
  const TargetScreen({super.key});

  @override
  State<TargetScreen> createState() => _TargetScreenState();
}

class _TargetScreenState extends State<TargetScreen> {
  final ApiService _apiService = ApiService();
  List<Season> _seasons = [];
  List<Harvest> _harvests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final seasons = await _apiService.getSeasons();
      final harvests = await _apiService.getHarvests();
      if (mounted) {
        setState(() {
          _seasons = seasons;
          _harvests = harvests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data target: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
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

  void _showEditTargetDialog(Season season) {
    final controller = TextEditingController(text: season.targetKg.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Target Panen (${season.name})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan target produksi baru (kg):', style: AppTheme.bodySmall),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Target (Kg)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.track_changes_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.green700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val == null || val <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nilai target tidak valid')),
                );
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                final res = await _apiService.updateSeason(
                  season.id,
                  name: season.name,
                  startDate: season.startDate,
                  endDate: season.endDate,
                  status: season.status,
                  targetKg: val,
                  notes: season.notes,
                );
                if (res['success'] == true) {
                  _loadData();
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Target panen berhasil diperbarui'), backgroundColor: Colors.green),
                  );
                } else {
                  _loadData();
                }
              } catch (e) {
                _loadData();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  double _getActualForSeason(Season season) {
    double total = 0;
    for (var h in _harvests) {
      if (h.seasonId == season.id) {
        total += h.quantity.toDouble();
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name = user?.name ?? 'Petani';
    final email = user?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: AppTheme.pageBg,
          appBar: isDesktop
              ? null
              : AppMobileAppBar(
                  title: 'Target Panen',
                  userInitials: initials,
                  onNotificationTap: _loadData,
                ),
          drawer: isDesktop
              ? null
              : AppDrawer(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: NavigationHelper.buildNavItems(context, 'target'),
                  secondaryItems: NavigationHelper.buildSecondaryNavItems(context, 'target'),
                ),
          body: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: NavigationHelper.buildNavItems(context, 'target'),
                  secondaryItems: NavigationHelper.buildSecondaryNavItems(context, 'target'),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop)
                      AppHeader(
                        title: 'Target Panen & Realisasi',
                        subtitle: 'Pantau pencapaian target produksi pertanian kentang per musim',
                        userInitials: initials,
                        onRefresh: _loadData,
                      ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              color: AppTheme.green700,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildActiveTargetHero(isDesktop),
                                    const SizedBox(height: 24),
                                    const Text('Daftar Target Musim Tanam', style: AppTheme.h2),
                                    const SizedBox(height: 12),
                                    _seasons.isEmpty
                                        ? _buildEmptyState()
                                        : _buildSeasonsTargetList(isDesktop),
                                  ],
                                ),
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

  Widget _buildActiveTargetHero(bool isDesktop) {
    Season? activeSeason;
    try {
      activeSeason = _seasons.firstWhere((s) => s.status == 'active');
    } catch (_) {
      if (_seasons.isNotEmpty) activeSeason = _seasons.first;
    }

    if (activeSeason == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.card,
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: const Center(
          child: Text('Belum ada musim tanam aktif untuk menampilkan target.', style: AppTheme.bodySmall),
        ),
      );
    }

    final target = activeSeason.targetKg;
    final actual = _getActualForSeason(activeSeason);
    final pct = target > 0 ? (actual / target).clamp(0.0, 1.0) : 0.0;
    final pctString = (pct * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.card,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco_rounded, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Musim Aktif: ${activeSeason.name}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: 'Edit Target Musim Ini',
                onPressed: () => _showEditTargetDialog(activeSeason!),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Realisasi Saat Ini', style: TextStyle(color: Colors.blue.shade100, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatNumber(actual.toInt())} kg',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Target Produksi', style: TextStyle(color: Colors.blue.shade100, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatNumber(target.toInt())} kg',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: pct >= 1.0 ? Colors.greenAccent : Colors.amberAccent,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$pctString% Terpenuhi',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                actual >= target
                    ? '🎉 Target telah tercapai!'
                    : 'Kurang ${_formatNumber((target - actual).toInt())} kg lagi',
                style: TextStyle(
                  color: actual >= target ? Colors.greenAccent : Colors.amberAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.track_changes_outlined, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Belum ada data target musim tanam', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonsTargetList(bool isDesktop) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _seasons.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final season = _seasons[index];
        final target = season.targetKg;
        final actual = _getActualForSeason(season);
        final pct = target > 0 ? (actual / target).clamp(0.0, 1.0) : 0.0;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: AppTheme.card,
            border: Border.all(color: AppTheme.cardBorder),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(season.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 10),
                      _buildStatusBadge(season.status),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                    onPressed: () => _showEditTargetDialog(season),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Target: ${_formatNumber(target.toInt())} kg', style: AppTheme.bodySmall),
                  Text('Realisasi: ${_formatNumber(actual.toInt())} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: AppTheme.cardBorder,
                  color: pct >= 1.0 ? AppTheme.green500 : AppTheme.amber600,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text('${(pct * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: pct >= 1.0 ? AppTheme.green700 : AppTheme.amber600)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;
    if (status == 'active') {
      bg = AppTheme.green100;
      text = AppTheme.green700;
      label = 'Aktif';
    } else if (status == 'completed') {
      bg = AppTheme.blue100;
      text = Colors.blue;
      label = 'Selesai';
    } else {
      bg = Colors.grey.shade200;
      text = Colors.grey.shade700;
      label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  String _formatNumber(int val) {
    return val.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  }
}
