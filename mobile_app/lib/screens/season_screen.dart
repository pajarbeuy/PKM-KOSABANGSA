import 'package:flutter/material.dart';
import '../models/season.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_theme.dart';
import '../widgets/seasons/season_form_bottom_sheet.dart';

class SeasonScreen extends StatefulWidget {
  const SeasonScreen({super.key});

  @override
  State<SeasonScreen> createState() => _SeasonScreenState();
}

class _SeasonScreenState extends State<SeasonScreen> {
  final _apiService = ApiService();
  List<Season> _seasons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    setState(() => _isLoading = true);
    try {
      final seasons = await _apiService.getSeasons();
      setState(() {
        _seasons = seasons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showSeasonForm({Season? season}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => SeasonFormBottomSheet(
        apiService: _apiService,
        season: season,
        existingSeasons: _seasons,
        onSuccess: (_) {
          _loadSeasons();
          Navigator.pop(modalContext);
        },
      ),
    );
  }

  Future<void> _deleteSeason(Season season) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Musim Tanam'),
        content: Text('Yakin hapus musim tanam "${season.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _apiService.deleteSeason(season.id);
      if (result['success'] == true) {
        _loadSeasons();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Musim tanam berhasil dihapus')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gagal menghapus')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: 'season',
      title: 'Musim Tanam',
      subtitle: 'Kelola musim tanam dan target panen',
      onRefresh: _loadSeasons,
      headerActions: [
        ElevatedButton.icon(
          onPressed: () => _showSeasonForm(),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Tambah Musim', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.green700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _showSeasonForm(),
            backgroundColor: AppTheme.green700,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Tambah Musim',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
          : RefreshIndicator(
              onRefresh: _loadSeasons,
              color: AppTheme.green700,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return _buildDesktopLayout();
                  }
                  return _buildMobileLayout();
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada musim tanam',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text('Mulai dengan menambahkan musim tanam baru.', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    if (_seasons.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _seasons.length,
      itemBuilder: (context, index) {
        final season = _seasons[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        season.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    _buildStatusBadge(season.computedStatus),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.date_range, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${AppFormatters.formatDate(season.startDate)} - ${AppFormatters.formatDate(season.endDate)}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.scale, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Total: ${season.totalPanen.toQuantity("kg")}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.green700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showSeasonForm(season: season),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.blue600),
                    ),
                    TextButton.icon(
                      onPressed: () => _deleteSeason(season),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Hapus'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.red600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    final musimAktif = _seasons.where((s) => s.computedStatus == 'active').length;
    final musimSelesai = _seasons.where((s) => s.computedStatus == 'completed').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_month,
                  label: 'Total Musim Tanam',
                  value: '${_seasons.length}',
                  iconColor: AppTheme.green700,
                  iconBg: AppTheme.green100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.eco_outlined,
                  label: 'Musim Aktif',
                  value: '$musimAktif',
                  iconColor: AppTheme.green700,
                  iconBg: AppTheme.green100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.event_available_outlined,
                  label: 'Musim Selesai',
                  value: '$musimSelesai',
                  iconColor: AppTheme.green700,
                  iconBg: AppTheme.green100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_seasons.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: _buildEmptyState(),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: const Row(
                      children: [
                        _ColHeader(text: 'NO', flex: 1),
                        _ColHeader(text: 'NAMA MUSIM', flex: 3),
                        _ColHeader(text: 'TANGGAL MULAI', flex: 2),
                        _ColHeader(text: 'TANGGAL SELESAI', flex: 2),
                        _ColHeader(text: 'STATUS', flex: 2),
                        _ColHeader(text: 'TOTAL PANEN', flex: 2),
                        _ColHeader(text: 'AKSI', flex: 2),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ...List.generate(_seasons.length, (index) {
                    final season = _seasons[index];
                    final isLast = index == _seasons.length - 1;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  season.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  AppFormatters.formatDate(season.startDate),
                                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  AppFormatters.formatDate(season.endDate),
                                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildStatusBadge(season.computedStatus),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  season.totalPanen.toQuantity('kg'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.green700,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _ActionBtn(
                                      icon: Icons.edit_outlined,
                                      color: AppTheme.blue600,
                                      bgColor: AppTheme.blue100,
                                      tooltip: 'Edit',
                                      onTap: () => _showSeasonForm(season: season),
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionBtn(
                                      icon: Icons.delete_outline,
                                      color: AppTheme.red600,
                                      bgColor: AppTheme.red100,
                                      tooltip: 'Hapus',
                                      onTap: () => _deleteSeason(season),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast) const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      ],
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'active':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        label = 'Aktif';
        break;
      case 'completed':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF1E40AF);
        label = 'Selesai';
        break;
      case 'belum_dimulai':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        label = 'Belum Dimulai';
        break;
      case 'cancelled':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        label = 'Dibatalkan';
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF374151);
        label = status;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ── Reusable helper widgets ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  final int flex;

  const _ColHeader({required this.text, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
