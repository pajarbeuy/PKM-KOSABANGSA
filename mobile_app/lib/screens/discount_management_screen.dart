import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/processed_product.dart';
import '../models/processed_product_discount.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';

class DiscountManagementScreen extends StatefulWidget {
  final bool isEmbedded;
  const DiscountManagementScreen({super.key, this.isEmbedded = false});

  @override
  State<DiscountManagementScreen> createState() => _DiscountManagementScreenState();
}

class _DiscountManagementScreenState extends State<DiscountManagementScreen> {
  final ApiService _apiService = ApiService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  List<ProcessedProductDiscount> _discounts = [];
  List<ProcessedProduct> _products = [];
  bool _isLoading = true;
  String _statusFilter = 'all'; // all, active, upcoming, expired
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getSuperAdminDiscounts(
        status: _statusFilter == 'all' ? null : _statusFilter,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      final prods = await _apiService.getSuperAdminProcessedProducts();

      if (!mounted) return;
      setState(() {
        _discounts = (res['discounts'] as List<ProcessedProductDiscount>?) ?? [];
        _products = prods;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data diskon: $e'),
          backgroundColor: AppTheme.red600,
        ),
      );
    }
  }

  void _showDiscountFormDialog([ProcessedProductDiscount? discount]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DiscountFormDialog(
        discount: discount,
        products: _products,
        currencyFormat: _currencyFormat,
        onSaved: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  Future<void> _deleteDiscount(ProcessedProductDiscount discount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Diskon', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus diskon ${discount.discountPercentage.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}% untuk "${discount.productName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await _apiService.deleteDiscount(discount.id);
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Diskon berhasil dihapus'),
            backgroundColor: AppTheme.green700,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal menghapus diskon'),
            backgroundColor: AppTheme.red600,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: AppTheme.red600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        return RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.green700,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDesktop),
                const SizedBox(height: 16),
                _buildFilterBar(isDesktop),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.green700),
                    ),
                  )
                else if (_discounts.isEmpty)
                  _buildEmptyState()
                else if (isDesktop || isTablet)
                  _buildDiscountTable(isDesktop)
                else
                  _buildDiscountCards(),
              ],
            ),
          ),
        );
      },
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        title: const Text('Manajemen Diskon Produk Olahan'),
        backgroundColor: AppTheme.green800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDiscountFormDialog(),
        backgroundColor: AppTheme.green700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Diskon'),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppTheme.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_offer_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Diskon Produk Olahan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelola promosi diskon produk olahan dengan persentase fleksibel (misal 5%, 7.5%, 12.5%, 25%). Harga asli tetap utuh sebagai single source of truth.',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showDiscountFormDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.green800,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Buat Diskon Baru',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildFilterChip('all', 'Semua Status'),
              _buildFilterChip('active', 'Aktif'),
              _buildFilterChip('upcoming', 'Akan Datang'),
              _buildFilterChip('expired', 'Berakhir'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari berdasarkan nama produk...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadData();
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.green700, width: 1.5),
                    ),
                  ),
                  onSubmitted: (val) {
                    setState(() => _searchQuery = val.trim());
                    _loadData();
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() => _searchQuery = _searchController.text.trim());
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.green700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cari'),
              ),
              if (!isDesktop) ...[
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _showDiscountFormDialog(),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.green700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _statusFilter = value);
          _loadData();
        }
      },
      selectedColor: AppTheme.green700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(
        color: isSelected ? AppTheme.green700 : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Belum ada data diskon',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Klik tombol "Buat Diskon Baru" untuk mengatur promosi harga produk olahan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showDiscountFormDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Buat Diskon Pertama'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.green700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountTable(bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 860),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
              dataRowMaxHeight: 70,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('Produk', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Harga Normal', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Diskon', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Harga Efektif', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Periode Berlaku', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _discounts.map((d) {
                return DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          d.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _currencyFormat.format(d.originalPrice),
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.red100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${d.discountPercentage.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}% OFF',
                          style: const TextStyle(
                            color: AppTheme.red600,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _currencyFormat.format(d.effectivePrice),
                        style: const TextStyle(
                          color: AppTheme.green700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${d.startDate} s/d ${d.endDate}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(_buildStatusBadge(d)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.blue600),
                            tooltip: 'Ubah Diskon',
                            onPressed: () => _showDiscountFormDialog(d),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.red600),
                            tooltip: 'Hapus Diskon',
                            onPressed: () => _deleteDiscount(d),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountCards() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _discounts.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final d = _discounts[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      d.productName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(d),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.red100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${d.discountPercentage.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}%',
                      style: const TextStyle(
                        color: AppTheme.red600,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _currencyFormat.format(d.originalPrice),
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    _currencyFormat.format(d.effectivePrice),
                    style: const TextStyle(
                      color: AppTheme.green700,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${d.startDate} - ${d.endDate}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.blue600),
                        onPressed: () => _showDiscountFormDialog(d),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.red600),
                        onPressed: () => _deleteDiscount(d),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ProcessedProductDiscount d) {
    Color bg;
    Color text;
    String label = d.statusLabel;

    if (d.isActive) {
      bg = AppTheme.green100;
      text = AppTheme.green800;
    } else if (d.isUpcoming) {
      bg = AppTheme.amber100;
      text = AppTheme.amber600;
    } else {
      bg = Colors.grey.shade200;
      text = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DiscountFormDialog extends StatefulWidget {
  final ProcessedProductDiscount? discount;
  final List<ProcessedProduct> products;
  final NumberFormat currencyFormat;
  final VoidCallback onSaved;

  const _DiscountFormDialog({
    this.discount,
    required this.products,
    required this.currencyFormat,
    required this.onSaved,
  });

  @override
  State<_DiscountFormDialog> createState() => _DiscountFormDialogState();
}

class _DiscountFormDialogState extends State<_DiscountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late int? _selectedProductId;
  late TextEditingController _percentageController;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final d = widget.discount;
    _selectedProductId = d?.processedProductId ?? (widget.products.isNotEmpty ? widget.products.first.id : null);
    _percentageController = TextEditingController(
      text: d != null ? d.discountPercentage.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '') : '10',
    );

    if (d != null) {
      _startDate = DateTime.tryParse(d.startDate) ?? DateTime.now();
      _endDate = DateTime.tryParse(d.endDate) ?? DateTime.now().add(const Duration(days: 7));
    } else {
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 7));
    }
  }

  @override
  void dispose() {
    _percentageController.dispose();
    super.dispose();
  }

  ProcessedProduct? get _selectedProduct {
    try {
      return widget.products.firstWhere((p) => p.id == _selectedProductId);
    } catch (_) {
      return null;
    }
  }

  double get _currentPercentage {
    return double.tryParse(_percentageController.text.trim()) ?? 0.0;
  }

  double get _effectivePrice {
    final p = _selectedProduct;
    if (p == null) return 0.0;
    final pct = _currentPercentage;
    final disc = p.price * (pct / 100);
    return (p.price - disc).clamp(0.0, double.infinity);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.green700,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      setState(() => _errorMessage = 'Pilih produk olahan terlebih dahulu');
      return;
    }

    final pct = double.tryParse(_percentageController.text.trim());
    if (pct == null || pct <= 0 || pct > 100) {
      setState(() => _errorMessage = 'Persentase diskon harus di antara > 0% dan <= 100%');
      return;
    }

    if (_startDate.isAfter(_endDate)) {
      setState(() => _errorMessage = 'Tanggal mulai tidak boleh melebihi tanggal selesai');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate);

    try {
      Map<String, dynamic> res;
      if (widget.discount == null) {
        res = await _apiService.createDiscount(
          processedProductId: _selectedProductId!,
          discountPercentage: pct,
          startDate: startStr,
          endDate: endStr,
        );
      } else {
        res = await _apiService.updateDiscount(
          id: widget.discount!.id,
          processedProductId: _selectedProductId!,
          discountPercentage: pct,
          startDate: startStr,
          endDate: endStr,
        );
      }

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Diskon berhasil disimpan'),
            backgroundColor: AppTheme.green700,
          ),
        );
        widget.onSaved();
      } else {
        String errorMsg = res['message'] ?? 'Gagal menyimpan diskon';
        if (res['errors'] != null && res['errors'] is Map) {
          final errMap = res['errors'] as Map;
          if (errMap.isNotEmpty) {
            final firstVal = errMap.values.first;
            if (firstVal is List && firstVal.isNotEmpty) {
              errorMsg = '$errorMsg: ${firstVal.first}';
            } else if (firstVal != null) {
              errorMsg = '$errorMsg: $firstVal';
            }
          }
        }
        setState(() {
          _isSaving = false;
          _errorMessage = errorMsg;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy', 'id');
    final isEditing = widget.discount != null;
    final prod = _selectedProduct;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Ubah Diskon Produk' : 'Buat Diskon Produk Baru',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.red100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.red600.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.red600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.red600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Product Selection
                const Text(
                  'Produk Olahan *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: _selectedProductId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: widget.products.map((p) {
                    return DropdownMenuItem<int>(
                      value: p.id,
                      child: Text(
                        '${p.name} (${widget.currencyFormat.format(p.price)})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedProductId = val);
                  },
                ),
                const SizedBox(height: 16),
                // Discount Percentage
                const Text(
                  'Persentase Diskon (%) *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _percentageController,
                  keyboardType: const TextInputPrefilledDoubleOrNumber(),
                  decoration: InputDecoration(
                    hintText: 'Misal: 5, 7.5, 12.5, 25',
                    suffixText: '%',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (val) {
                    final d = double.tryParse(val?.trim() ?? '');
                    if (d == null) return 'Masukkan angka yang valid';
                    if (d <= 0) return 'Diskon harus > 0%';
                    if (d > 100) return 'Diskon tidak boleh melebihi 100%';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                // Preset chips
                Wrap(
                  spacing: 6,
                  children: [5.0, 7.5, 10.0, 12.5, 20.0, 25.0].map((preset) {
                    final label = '${preset.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}%';
                    return ActionChip(
                      label: Text(label, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      onPressed: () {
                        setState(() {
                          _percentageController.text = preset.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Date Range
                const Text(
                  'Periode Berlaku *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 20, color: AppTheme.green700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${dateFormat.format(_startDate)}  —  ${dateFormat.format(_endDate)}',
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.edit_calendar_rounded, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Effective Price Calculation Preview
                if (prod != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Simulasi Perhitungan Harga:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Harga Asli:', style: TextStyle(fontSize: 13)),
                            Text(widget.currencyFormat.format(prod.price), style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Potongan (${_currentPercentage.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}%):',
                              style: const TextStyle(fontSize: 13, color: AppTheme.red600),
                            ),
                            Text(
                              '- ${widget.currencyFormat.format(prod.price * (_currentPercentage / 100))}',
                              style: const TextStyle(fontSize: 13, color: AppTheme.red600),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Harga Efektif:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              widget.currencyFormat.format(_effectivePrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.green700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                // Submit Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Simpan Perubahan' : 'Terapkan Diskon'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TextInputPrefilledDoubleOrNumber extends TextInputType {
  const TextInputPrefilledDoubleOrNumber() : super.numberWithOptions(decimal: true);
}
