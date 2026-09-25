import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../models/harvest.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_shell.dart';
import 'add_edit_harvest_screen.dart';

class HarvestScreen extends StatefulWidget {
  const HarvestScreen({super.key});

  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  late ApiService _apiService;
  List<Harvest> _harvests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadHarvests();
  }

  Future<void> _loadHarvests() async {
    setState(() => _isLoading = true);
    try {
      final harvests = await _apiService.getHarvests();
      if (mounted) {
        setState(() {
          _harvests = harvests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: 'harvest',
      title: 'Pencatatan Panen',
      subtitle: 'Pantau hasil panen kelompok tani',
      onRefresh: _loadHarvests,
      headerActions: [
        ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AddEditHarvestScreen(onSaved: _loadHarvests),
            ).then((_) => _loadHarvests());
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Catat Panen', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.green700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: AppTheme.green700,
            foregroundColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddEditHarvestScreen(onSaved: _loadHarvests),
                ),
              ).then((_) => _loadHarvests());
            },
            icon: const Icon(Icons.add),
            label: const Text('Catat Panen',
                style: TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.green700))
          : RefreshIndicator(
              onRefresh: _loadHarvests,
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

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.agriculture, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Tidak ada data panen',
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 18,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Mulai dengan menambahkan data panen baru.',
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  // ── Mobile layout ──────────────────────────────────────────────────────────

  Widget _buildMobileLayout() {
    if (_harvests.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _harvests.length,
      itemBuilder: (context, index) {
        final harvest = _harvests[index];
        final hasNotes = harvest.notes.isNotEmpty;
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
                // Header row: date + blok badge & commodity badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('d MMM yyyy', 'id')
                            .format(_safeParseDate(harvest.harvestDate)),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.textPrimary),
                      ),
                    ),
                    if (harvest.commodityName != null && harvest.commodityName!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: Text(
                          harvest.commodityName!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                    _HarvestBlokBadge(label: harvest.seasonName),
                  ],
                ),
                const SizedBox(height: 10),
                // Weight & unit + foto indicator
                Row(
                  children: [
                    const Icon(Icons.scale_outlined,
                        size: 14, color: AppTheme.green700),
                    const SizedBox(width: 6),
                    Text(
                      harvest.quantity > 0 && harvest.unit != 'kg'
                          ? '${harvest.quantity} ${harvest.unit} (${_formatNumber(harvest.weightKg)} kg)'
                          : '${_formatNumber(harvest.weightKg)} kg',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.green700,
                          fontWeight: FontWeight.w700),
                    ),
                    if (hasNotes) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.image_outlined,
                          size: 14, color: AppTheme.green700),
                      const SizedBox(width: 4),
                      const Text('Ada',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.green700,
                              fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
                if (harvest.hasMarketPriceSnapshot) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.green100.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.green300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.price_change_outlined, size: 14, color: AppTheme.green700),
                            const SizedBox(width: 4),
                            Text(
                              '@ ${_formatCurrency(harvest.marketPriceSnapshot!)}/${harvest.unit}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.green900, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text(
                          'Gross: ${_formatCurrency(harvest.calculatedGrossValue)}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.green900, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
                if (hasNotes) ...[
                  const SizedBox(height: 6),
                  Text(harvest.notes,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ActionBtn(
                      icon: Icons.edit_outlined,
                      color: AppTheme.blue600,
                      bgColor: AppTheme.blue100,
                      tooltip: 'Edit',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddEditHarvestScreen(
                            harvest: harvest,
                            onSaved: _loadHarvests,
                          ),
                        ).then((_) => _loadHarvests());
                      },
                    ),
                    const SizedBox(width: 8),
                    _ActionBtn(
                      icon: Icons.delete_outline,
                      color: AppTheme.red600,
                      bgColor: AppTheme.red100,
                      tooltip: 'Hapus',
                      onTap: () => _showDeleteDialog(context, harvest),
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

  // ── Desktop layout ─────────────────────────────────────────────────────────

  Widget _buildDesktopLayout() {
    final totalCatatan = _harvests.length;
    final totalHasil =
        _harvests.fold<double>(0, (sum, h) => sum + h.weightKg);
    final rataRata = totalCatatan > 0 ? totalHasil / totalCatatan : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Summary Stat Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.list_alt_outlined,
                  label: 'Total Catatan',
                  value: '$totalCatatan entri',
                  iconColor: AppTheme.green700,
                  iconBg: AppTheme.green100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.scale_outlined,
                  label: 'Total Hasil',
                  value: '${_formatNumber(totalHasil)} kg',
                  iconColor: AppTheme.green700,
                  iconBg: AppTheme.green100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.bar_chart_outlined,
                  label: 'Rata-rata',
                  value: '${_formatNumber(rataRata)} kg',
                  iconColor: AppTheme.green700,
                  iconBg: AppTheme.green100,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Table Card
          if (_harvests.isEmpty)
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
                  // Table header
                  Container(
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: const Row(
                      children: [
                        _ColHeader(text: 'TANGGAL', flex: 3),
                        _ColHeader(text: 'HASIL TANI', flex: 3),
                        _ColHeader(text: 'MUSIM TANAM', flex: 2),
                        _ColHeader(text: 'BERAT & NILAI PASAR', flex: 4),
                        _ColHeader(text: 'CATATAN', flex: 3),
                        _ColHeader(text: 'AKSI', flex: 2),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  // Table rows
                  ...List.generate(_harvests.length, (index) {
                    final harvest = _harvests[index];
                    final isLast = index == _harvests.length - 1;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              // TANGGAL
                              Expanded(
                                flex: 3,
                                child: Text(
                                  DateFormat('d MMM yyyy', 'id').format(
                                      _safeParseDate(harvest.harvestDate)),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textPrimary),
                                ),
                              ),
                              // HASIL TANI
                              Expanded(
                                flex: 3,
                                child: Text(
                                  harvest.commodityName ?? '–',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: harvest.commodityName != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: harvest.commodityName != null
                                        ? const Color(0xFF2E7D32)
                                        : Colors.grey[400],
                                  ),
                                ),
                              ),
                              // BLOK (season name as colored badge)
                              Expanded(
                                flex: 2,
                                child:
                                    _HarvestBlokBadge(label: harvest.seasonName),
                              ),
                              // BERAT & NILAI PASAR
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      harvest.quantity > 0 && harvest.unit != 'kg'
                                          ? '${harvest.quantity} ${harvest.unit} (${_formatNumber(harvest.weightKg)} kg)'
                                          : '${_formatNumber(harvest.weightKg)} kg',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.green700),
                                    ),
                                    if (harvest.hasMarketPriceSnapshot) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        '@ ${_formatCurrency(harvest.marketPriceSnapshot!)}/${harvest.unit} (Pasar)',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                      Text(
                                        'Gross: ${_formatCurrency(harvest.calculatedGrossValue)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.green900,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // CATATAN
                              Expanded(
                                flex: 3,
                                child: Text(
                                  harvest.notes.isNotEmpty
                                      ? harvest.notes
                                      : '–',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: harvest.notes.isNotEmpty
                                        ? AppTheme.textSecondary
                                        : Colors.grey[400],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // AKSI
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
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              AddEditHarvestScreen(
                                            harvest: harvest,
                                            onSaved: _loadHarvests,
                                          ),
                                        ).then((_) => _loadHarvests());
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionBtn(
                                      icon: Icons.delete_outline,
                                      color: AppTheme.red600,
                                      bgColor: AppTheme.red100,
                                      tooltip: 'Hapus',
                                      onTap: () =>
                                          _showDeleteDialog(context, harvest),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          const Divider(
                              height: 1, color: Color(0xFFF3F4F6)),
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  DateTime _safeParseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }

  String _formatNumber(double value) {
    if (value == 0) return '0';
    final formatter = NumberFormat('#,##0', 'id');
    return formatter.format(value);
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat('#,##0', 'id');
    return 'Rp ${formatter.format(value)}';
  }

  void _showDeleteDialog(BuildContext context, Harvest harvest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Panen'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus data panen ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              final result = await _apiService.deleteHarvest(harvest.id);
              if (result['success'] == true) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Panen berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadHarvests();
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Gagal menghapus'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Hapus',
                style: TextStyle(color: Colors.red)),
          ),
        ],
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
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1.1)),
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
              color: bgColor, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

/// Colored pill badge for the BLOK column – color cycles by season name hash
class _HarvestBlokBadge extends StatelessWidget {
  final String label;

  const _HarvestBlokBadge({required this.label});

  static const _palettes = [
    [Color(0xFFDCFCE7), Color(0xFF166534)], // green
    [Color(0xFFDBEAFE), Color(0xFF1E40AF)], // blue
    [Color(0xFFFFEDD5), Color(0xFF9A3412)], // orange
    [Color(0xFFEDE9FE), Color(0xFF5B21B6)], // purple
    [Color(0xFFFEE2E2), Color(0xFF991B1B)], // red
  ];

  @override
  Widget build(BuildContext context) {
    final idx = label.hashCode.abs() % _palettes.length;
    final bg = _palettes[idx][0];
    final fg = _palettes[idx][1];
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: fg),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
