import 'package:flutter/material.dart';
import '../models/farmer_commodity.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_shell.dart';

class FarmerCommodityScreen extends StatefulWidget {
  final bool isEmbedded;
  const FarmerCommodityScreen({super.key, this.isEmbedded = false});

  @override
  State<FarmerCommodityScreen> createState() => _FarmerCommodityScreenState();
}

class _FarmerCommodityScreenState extends State<FarmerCommodityScreen> {
  final ApiService _apiService = ApiService();

  List<FarmerCommodity> _commodities = [];
  List<FarmerCommodity> _filteredCommodities = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'inactive'

  final List<String> _unitOptions = ['kg', 'kuintal', 'ton', 'ikat', 'pcs'];

  @override
  void initState() {
    super.initState();
    _fetchCommodities();
  }

  Future<void> _fetchCommodities() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getFarmerCommodities();
      if (!mounted) return;
      setState(() {
        _commodities = list;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat hasil tani: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredCommodities = _commodities.where((c) {
        final matchesSearch = c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (c.code ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (c.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesStatus = _statusFilter == 'all' ||
            (_statusFilter == 'active' && c.isActive) ||
            (_statusFilter == 'inactive' && !c.isActive);

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _showFormDialog({FarmerCommodity? existing}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String unit = existing?.unit ?? 'kg';
    String status = existing?.status ?? 'active';
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.green100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.grass_rounded, color: AppTheme.green700, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    existing == null ? 'Tambah Hasil Tani' : 'Edit Hasil Tani',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nama Hasil Tani / Komoditas *',
                            hintText: 'Misal: Jeruk Manis, Talas, Kentang Granola',
                            prefixIcon: Icon(Icons.agriculture_rounded, color: AppTheme.green700),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Nama hasil tani wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                initialValue: unit,
                                decoration: const InputDecoration(
                                  labelText: 'Satuan Kuantitas *',
                                  prefixIcon: Icon(Icons.scale_rounded, color: AppTheme.green700),
                                ),
                                items: _unitOptions.map((u) {
                                  return DropdownMenuItem(value: u, child: Text(u));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => unit = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: codeCtrl,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'Kode (Opsional)',
                                  hintText: 'JRK-01',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(
                            labelText: 'Status Komoditas',
                            prefixIcon: Icon(Icons.toggle_on_outlined, color: AppTheme.green700),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'active', child: Text('Aktif')),
                            DropdownMenuItem(value: 'inactive', child: Text('Nonaktif')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => status = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi / Catatan Varietas',
                            hintText: 'Informasi varietas bibit, musim ideal, atau karakteristik tanaman',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(dialogCtx);
                          setDialogState(() => isSubmitting = true);

                          final payload = {
                            'name': nameCtrl.text.trim(),
                            'unit': unit,
                            'code': codeCtrl.text.trim().toUpperCase(),
                            'status': status,
                            'description': descCtrl.text.trim(),
                          };

                          Map<String, dynamic> res;
                          if (existing == null) {
                            res = await _apiService.createFarmerCommodity(payload);
                          } else {
                            res = await _apiService.updateFarmerCommodity(existing.id, payload);
                          }

                          if (!mounted) return;

                          if (res['success'] == true) {
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? 'Berhasil disimpan'),
                                backgroundColor: AppTheme.green700,
                              ),
                            );
                            _fetchCommodities();
                          } else {
                            setDialogState(() => isSubmitting = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? 'Terjadi kesalahan.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(existing == null ? 'Simpan' : 'Perbarui'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(FarmerCommodity item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24),
              SizedBox(width: 10),
              Text('Hapus Hasil Tani', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus komoditas "${item.name}"?\n\nKomoditas yang sudah memiliki data panen tidak dapat dihapus demi integritas pembukuan.',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                navigator.pop();

                final res = await _apiService.deleteFarmerCommodity(item.id);
                if (!mounted) return;

                if (res['success'] == true) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Komoditas berhasil dihapus.'),
                      backgroundColor: AppTheme.green700,
                    ),
                  );
                  _fetchCommodities();
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Gagal menghapus komoditas.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    if (_filteredCommodities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.grass_outlined, size: 54, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Belum ada hasil tani terdaftar',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredCommodities.length,
      itemBuilder: (context, index) {
        final c = _filteredCommodities[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.green100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.grass_rounded, size: 18, color: AppTheme.green700),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (c.code != null && c.code!.isNotEmpty)
                              Text(
                                c.code!,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (c.isActive ? Colors.green : Colors.grey).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        c.isActive ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: c.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (c.description != null && c.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    c.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                  ),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Satuan: ${c.unit}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.blue600),
                          tooltip: 'Edit',
                          onPressed: () => _showFormDialog(existing: c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          tooltip: 'Hapus',
                          onPressed: () => _showDeleteDialog(c),
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

  Widget _buildDesktopLayout() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 48,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 64,
              columns: const [
                DataColumn(label: Text('Nama Hasil Tani', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Kode', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Satuan', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _filteredCommodities.map((c) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.green100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.grass_rounded, size: 16, color: AppTheme.green700),
                          ),
                          const SizedBox(width: 10),
                          Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataCell(Text(c.code ?? '-')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.unit,
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (c.isActive ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          c.isActive ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            color: c.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(c.description ?? '-', overflow: TextOverflow.ellipsis)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.blue600),
                            tooltip: 'Edit',
                            onPressed: () => _showFormDialog(existing: c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                            tooltip: 'Hapus',
                            onPressed: () => _showDeleteDialog(c),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (_filteredCommodities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text('Belum ada komoditas hasil tani ditemukan', style: TextStyle(color: Colors.grey.shade500)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDesktop) {
    return RefreshIndicator(
      onRefresh: _fetchCommodities,
      color: AppTheme.green700,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isDesktop ? AppTheme.pageHPad : 16.0),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Search & Add Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Cari hasil tani (misal: Jeruk, Talas, Pisang)...',
                                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                _searchQuery = val;
                                _applyFilter();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.green700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _showFormDialog(),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Tambah Hasil Tani', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Filter Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(width: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Semua', style: TextStyle(fontSize: 12)),
                                selected: _statusFilter == 'all',
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() => _statusFilter = 'all');
                                    _applyFilter();
                                  }
                                },
                                selectedColor: AppTheme.green100,
                              ),
                              ChoiceChip(
                                label: const Text('Aktif', style: TextStyle(fontSize: 12)),
                                selected: _statusFilter == 'active',
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() => _statusFilter = 'active');
                                    _applyFilter();
                                  }
                                },
                                selectedColor: AppTheme.green100,
                              ),
                              ChoiceChip(
                                label: const Text('Nonaktif', style: TextStyle(fontSize: 12)),
                                selected: _statusFilter == 'inactive',
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() => _statusFilter = 'inactive');
                                    _applyFilter();
                                  }
                                },
                                selectedColor: Colors.grey.shade200,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: AppTheme.green700),
                    ),
                  )
                else
                  isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          return _buildBody(isDesktop);
        },
      );
    }

    return AppShell(
      currentRoute: 'commodities',
      title: 'Hasil Tani',
      subtitle: 'Kelola komoditas dan hasil pertanian Anda',
      onRefresh: _fetchCommodities,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          return _buildBody(isDesktop);
        },
      ),
    );
  }
}
