import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/cost.dart';
import '../models/season.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_shell.dart';
import 'add_edit_cost_screen.dart';

class CostsScreen extends StatefulWidget {
  const CostsScreen({super.key});

  @override
  State<CostsScreen> createState() => _CostsScreenState();
}

class _CostsScreenState extends State<CostsScreen> {
  final ApiService _apiService = ApiService();
  List<Cost> _costs = [];
  List<Season> _seasons = [];
  Season? _selectedSeason;
  double _totalCost = 0.0;
  Map<String, double> _costsByCategory = {};
  bool _isLoading = true;

  Future<void> _showCostForm({Cost? cost}) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditCostScreen(
        cost: cost,
        onSaved: _loadData,
      ),
    );

    if (added == true) {
      _loadData();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final seasons = await _apiService.getSeasons();
      final costs = await _apiService.getCosts(seasonId: _selectedSeason?.id);
      
      double sum = 0.0;
      Map<String, double> categories = {
        'seed': 0.0, 
        'fertilizer': 0.0, 
        'pesticide': 0.0, 
        'equipment': 0.0, 
        'transport': 0.0,
        'other': 0.0
      };
      
      for (var c in costs) {
        sum += c.amount;
        final cat = categories.containsKey(c.category.toLowerCase()) ? c.category.toLowerCase() : 'other';
        categories[cat] = (categories[cat] ?? 0.0) + c.amount;
      }

      setState(() {
        _seasons = seasons;
        _costs = costs;
        _totalCost = sum;
        _costsByCategory = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data biaya: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteCost(Cost cost) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Biaya'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan biaya ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final result = await _apiService.deleteCost(cost.id);
      if (result['success'] == true) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Catatan biaya berhasil dihapus'), backgroundColor: Colors.green),
        );
        _loadData();
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal menghapus biaya'), backgroundColor: Colors.red),
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
          currentRoute: 'costs',
          title: 'Biaya Produksi',
          subtitle: 'Catat pengeluaran operasional pertanian',
          onRefresh: _loadData,
          floatingActionButton: isDesktop
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _showCostForm(),
                  backgroundColor: AppTheme.green700,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Tambah Biaya',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.green700,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderRow(isDesktop),
                        const SizedBox(height: 24),
                        _buildSummaryAndBreakdown(isDesktop),
                        const SizedBox(height: 24),
                        if (_costs.isEmpty)
                          _buildEmptyState()
                        else
                          isDesktop ? _buildDesktopTable() : _buildMobileList(),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeaderRow(bool isDesktop) {
    if (!isDesktop) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Season Filter Dropdown mimicking the subtitle area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Season?>(
              value: _selectedSeason,
              hint: const Text('Semua Musim Tanam', style: TextStyle(fontSize: 14)),
              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppTheme.textSecondary),
              items: [
                const DropdownMenuItem<Season?>(value: null, child: Text('Semua Musim Tanam', style: TextStyle(fontSize: 14))),
                ..._seasons.map((s) => DropdownMenuItem<Season?>(value: s, child: Text(s.name, style: const TextStyle(fontSize: 14)))),
              ],
              onChanged: (val) {
                setState(() => _selectedSeason = val);
                _loadData();
              },
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showCostForm(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Tambah Biaya', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.green700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            shadowColor: AppTheme.green700.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryAndBreakdown(bool isDesktop) {
    final summaryCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6), // Light pink background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.attach_money, color: Color(0xFFE11D48), size: 24),
          ),
          const SizedBox(height: 20),
          const Text('Total Biaya', style: TextStyle(color: Color(0xFF9F1239), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(_formatJt(_totalCost), style: const TextStyle(color: Color(0xFF881337), fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(_selectedSeason?.name ?? 'Semua Musim', style: const TextStyle(color: Color(0xFFBE123C), fontSize: 13)),
        ],
      ),
    );

    final breakdownCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Breakdown per Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          _buildProgressBar('Pupuk', 'fertilizer'),
          const SizedBox(height: 16),
          _buildProgressBar('Pestisida', 'pesticide'),
          const SizedBox(height: 16),
          _buildProgressBar('Bibit', 'seed'),
          const SizedBox(height: 16),
          _buildProgressBar('Peralatan', 'equipment'),
          const SizedBox(height: 16),
          _buildProgressBar('Transportasi', 'transport'),
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: summaryCard),
          const SizedBox(width: 24),
          Expanded(flex: 3, child: breakdownCard),
        ],
      );
    }

    return Column(
      children: [
        summaryCard,
        const SizedBox(height: 16),
        breakdownCard,
      ],
    );
  }

  Widget _buildProgressBar(String label, String catKey) {
    final amount = _costsByCategory[catKey] ?? 0.0;
    final percentage = _totalCost > 0 ? (amount / _totalCost) : 0.0;
    final color = getCategoryColor(catKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
            Text('${_formatRp(amount)} (${(percentage * 100).toStringAsFixed(0)}%)', 
                 style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Belum ada catatan biaya', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable() {
    return Container(
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
                _ColHeader(text: 'TANGGAL', flex: 2),
                _ColHeader(text: 'KATEGORI', flex: 2),
                _ColHeader(text: 'DESKRIPSI', flex: 3),
                _ColHeader(text: 'MUSIM', flex: 2),
                _ColHeader(text: 'JUMLAH', flex: 2),
                _ColHeader(text: 'AKSI', flex: 1),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          ...List.generate(_costs.length, (index) {
            final cost = _costs[index];
            final isLast = index == _costs.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // TANGGAL
                      Expanded(
                        flex: 2,
                        child: Text(DateFormat('d MMM yyyy').format(safeParseDate(cost.date)), style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                      ),
                      // KATEGORI
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _CategoryPill(category: cost.category),
                        ),
                      ),
                      // DESKRIPSI
                      Expanded(
                        flex: 3,
                        child: Text(cost.notes.isNotEmpty ? cost.notes : '-', style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      // MUSIM
                      Expanded(
                        flex: 2,
                        child: Text(cost.seasonName, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                      ),
                      // JUMLAH
                      Expanded(
                        flex: 2,
                        child: Text(_formatRp(cost.amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                      ),
                      // AKSI
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ActionBtn(
                              icon: Icons.edit_outlined,
                              color: AppTheme.blue600,
                              bgColor: AppTheme.blue100,
                              tooltip: 'Edit',
                              onTap: () async {
                                await _showCostForm(cost: cost);
                              },
                            ),
                            const SizedBox(width: 8),
                            _ActionBtn(
                              icon: Icons.delete_outline,
                              color: AppTheme.red600,
                              bgColor: AppTheme.red100,
                              tooltip: 'Hapus',
                              onTap: () => _deleteCost(cost),
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
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _costs.length,
      itemBuilder: (context, index) {
        final cost = _costs[index];
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('d MMM yyyy').format(safeParseDate(cost.date)), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary)),
                    _CategoryPill(category: cost.category),
                  ],
                ),
                const SizedBox(height: 10),
                Text(cost.notes.isNotEmpty ? cost.notes : '(Tanpa deskripsi)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(cost.seasonName, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatRp(cost.amount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                    Row(
                      children: [
                        _ActionBtn(
                          icon: Icons.edit_outlined,
                          color: AppTheme.blue600,
                          bgColor: AppTheme.blue100,
                          tooltip: 'Edit',
                          onTap: () => _showCostForm(cost: cost),
                        ),
                        const SizedBox(width: 8),
                        _ActionBtn(
                          icon: Icons.delete_outline,
                          color: AppTheme.red600,
                          bgColor: AppTheme.red100,
                          tooltip: 'Hapus',
                          onTap: () => _deleteCost(cost),
                        ),
                      ],
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

  // ── Formatters & Helpers ───────────────────────────────────────────────────

  String _formatRp(double val) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(val);
  }

  String _formatJt(double value) {
    if (value >= 1000000) {
      final double result = value / 1000000;
      return 'Rp ${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)} jt';
    }
    return _formatRp(value);
  }

  Color getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'seed': return const Color(0xFF166534); // Dark Green
      case 'fertilizer': return const Color(0xFF22C55E); // Green
      case 'pesticide': return const Color(0xFFDC2626); // Red
      case 'equipment': return const Color(0xFF2563EB); // Blue
      case 'transport': return const Color(0xFFD97706); // Brown/Orange
      default: return Colors.grey;
    }
  }

  DateTime safeParseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }
}

// ── Shared Widgets ───────────────────────────────────────────────────────────

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
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String category;

  const _CategoryPill({required this.category});

  String getCategoryLabel(String cat) {
    switch (cat.toLowerCase()) {
      case 'seed': return 'Bibit';
      case 'fertilizer': return 'Pupuk';
      case 'pesticide': return 'Pestisida';
      case 'equipment': return 'Peralatan';
      case 'transport': return 'Transportasi';
      default: return 'Lainnya';
    }
  }

  Color getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'seed': return const Color(0xFF166534); // Dark Green
      case 'fertilizer': return const Color(0xFF22C55E); // Green
      case 'pesticide': return const Color(0xFFDC2626); // Red
      case 'equipment': return const Color(0xFF2563EB); // Blue
      case 'transport': return const Color(0xFFD97706); // Brown/Orange
      default: return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = getCategoryLabel(category);
    final color = getCategoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}
