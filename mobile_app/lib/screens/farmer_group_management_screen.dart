import 'package:flutter/material.dart';
import '../models/farmer_group.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';

class FarmerGroupManagementScreen extends StatefulWidget {
  final bool isEmbedded;
  const FarmerGroupManagementScreen({super.key, this.isEmbedded = false});

  @override
  State<FarmerGroupManagementScreen> createState() => _FarmerGroupManagementScreenState();
}

class _FarmerGroupManagementScreenState extends State<FarmerGroupManagementScreen> {
  final ApiService _apiService = ApiService();

  List<FarmerGroup> _groups = [];
  List<FarmerGroup> _filteredGroups = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'inactive'

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getSuperAdminFarmerGroups();
      setState(() {
        _groups = list;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat Kelompok Tani: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredGroups = _groups.where((g) {
        final matchesSearch = g.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            g.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (g.village ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (g.leaderName ?? '').toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesStatus = _statusFilter == 'all' ||
            (_statusFilter == 'active' && g.isActive) ||
            (_statusFilter == 'inactive' && !g.isActive);

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  int get _totalMembers => _groups.fold(0, (acc, g) => acc + g.membersCount);
  int get _activeGroupsCount => _groups.where((g) => g.isActive).length;

  void _showFormDialog({FarmerGroup? existingGroup}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existingGroup?.name ?? '');
    final codeCtrl = TextEditingController(text: existingGroup?.code ?? '');
    final villageCtrl = TextEditingController(text: existingGroup?.village ?? '');
    final leaderCtrl = TextEditingController(text: existingGroup?.leaderName ?? '');
    final descCtrl = TextEditingController(text: existingGroup?.description ?? '');
    String status = existingGroup?.status ?? 'active';
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
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
                    child: const Icon(Icons.groups_rounded, color: AppTheme.green700, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    existingGroup == null ? 'Tambah Kelompok Tani' : 'Edit Kelompok Tani',
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
                            labelText: 'Nama Kelompok Tani *',
                            hintText: 'Misal: Poktan Sumber Makmur',
                            prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.green700),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Nama Kelompok Tani wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Kode Kelompok Tani *',
                            hintText: 'Misal: POKTAN-01',
                            prefixIcon: Icon(Icons.tag_rounded, color: AppTheme.green700),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Kode Kelompok Tani wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: villageCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Wilayah / Desa',
                            hintText: 'Misal: Desa Pasirhuni, Kec. Cimaung',
                            prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.green700),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: leaderCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nama Ketua Poktan',
                            hintText: 'Misal: Bapak H. Suryadi',
                            prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.green700),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(
                            labelText: 'Status Operasional',
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
                            labelText: 'Deskripsi / Fokus Komoditas',
                            hintText: 'Keterangan fokus budidaya atau diversifikasi olahan',
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

                          setDialogState(() => isSubmitting = true);

                          final payload = {
                            'name': nameCtrl.text.trim(),
                            'code': codeCtrl.text.trim().toUpperCase(),
                            'village': villageCtrl.text.trim(),
                            'leader_name': leaderCtrl.text.trim(),
                            'status': status,
                            'description': descCtrl.text.trim(),
                          };

                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(dialogCtx);

                          Map<String, dynamic> res;
                          if (existingGroup == null) {
                            res = await _apiService.createFarmerGroup(payload);
                          } else {
                            res = await _apiService.updateFarmerGroup(existingGroup.id, payload);
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
                            _fetchGroups();
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
                      : Text(existingGroup == null ? 'Simpan' : 'Perbarui'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(FarmerGroup group) {
    final hasMembers = group.membersCount > 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                hasMembers ? Icons.warning_amber_rounded : Icons.delete_outline_rounded,
                color: hasMembers ? Colors.amber.shade800 : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                hasMembers ? 'Tidak Dapat Menghapus' : 'Hapus Kelompok Tani',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: hasMembers
              ? Text(
                  'Kelompok Tani "${group.name}" masih memiliki ${group.membersCount} petani terdaftar sebagai anggota.\n\nDemi integritas data, Anda harus memindahkan seluruh anggota ke Poktan lain terlebih dahulu sebelum kelompok tani ini dapat dihapus.',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                )
              : Text(
                  'Apakah Anda yakin ingin menghapus Kelompok Tani "${group.name}" (${group.code})?\n\nTindakan ini tidak dapat dibatalkan.',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(hasMembers ? 'Mengerti' : 'Batal', style: const TextStyle(color: Colors.grey)),
            ),
            if (!hasMembers)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final res = await _apiService.deleteFarmerGroup(group.id);
                  if (!mounted) return;
                  if (res['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res['message'] ?? 'Kelompok Tani berhasil dihapus'),
                        backgroundColor: AppTheme.green700,
                      ),
                    );
                    _fetchGroups();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res['message'] ?? 'Gagal menghapus Kelompok Tani'),
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

  void _showMembersDialog(FarmerGroup group) async {
    showDialog(
      context: context,
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: _apiService.getFarmerGroupDetail(group.id),
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            final data = snapshot.data;
            final List<dynamic> members = data?['members'] ?? [];

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
                    child: const Icon(Icons.people_alt_rounded, color: AppTheme.green700, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${group.code} • ${members.length} Petani Terdaftar',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                height: 380,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                    : members.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_off_rounded, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada petani terdaftar pada Poktan ini.',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: members.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (c, idx) {
                              final m = members[idx];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.green100,
                                  child: Text(
                                    (m['name'] ?? 'P')[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.green700,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  m['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${m['email'] ?? '-'} • ${m['phone'] ?? '-'}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    if (m['farm_name'] != null)
                                      Text(
                                        'Lahan: ${m['farm_name']}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF1A7A4A), fontWeight: FontWeight.w500),
                                      ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (m['status'] == 'active' ? Colors.green : Colors.amber).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    m['status'] == 'active' ? 'Aktif' : 'Menunggu',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: m['status'] == 'active' ? Colors.green.shade800 : Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup', style: TextStyle(color: AppTheme.green700, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.dark900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    if (_filteredGroups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 54, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Tidak ada data Kelompok Tani ditemukan',
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
      itemCount: _filteredGroups.length,
      itemBuilder: (context, index) {
        final g = _filteredGroups[index];
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.green100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        g.code,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.green700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (g.isActive ? Colors.green : Colors.grey).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        g.isActive ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: g.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  g.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dark900),
                ),
                if (g.description != null && g.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    g.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        g.village ?? 'Wilayah belum diisi',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        g.leaderName != null && g.leaderName!.isNotEmpty ? 'Ketua: ${g.leaderName}' : 'Ketua: Belum ditentukan',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _showMembersDialog(g),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF1A7A4A)),
                            const SizedBox(width: 6),
                            Text(
                              '${g.membersCount} Anggota',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A7A4A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF1A7A4A)),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.blue600),
                          tooltip: 'Edit Poktan',
                          onPressed: () => _showFormDialog(existingGroup: g),
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          tooltip: 'Hapus Poktan',
                          onPressed: () => _showDeleteDialog(g),
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
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
                DataColumn(label: Text('Kode', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Nama Kelompok Tani', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Wilayah / Desa', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Ketua Poktan', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Anggota', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _filteredGroups.map((g) {
                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.green100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          g.code,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.green700),
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (g.description != null && g.description!.isNotEmpty)
                            Text(
                              g.description!,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    DataCell(Text(g.village ?? '-')),
                    DataCell(Text(g.leaderName ?? '-')),
                    DataCell(
                      InkWell(
                        onTap: () => _showMembersDialog(g),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A7A4A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF1A7A4A)),
                              const SizedBox(width: 4),
                              Text(
                                '${g.membersCount} Petani',
                                style: const TextStyle(
                                  color: Color(0xFF1A7A4A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (g.isActive ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          g.isActive ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            color: g.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF1A7A4A)),
                            tooltip: 'Lihat Anggota',
                            onPressed: () => _showMembersDialog(g),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.blue600),
                            tooltip: 'Edit Poktan',
                            onPressed: () => _showFormDialog(existingGroup: g),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                            tooltip: 'Hapus Poktan',
                            onPressed: () => _showDeleteDialog(g),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (_filteredGroups.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text('Tidak ada data Kelompok Tani ditemukan', style: TextStyle(color: Colors.grey.shade500)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return RefreshIndicator(
          onRefresh: _fetchGroups,
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
                    // Statistics Banner
                    Row(
                      children: [
                        _buildStatCard(
                          title: 'Total Poktan',
                          value: '${_groups.length}',
                          icon: Icons.groups_rounded,
                          color: AppTheme.green700,
                          bg: AppTheme.green100,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          title: 'Poktan Aktif',
                          value: '$_activeGroupsCount',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppTheme.blue600,
                          bg: AppTheme.blue100,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          title: 'Total Petani',
                          value: '$_totalMembers',
                          icon: Icons.person_outline_rounded,
                          color: Colors.purple,
                          bg: AppTheme.purple100,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Actions & Filter Bar
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
                                    hintText: 'Cari nama, kode (POKTAN-01), wilayah, atau nama ketua...',
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
                                label: const Text('Tambah Poktan', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _statusFilter = 'all');
                                        _applyFilter();
                                      }
                                    },
                                    selectedColor: AppTheme.green100,
                                    labelStyle: TextStyle(
                                      color: _statusFilter == 'all' ? AppTheme.green700 : Colors.black87,
                                      fontWeight: _statusFilter == 'all' ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Aktif', style: TextStyle(fontSize: 12)),
                                    selected: _statusFilter == 'active',
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _statusFilter = 'active');
                                        _applyFilter();
                                      }
                                    },
                                    selectedColor: AppTheme.green100,
                                    labelStyle: TextStyle(
                                      color: _statusFilter == 'active' ? AppTheme.green700 : Colors.black87,
                                      fontWeight: _statusFilter == 'active' ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Nonaktif', style: TextStyle(fontSize: 12)),
                                    selected: _statusFilter == 'inactive',
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _statusFilter = 'inactive');
                                        _applyFilter();
                                      }
                                    },
                                    selectedColor: Colors.grey.shade200,
                                    labelStyle: TextStyle(
                                      color: _statusFilter == 'inactive' ? Colors.black : Colors.black87,
                                      fontWeight: _statusFilter == 'inactive' ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Main Content (Mobile / Desktop)
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
      },
    );
  }
}
