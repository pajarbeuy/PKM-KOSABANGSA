import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';

class SuperAdminOrdersScreen extends StatefulWidget {
  final bool isEmbedded;
  const SuperAdminOrdersScreen({super.key, this.isEmbedded = false});

  @override
  State<SuperAdminOrdersScreen> createState() => _SuperAdminOrdersScreenState();
}

class _SuperAdminOrdersScreenState extends State<SuperAdminOrdersScreen> {
  final ApiService _apiService = ApiService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final statusParam = _selectedStatus == 'all' ? null : _selectedStatus;
      final results = await _apiService.getSuperAdminOrders(
        status: statusParam,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _orders = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar pesanan: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    final res = await _apiService.updateOrderStatus(orderId, newStatus);
    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] as String? ?? 'Status pesanan berhasil diperbarui'), backgroundColor: AppTheme.green700),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] as String? ?? 'Gagal memperbarui status'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _completeOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.green700, size: 28),
            SizedBox(width: 8),
            Text('Selesaikan Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin menyelesaikan pesanan ${order.orderCode} atas nama ${order.customerName}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tindakan ini akan mencatat transaksi Penjualan (Sale) atas nama petani pemilik dan mengurangi stok produk olahan secara otomatis.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Selesaikan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = await _apiService.completeOrder(order.id);
    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] as String? ?? 'Pesanan berhasil diselesaikan!'), backgroundColor: AppTheme.green700),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] as String? ?? 'Gagal menyelesaikan pesanan'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pesanan'),
        content: Text('Apakah Anda yakin ingin membatalkan pesanan ${order.orderCode}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = await _apiService.cancelOrder(order.id);
    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] as String? ?? 'Pesanan berhasil dibatalkan'), backgroundColor: Colors.grey.shade800),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] as String? ?? 'Gagal membatalkan pesanan'), backgroundColor: Colors.red),
      );
    }
  }

  void _copyCustomerContact(String phone, String name) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nomor kontak $name ($phone) berhasil disalin.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildStatusChip(String statusKey, String label, Color bg, Color textColor) {
    final isSelected = _selectedStatus == statusKey;
    return InkWell(
      onTap: () {
        setState(() => _selectedStatus = statusKey);
        _loadOrders();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.dark900 : bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.dark900 : textColor.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        bg = Colors.amber.shade100;
        text = Colors.amber.shade900;
        label = 'Pending';
        break;
      case 'confirmed':
        bg = Colors.blue.shade100;
        text = Colors.blue.shade900;
        label = 'Dikonfirmasi';
        break;
      case 'processing':
        bg = Colors.indigo.shade100;
        text = Colors.indigo.shade900;
        label = 'Diproses';
        break;
      case 'completed':
        bg = Colors.green.shade100;
        text = Colors.green.shade900;
        label = 'Selesai';
        break;
      case 'cancelled':
        bg = Colors.red.shade100;
        text = Colors.red.shade900;
        label = 'Dibatalkan';
        break;
      default:
        bg = Colors.grey.shade200;
        text = Colors.grey.shade800;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    String formattedDate = '-';
    if (order.createdAt != null) {
      try {
        final parsed = DateTime.parse(order.createdAt!);
        formattedDate = _dateFormat.format(parsed);
      } catch (_) {
        formattedDate = order.createdAt!.split('T')[0];
      }
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Code, Date & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderCode,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: AppTheme.dark900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const Divider(height: 24),

            // Customer Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.green700),
                      const SizedBox(width: 6),
                      Text(
                        order.customerName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.dark900),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _copyCustomerContact(order.customerPhone, order.customerName),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            children: [
                              Icon(Icons.phone_rounded, size: 14, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Text(
                                order.customerPhone,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (order.customerAddress != null && order.customerAddress!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.customerAddress!,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.2),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note_alt_outlined, size: 16, color: Colors.amber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Catatan: ${order.notes}',
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Order Items List
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.green100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.green700),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Petani: ${item.ownerName ?? "Mitra"} • ${item.quantity} unit × ${_currencyFormat.format(item.priceSnapshot)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _currencyFormat.format(item.subtotal),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )),

            const Divider(height: 20),

            // Total & Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pembayaran', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      _currencyFormat.format(order.totalAmount),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.green700),
                    ),
                  ],
                ),

                // Actions according to status
                Row(
                  children: [
                    if (order.isPending) ...[
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _cancelOrder(order),
                        child: const Text('Batal', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _updateStatus(order.id, 'confirmed'),
                        child: const Text('Konfirmasi', style: TextStyle(fontSize: 12)),
                      ),
                    ] else if (order.isConfirmed) ...[
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _cancelOrder(order),
                        child: const Text('Batal', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _updateStatus(order.id, 'processing'),
                        child: const Text('Proses', style: TextStyle(fontSize: 12)),
                      ),
                    ] else if (order.isProcessing) ...[
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _cancelOrder(order),
                        child: const Text('Batal', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.green700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _completeOrder(order),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Selesaikan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ] else if (order.isCompleted) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.green100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.green700),
                            SizedBox(width: 4),
                            Text('Penjualan Tercatat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.green700)),
                          ],
                        ),
                      ),
                    ] else if (order.isCancelled) ...[
                      Text('Pesanan Dibatalkan', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppTheme.green700,
      child: Column(
        children: [
          // Filter & Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nomor pesanan atau nama pelanggan...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadOrders();
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onSubmitted: (val) {
                    setState(() => _searchQuery = val);
                    _loadOrders();
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip('all', 'Semua', Colors.grey.shade100, Colors.grey.shade800),
                      const SizedBox(width: 8),
                      _buildStatusChip('pending', 'Pending', Colors.amber.shade50, Colors.amber.shade900),
                      const SizedBox(width: 8),
                      _buildStatusChip('confirmed', 'Dikonfirmasi', Colors.blue.shade50, Colors.blue.shade900),
                      const SizedBox(width: 8),
                      _buildStatusChip('processing', 'Diproses', Colors.indigo.shade50, Colors.indigo.shade900),
                      const SizedBox(width: 8),
                      _buildStatusChip('completed', 'Selesai', Colors.green.shade50, Colors.green.shade900),
                      const SizedBox(width: 8),
                      _buildStatusChip('cancelled', 'Dibatalkan', Colors.red.shade50, Colors.red.shade900),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada pesanan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pesanan dari katalog publik akan muncul di sini.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
                      ),
          ),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        title: const Text('Manajemen Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.dark900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: content,
    );
  }
}
