import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../models/harvest.dart';
import '../models/economic_result.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_shell.dart';
import '../widgets/convert_harvest_dialog.dart';
import '../widgets/integrated_economic_dialog.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        return AppShell(
          currentRoute: 'harvest',
          title: 'Pencatatan Panen',
          subtitle: 'Pantau hasil panen kelompok tani',
          onRefresh: _loadHarvests,
          headerActions: [
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const IntegratedEconomicDialog(),
                );
              },
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
              label: const Text('Laba/Rugi Terpadu', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.green700,
                side: const BorderSide(color: AppTheme.green700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(width: 8),
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
          floatingActionButton: isDesktop
              ? null
              : FloatingActionButton.extended(
                  backgroundColor: AppTheme.green700,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          AddEditHarvestScreen(onSaved: _loadHarvests),
                    ).then((_) => _loadHarvests());
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Catat Panen',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.green700))
              : RefreshIndicator(
                  onRefresh: _loadHarvests,
                  color: AppTheme.green700,
                  child: isDesktop
                      ? _buildDesktopLayout()
                      : _buildMobileLayout(),
                ),
        );
      },
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
      itemCount: _harvests.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Laba/Rugi Terpadu (Hulu & Hilir)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pantau total panen kebun & margin olahan',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const IntegratedEconomicDialog(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1B5E20),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Buka', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          );
        }

        final harvest = _harvests[index - 1];
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('d MMM yyyy', 'id')
                                .format(_safeParseDate(harvest.harvestDate)),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppTheme.textPrimary),
                          ),
                          if (harvest.commodityName != null && harvest.commodityName!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                      icon: Icons.soup_kitchen_outlined,
                      color: Colors.orange.shade800,
                      bgColor: Colors.orange.shade100,
                      tooltip: 'Alihkan ke Olahan',
                      onTap: () => _showConvertDialog(context, harvest),
                    ),
                    const SizedBox(width: 8),
                    _ActionBtn(
                      icon: Icons.analytics_outlined,
                      color: AppTheme.green700,
                      bgColor: AppTheme.green100,
                      tooltip: 'Hasil Ekonomi',
                      onTap: () => _showEconomicResultModal(context, harvest),
                    ),
                    const SizedBox(width: 8),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth - 56;
        final tableWidth = contentWidth > 950 ? contentWidth : 950.0;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // ── Summary Stat Cards
          constraints.maxWidth < 900
              ? Column(
                  children: [
                    _StatCard(
                      icon: Icons.list_alt_outlined,
                      label: 'Total Catatan',
                      value: '$totalCatatan entri',
                      iconColor: AppTheme.green700,
                      iconBg: AppTheme.green100,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      icon: Icons.scale_outlined,
                      label: 'Total Hasil',
                      value: '${_formatNumber(totalHasil)} kg',
                      iconColor: AppTheme.green700,
                      iconBg: AppTheme.green100,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      icon: Icons.bar_chart_outlined,
                      label: 'Rata-rata',
                      value: '${_formatNumber(rataRata)} kg',
                      iconColor: AppTheme.green700,
                      iconBg: AppTheme.green100,
                    ),
                  ],
                )
              : Row(
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  width: tableWidth,
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
                            _ColHeader(text: 'AKSI', flex: 4),
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
                                flex: 4,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _ActionBtn(
                                          icon: Icons.soup_kitchen_outlined,
                                          color: Colors.orange.shade800,
                                          bgColor: Colors.orange.shade100,
                                          tooltip: 'Alihkan ke Olahan',
                                          onTap: () => _showConvertDialog(context, harvest),
                                        ),
                                        const SizedBox(width: 8),
                                        _ActionBtn(
                                          icon: Icons.analytics_outlined,
                                          color: AppTheme.green700,
                                          bgColor: AppTheme.green100,
                                          tooltip: 'Hasil Ekonomi',
                                          onTap: () => _showEconomicResultModal(context, harvest),
                                        ),
                                        const SizedBox(width: 8),
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
          ),
        ),
      ],
    ),
  );
},
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

  void _showConvertDialog(BuildContext context, Harvest harvest) {
    showDialog(
      context: context,
      builder: (ctx) => ConvertHarvestDialog(
        initialHarvest: harvest,
        onConverted: _loadHarvests,
      ),
    );
  }

  void _showEconomicResultModal(BuildContext context, Harvest harvest) {
    final isDesktop = MediaQuery.of(context).size.width > 700;
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: _EconomicResultSheet(
            harvestId: harvest.id,
            harvestName: harvest.commodityName ?? 'Panen #${harvest.id}',
            isDialog: true,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _EconomicResultSheet(
          harvestId: harvest.id,
          harvestName: harvest.commodityName ?? 'Panen #${harvest.id}',
          isDialog: false,
        ),
      );
    }
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

/// Modal untuk Hasil Ekonomi Panen (Phase 6)
class _EconomicResultSheet extends StatelessWidget {
  final int harvestId;
  final String harvestName;
  final bool isDialog;

  const _EconomicResultSheet({
    required this.harvestId,
    required this.harvestName,
    this.isDialog = false,
  });

  String _formatCurrency(double? val) {
    if (val == null) return '–';
    final fmt = NumberFormat('#,##0', 'id');
    return 'Rp ${fmt.format(val)}';
  }

  String _formatNumber(double? val) {
    if (val == null) return '–';
    final fmt = NumberFormat('#,##0', 'id');
    return fmt.format(val);
  }

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 560,
      ),
      margin: isDialog
          ? EdgeInsets.zero
          : EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: MediaQuery.of(context).size.width > 640 ? (MediaQuery.of(context).size.width - 560) / 2 : 0,
              right: MediaQuery.of(context).size.width > 640 ? (MediaQuery.of(context).size.width - 560) / 2 : 0,
            ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDialog
            ? BorderRadius.circular(20)
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle (bottom sheet only)
          if (!isDialog)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.green100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.analytics_outlined, color: AppTheme.green700, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hasil Ekonomi Panen',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        harvestName,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: FutureBuilder<HarvestEconomicResult?>(
              future: apiService.getHarvestEconomicResult(harvestId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.green700),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.orange, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'Gagal memuat rincian ekonomi panen',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error?.toString() ?? 'Data tidak ditemukan.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                final res = snapshot.data!;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Banner Laba / Rugi
                      if (res.hasEconomicData)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: res.isProfit ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: res.isProfit ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: res.isProfit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  res.isProfit ? Icons.trending_up : Icons.trending_down,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      res.isProfit ? 'PROFIT (LABA BERSIH)' : 'LOSS (RUGI BERSIH)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: res.isProfit ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatCurrency(res.profitLoss),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: res.isProfit ? const Color(0xFF047857) : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Color(0xFFD97706), size: 22),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Harga pasar snapshot = NULL. Maka Revenue = NULL dan Profit/Loss = NULL (tidak dianggap 0).',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Rincian 5 Komponen Phase 6
                      const Text(
                        'Rincian Hasil Ekonomi',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 12),

                      // 1. Hasil Panen
                      _DetailRow(
                        icon: Icons.scale_outlined,
                        label: 'Hasil Panen',
                        value: res.quantity > 0 && res.unit != 'kg'
                            ? '${_formatNumber(res.weightKg)} kg (${_formatNumber(res.quantity)} ${res.unit})'
                            : '${_formatNumber(res.weightKg)} kg',
                        subtitle: 'Bobot dasar kalkulasi: weight_kg',
                        accentColor: AppTheme.green700,
                      ),
                      const SizedBox(height: 8),

                      // 2. Harga Pasar
                      _DetailRow(
                        icon: Icons.storefront_outlined,
                        label: 'Harga Pasar',
                        value: res.marketPriceSnapshot != null
                            ? '${_formatCurrency(res.marketPriceSnapshot)} / kg'
                            : 'NULL',
                        subtitle: res.marketPriceEffectiveDate != null
                            ? 'Snapshot per: ${res.marketPriceEffectiveDate}'
                            : 'Snapshot pasar belum tersedia',
                        accentColor: AppTheme.blue600,
                      ),
                      const SizedBox(height: 8),

                      // 3. Revenue
                      _DetailRow(
                        icon: Icons.payments_outlined,
                        label: 'Revenue',
                        value: res.revenue != null
                            ? _formatCurrency(res.revenue)
                            : 'NULL',
                        subtitle: res.revenue != null
                            ? 'weight_kg (${_formatNumber(res.weightKg)}) × Harga Pasar'
                            : 'NULL (karena Harga Pasar = NULL)',
                        accentColor: const Color(0xFF0D9488),
                      ),
                      const SizedBox(height: 8),

                      // 4. Allocated Production Cost
                      _DetailRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Allocated Production Cost',
                        value: res.allocatedProductionCost != null
                            ? _formatCurrency(res.allocatedProductionCost)
                            : 'Rp 0',
                        subtitle: '(harvest.weight_kg / total_season_weight_kg) × season_total_cost',
                        accentColor: Colors.orange[800]!,
                      ),
                      const SizedBox(height: 8),

                      // 5. Profit/Loss
                      _DetailRow(
                        icon: Icons.calculate_outlined,
                        label: 'Profit/Loss',
                        value: res.profitLoss != null
                            ? _formatCurrency(res.profitLoss)
                            : 'NULL',
                        subtitle: res.profitLoss != null
                            ? 'Revenue - Allocated Production Cost'
                            : 'NULL (karena Revenue = NULL)',
                        accentColor: res.isProfit
                            ? AppTheme.green700
                            : (res.isLoss ? Colors.red[700]! : AppTheme.textSecondary),
                      ),

                      const SizedBox(height: 20),

                      // Info box penjelasan formula
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calculate_outlined, size: 18, color: AppTheme.textSecondary),
                                SizedBox(width: 8),
                                Text(
                                  'Formula Perhitungan Phase 6:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              '• Revenue = weight_kg × Historical Market Price Snapshot\n'
                              '• Allocated Production Cost = (harvest.weight_kg / total_season_weight_kg) × season_total_cost\n'
                              '• Profit/Loss = Revenue - Allocated Production Cost\n'
                              '• Jika market_price_snapshot = NULL: Revenue = NULL & Profit/Loss = NULL (tidak dianggap 0)',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color accentColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

