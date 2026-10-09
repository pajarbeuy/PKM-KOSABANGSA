import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';

class PasswordResetManagementScreen extends StatefulWidget {
  final bool isEmbedded;

  const PasswordResetManagementScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<PasswordResetManagementScreen> createState() =>
      _PasswordResetManagementScreenState();
}

class _PasswordResetManagementScreenState
    extends State<PasswordResetManagementScreen> {
  final ApiService _apiService = ApiService();

  List<dynamic> _requests = [];
  bool _isLoading = true;
  String _selectedStatus = 'all'; // all, pending, approved, completed, rejected
  final TextEditingController _searchController = TextEditingController();

  // Active generated token banner/modal tracking
  final Map<int, Map<String, dynamic>> _activeTokens = {};

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getPasswordResetRequests(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        search: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _requests = res['data'] is List ? res['data'] : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackbar('Gagal memuat daftar permintaan: $e', isError: true);
      }
    }
  }

  Future<void> _handleApprove(int id, String requesterName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.green700),
            SizedBox(width: 8),
            Text('Setujui Permintaan'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menyetujui permintaan pemulihan password untuk "$requesterName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.green700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final res = await _apiService.approvePasswordResetRequest(id);
    if (!mounted) return;

    if (res['success'] == true) {
      _showSnackbar('Permintaan berhasil disetujui.');
      await _fetchRequests();

      // Offer prompt to immediately generate token
      if (mounted) {
        _promptGenerateTokenAfterApprove(id, requesterName);
      }
    } else {
      setState(() => _isLoading = false);
      _showSnackbar(res['message'] ?? 'Gagal menyetujui permintaan.', isError: true);
    }
  }

  Future<void> _promptGenerateTokenAfterApprove(int id, String requesterName) async {
    final generateNow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Buat Token 5 Menit Sekarang?'),
        content: Text(
          'Permintaan untuk "$requesterName" telah disetujui. Apakah Anda ingin langsung membuat token reset 5 menit sekarang untuk dibagikan ke petani?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dark900,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buat Token'),
          ),
        ],
      ),
    );

    if (generateNow == true) {
      _handleGenerateToken(id, requesterName);
    }
  }

  Future<void> _handleReject(int id, String requesterName) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Tolak Permintaan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tolak permohonan reset password untuk "$requesterName"?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Alasan Penolakan (Opsional)',
                hintText: 'Misal: Data kelompok tani tidak cocok',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final res = await _apiService.rejectPasswordResetRequest(
      id,
      reason: reasonController.text.trim(),
    );
    if (!mounted) return;

    if (res['success'] == true) {
      _showSnackbar('Permintaan berhasil ditolak.');
      await _fetchRequests();
    } else {
      setState(() => _isLoading = false);
      _showSnackbar(res['message'] ?? 'Gagal menolak permintaan.', isError: true);
    }
  }

  Future<void> _handleGenerateToken(int id, String requesterName) async {
    setState(() => _isLoading = true);
    final res = await _apiService.generatePasswordResetToken(id);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true && res['token'] != null) {
      final token = res['token'] as String;
      final expiresAt = res['expires_at'] as String? ?? '';
      final validity = res['validity_seconds'] as int? ?? 300;

      setState(() {
        _activeTokens[id] = {
          'token': token,
          'expires_at': expiresAt,
          'validity_seconds': validity,
          'generated_at': DateTime.now(),
        };
      });

      _showTokenModal(id, requesterName, token, expiresAt, validity);
    } else {
      _showSnackbar(res['message'] ?? 'Gagal membuat token.', isError: true);
    }
  }

  void _showTokenModal(
    int id,
    String requesterName,
    String token,
    String expiresAt,
    int validitySeconds,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TokenDisplayDialog(
        requesterName: requesterName,
        token: token,
        expiresAt: expiresAt,
        validitySeconds: validitySeconds,
        onClose: () {
          Navigator.pop(ctx);
          _fetchRequests();
        },
      ),
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : AppTheme.green700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2563EB); // Blue/Indigo
      case 'completed':
        return AppTheme.green700;
      case 'rejected':
        return Colors.red.shade600;
      case 'pending':
      default:
        return const Color(0xFFD97706); // Amber
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Disetujui (Siap Diberi Token)';
      case 'completed':
        return 'Selesai (Password Diperbarui)';
      case 'rejected':
        return 'Ditolak';
      case 'pending':
      default:
        return 'Menunggu Persetujuan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _buildFilterHeader(),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.green700),
                )
              : _requests.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetchRequests,
                      color: AppTheme.green700,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (ctx, idx) {
                          final item = _requests[idx] as Map<String, dynamic>;
                          return _buildRequestCard(item);
                        },
                      ),
                    ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Container(
        color: AppTheme.pageBg,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        title: const Text('Verifikasi Pemulihan Akun'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.dark900,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan data',
            onPressed: _fetchRequests,
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama petani, kelompok tani, atau kontak...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchRequests();
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onSubmitted: (_) => _fetchRequests(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.green700,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _fetchRequests,
                child: const Text('Cari'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('all', 'Semua'),
                const SizedBox(width: 8),
                _buildStatusChip('pending', 'Menunggu'),
                const SizedBox(width: 8),
                _buildStatusChip('approved', 'Disetujui'),
                const SizedBox(width: 8),
                _buildStatusChip('completed', 'Selesai'),
                const SizedBox(width: 8),
                _buildStatusChip('rejected', 'Ditolak'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() => _selectedStatus = status);
          _fetchRequests();
        }
      },
      selectedColor: AppTheme.green700.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppTheme.green700 : AppTheme.dark900,
      ),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.green700 : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tidak ada permintaan pemulihan password',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Permintaan reset dari petani atau anggota Poktan akan tampil di sini untuk diverifikasi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> item) {
    final id = item['id'] as int;
    final name = item['name'] as String? ?? 'Tanpa Nama';
    final group = item['farmer_group_name'] as String? ?? '-';
    final contact = item['contact_info'] as String? ?? '-';
    final status = item['status'] as String? ?? 'pending';
    final reason = item['rejection_reason'] as String?;
    final createdAt = item['created_at'] as String? ?? '';
    final user = item['user'] as Map<String, dynamic>?;
    final statusColor = _getStatusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Icon(
                  status == 'completed'
                      ? Icons.check_circle_rounded
                      : status == 'approved'
                          ? Icons.verified_user_rounded
                          : status == 'rejected'
                              ? Icons.cancel_rounded
                              : Icons.hourglass_top_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dark900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.groups_outlined,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            group,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Details grid
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kontak / WhatsApp',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.dark900,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Akun Terkait di Sistem',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user != null ? '${user['name']} (${user['email']})' : 'Belum Dipetakan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: user != null ? AppTheme.green700 : Colors.orange.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Alasan penolakan: $reason',
                      style: TextStyle(
                          fontSize: 12, color: Colors.red.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Diajukan pada: $createdAt',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],

          const SizedBox(height: 14),

          // Action Buttons depending on status
          if (status == 'pending') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Tolak'),
                    onPressed: () => _handleReject(id, name),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.green700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Setujui'),
                    onPressed: () => _handleApprove(id, name),
                  ),
                ),
              ],
            ),
          ] else if (status == 'approved') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B), // Dark slate
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.key_rounded, size: 18),
                label: const Text('Buat Token Reset 5 Menit'),
                onPressed: () => _handleGenerateToken(id, name),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Modal Dialog Displaying Generated 5-Minute Token ──────────────────────────
class _TokenDisplayDialog extends StatefulWidget {
  final String requesterName;
  final String token;
  final String expiresAt;
  final int validitySeconds;
  final VoidCallback onClose;

  const _TokenDisplayDialog({
    required this.requesterName,
    required this.token,
    required this.expiresAt,
    required this.validitySeconds,
    required this.onClose,
  });

  @override
  State<_TokenDisplayDialog> createState() => _TokenDisplayDialogState();
}

class _TokenDisplayDialogState extends State<_TokenDisplayDialog> {
  int _remainingSeconds = 300;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.validitySeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _copyToken() {
    Clipboard.setData(ClipboardData(text: widget.token));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Token reset berhasil disalin ke clipboard!'),
        backgroundColor: AppTheme.green700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyTemplateMessage() {
    final msg =
        'Halo ${widget.requesterName}, permohonan reset kata sandi Anda telah disetujui oleh Super Admin SumberTani.\n\n'
        'Kode Token Reset Anda:\n👉 *${widget.token}*\n\n'
        '⚠️ Token ini HANYA BERLAKU SELAMA 5 MENIT. Segera buka aplikasi SumberTani > Lupa Password > Masukkan Token untuk membuat password baru.';
    Clipboard.setData(ClipboardData(text: msg));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pesan WhatsApp siap kirim berhasil disalin!'),
        backgroundColor: AppTheme.green700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remainingSeconds <= 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isExpired
                    ? Colors.red.shade50
                    : AppTheme.green700.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isExpired ? Icons.timer_off_rounded : Icons.vpn_key_rounded,
                color: isExpired ? Colors.red : AppTheme.green700,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isExpired ? 'Token Sudah Kedaluwarsa' : 'Token Reset Aktif',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isExpired ? Colors.red.shade800 : AppTheme.dark900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Untuk pengguna: ${widget.requesterName}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),

            // Token Container Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Dark slate bg
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isExpired ? Colors.red : const Color(0xFF38BDF8),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  SelectableText(
                    widget.token,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                      color: Color(0xFF38BDF8), // Cyan neon
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time_filled_rounded,
                        size: 14,
                        color: isExpired ? Colors.red : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isExpired
                            ? 'Kedaluwarsa'
                            : 'Sisa Waktu: ${_formatTimer(_remainingSeconds)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isExpired ? Colors.red : Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Salin Token'),
                    onPressed: _copyToken,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: const Text('Salin Format WA'),
                    onPressed: _copyTemplateMessage,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Text(
              'Berikan token ini kepada petani untuk dimasukkan pada menu "Lupa Password" di aplikasi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: widget.onClose,
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
