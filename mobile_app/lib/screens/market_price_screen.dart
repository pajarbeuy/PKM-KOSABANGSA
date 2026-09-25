import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/farmer_commodity.dart';
import '../models/market_price.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_theme.dart';

class MarketPriceScreen extends StatefulWidget {
  final bool isEmbedded;
  const MarketPriceScreen({super.key, this.isEmbedded = false});

  @override
  State<MarketPriceScreen> createState() => _MarketPriceScreenState();
}

class _MarketPriceScreenState extends State<MarketPriceScreen> {
  final ApiService _apiService = ApiService();

  List<MarketPrice> _prices = [];
  List<FarmerCommodity> _commodities = [];
  bool _isLoading = true;
  bool _isIngesting = false;
  int? _selectedCommodityId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final isSuperAdmin = Provider.of<AuthProvider>(context, listen: false).user?.role == 'super_admin';
      final comms = isSuperAdmin
          ? await _apiService.getSuperAdminCommodities(status: 'active')
          : await _apiService.getFarmerCommodities(activeOnly: true);

      final priceRes = await _apiService.getMarketPrices(
        commodityId: _selectedCommodityId,
      );

      if (!mounted) return;
      setState(() {
        _commodities = comms;
        _prices = priceRes['market_prices'] as List<MarketPrice>? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data harga acuan: $e'),
          backgroundColor: AppTheme.red600,
        ),
      );
    }
  }

  Future<void> _triggerIngest() async {
    setState(() => _isIngesting = true);
    try {
      final res = await _apiService.triggerMarketPriceIngest();
      if (!mounted) return;
      setState(() => _isIngesting = false);

      if (res['success'] == true) {
        final stats = res['data'] as Map<String, dynamic>? ?? {};
        final created = stats['created'] ?? 0;
        final updated = stats['updated'] ?? 0;
        final skipped = stats['skipped'] ?? 0;
        final rejected = stats['rejected'] ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sinkronisasi sukses! Baru: $created, Diupdate: $updated, Lewat: $skipped, Ditolak: $rejected',
            ),
            backgroundColor: AppTheme.green700,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal sinkronisasi harga pasar.'),
            backgroundColor: AppTheme.red600,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isIngesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: AppTheme.red600,
        ),
      );
    }
  }

  List<MarketPrice> get _filteredPrices {
    if (_searchQuery.isEmpty) return _prices;
    final q = _searchQuery.toLowerCase();
    return _prices.where((p) {
      return p.commodityName.toLowerCase().contains(q) ||
          p.effectiveDate.contains(q) ||
          p.source.toLowerCase().contains(q) ||
          p.notes.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = context.watch<AuthProvider>().user?.role == 'super_admin';

    final content = Scaffold(
      backgroundColor: AppTheme.pageBg,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.green700,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isSuperAdmin),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 20),
              _buildFilterBar(),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.green700),
                  ),
                )
              else if (_filteredPrices.isEmpty)
                _buildEmptyState()
              else
                _buildPriceList(isSuperAdmin),
            ],
          ),
        ),
      ),
      floatingActionButton: isSuperAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditPriceDialog(null),
              backgroundColor: AppTheme.green700,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Tambah Acuan',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );

    return widget.isEmbedded
        ? content
        : AppShell(
            currentRoute: 'market_prices',
            title: 'Harga Acuan Pasar',
            subtitle: 'Pantauan acuan harga komoditas',
            child: content,
          );
  }

  Widget _buildHeader(bool isSuperAdmin) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppTheme.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Harga Acuan Pasar',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isSuperAdmin
                            ? 'Kelola master harga acuan komoditas (Super Admin)'
                            : 'Pantauan harga acuan untuk estimasi nilai panen',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isSuperAdmin)
                ElevatedButton.icon(
                  onPressed: _isIngesting ? null : _triggerIngest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.green900,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: _isIngesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync, size: 18),
                  label: Text(_isIngesting ? 'Sinkron...' : 'Sync Provider'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white70, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Harga acuan otomatis mengunci nilai saat panen dicatat (Snapshot permanen). Perubahan master harga di kemudian hari tidak mengubah histori panen lama.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final distinctCommodities = _prices.map((p) => p.commodityId).toSet().length;
    final referencedCount = _prices.where((p) => p.isReferenced).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Komoditas Terpantau',
            '$distinctCommodities Komoditas',
            Icons.eco,
            AppTheme.green700,
            AppTheme.green100,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            'Terkunci Panen',
            '$referencedCount Record',
            Icons.lock_clock,
            AppTheme.amber600,
            AppTheme.amber100,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            'Total Acuan Efektif',
            '${_prices.length} Record',
            Icons.analytics_outlined,
            AppTheme.blue600,
            AppTheme.blue100,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.caption),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari komoditas atau tanggal...',
                hintStyle: AppTheme.caption,
                prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(width: 14),
          DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.cardBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<int?>(
                value: _selectedCommodityId,
                hint: const Text('Semua Komoditas', style: TextStyle(fontSize: 13)),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Semua Komoditas', style: TextStyle(fontSize: 13)),
                  ),
                  ..._commodities.map((c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name, style: const TextStyle(fontSize: 13)),
                      )),
                ],
                onChanged: (val) {
                  setState(() => _selectedCommodityId = val);
                  _loadData();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.pageBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 36, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada data harga pasar acuan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Data harga acuan digunakan sebagai rujukan snapshot saat pencatatan panen dilakukan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceList(bool isSuperAdmin) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredPrices.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final price = _filteredPrices[index];
        return _buildPriceCard(price, isSuperAdmin);
      },
    );
  }

  Widget _buildPriceCard(MarketPrice price, bool isSuperAdmin) {
    final rawNumber = price.price.toStringAsFixed(0);
    final formattedNumber = rawNumber.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    final formattedPrice = 'Rp $formattedNumber';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.green100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.price_check, color: AppTheme.green700, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price.commodityName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '$formattedPrice / ${price.unit}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.green700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.pageBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Efektif: ${price.effectiveDate}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.blue100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Sumber: ${price.source}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.blue600, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (price.isReferenced)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.amber100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock, size: 12, color: AppTheme.amber600),
                            SizedBox(width: 4),
                            Text(
                              'Terkunci Panen',
                              style: TextStyle(fontSize: 11, color: AppTheme.amber600, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (price.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    price.notes,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          if (isSuperAdmin) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.textMuted),
              onSelected: (val) {
                if (val == 'edit') {
                  _showAddEditPriceDialog(price);
                } else if (val == 'delete') {
                  _confirmDelete(price);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: AppTheme.textSecondary),
                      SizedBox(width: 8),
                      Text('Ubah', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                if (!price.isReferenced)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: AppTheme.red600),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(fontSize: 13, color: AppTheme.red600)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAddEditPriceDialog(MarketPrice? existing) {
    if (_commodities.isEmpty && existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada data komoditas yang terdaftar. Tambahkan komoditas terlebih dahulu.'),
          backgroundColor: AppTheme.amber600,
        ),
      );
      return;
    }

    int? selectedCommId = existing?.commodityId ?? (_commodities.isNotEmpty ? _commodities.first.id : null);
    final priceCtrl = TextEditingController(text: existing != null ? existing.price.toStringAsFixed(0) : '');
    final dateCtrl = TextEditingController(text: existing?.effectiveDate ?? DateTime.now().toIso8601String().split('T')[0]);
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final sourceCtrl = TextEditingController(text: existing?.source ?? 'manual');
    final isLocked = existing?.isReferenced == true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Tambah Harga Acuan' : 'Ubah Harga Acuan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLocked) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.amber100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppTheme.amber600, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Record ini telah menjadi rujukan panen. Nilai harga & tanggal tidak dapat diubah.',
                                style: TextStyle(fontSize: 11, color: AppTheme.amber600, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Text('Komoditas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: selectedCommId,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      items: _commodities
                          .map((c) {
                            final farmerLabel = c.farmer?['name'] != null ? ' (${c.farmer!['name']})' : '';
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text('${c.name}$farmerLabel - ${c.unit}'),
                            );
                          })
                          .toList(),
                      onChanged: isLocked ? null : (val) => setDialogState(() => selectedCommId = val),
                    ),
                const SizedBox(height: 12),
                const Text('Harga per Satuan (Rp/kg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  enabled: !isLocked,
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Tanggal Efektif Berlaku', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: dateCtrl,
                  enabled: !isLocked,
                  decoration: const InputDecoration(
                    hintText: 'YYYY-MM-DD',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Sumber Acuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: sourceCtrl,
                  decoration: const InputDecoration(
                    hintText: 'manual / pasar_lokal / mock_feed',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Catatan Tambahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green700),
              onPressed: () async {
                final price = double.tryParse(priceCtrl.text) ?? 0.0;
                if (selectedCommId == null || (price <= 0 && !isLocked)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Komoditas dan harga valid wajib diisi!')),
                  );
                  return;
                }

                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                final payload = <String, dynamic>{
                  'notes': notesCtrl.text,
                  'source': sourceCtrl.text,
                };
                if (!isLocked) {
                  payload['commodity_id'] = selectedCommId;
                  payload['price'] = price;
                  payload['effective_date'] = dateCtrl.text;
                }

                Map<String, dynamic> result;
                if (existing == null) {
                  result = await _apiService.createMarketPrice(payload);
                } else {
                  result = await _apiService.updateMarketPrice(existing.id, payload);
                }

                if (!mounted) return;
                setState(() => _isLoading = false);

                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Berhasil menyimpan harga acuan.'),
                      backgroundColor: AppTheme.green700,
                    ),
                  );
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Gagal menyimpan harga acuan.'),
                      backgroundColor: AppTheme.red600,
                    ),
                  );
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  },
);
}

  void _confirmDelete(MarketPrice price) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Harga Acuan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus harga acuan ${price.commodityName} tanggal ${price.effectiveDate}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red600),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              final res = await _apiService.deleteMarketPrice(price.id);
              if (!mounted) return;
              setState(() => _isLoading = false);

              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Harga acuan berhasil dihapus.'),
                    backgroundColor: AppTheme.green700,
                  ),
                );
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Gagal menghapus harga acuan.'),
                    backgroundColor: AppTheme.red600,
                  ),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
