import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/season.dart';
import '../utils/download_helper.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_shell.dart';

class ReportsScreen extends StatefulWidget {
  final int initialTabIndex;
  const ReportsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  // Profit & Loss data
  bool _isPLReady = false;
  int? _selectedSeasonId;
  List<Season> _seasons = [];
  int _totalHarvest = 0;
  double _totalRevenue = 0.0;
  double _totalCost = 0.0;
  double _profit = 0.0;
  
  // Target vs Actual data
  bool _isTvAReady = false;
  List<dynamic> _tvaData = [];
  
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(_handleTabChange);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      if (_tabController.index == 0) {
        // Load Seasons and Profit Loss
        final seasons = await _apiService.getSeasons();
        final pl = await _apiService.getProfitLossReport(seasonId: _selectedSeasonId);
        
        setState(() {
          _seasons = seasons;
          if (pl != null) {
            _totalHarvest = pl['total_harvest_kg'] as int? ?? 0;
            _totalRevenue = (pl['total_revenue'] as num? ?? 0).toDouble();
            _totalCost = (pl['total_cost'] as num? ?? 0).toDouble();
            _profit = (pl['profit'] as num? ?? 0).toDouble();
          }
          _isPLReady = true;
          _isLoading = false;
        });
      } else {
        // Load Target vs Actual
        final tva = await _apiService.getTargetVsActualReport();
        setState(() {
          _tvaData = tva;
          _isTvAReady = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat laporan: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatRp(double val) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(val);
  }

  Future<void> _exportPdf() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    // Show progress dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: Color(0xFF27AE60)),
              SizedBox(width: 20),
              Expanded(child: Text('Sedang membuat PDF...\nMohon tunggu sebentar.')),
            ],
          ),
        ),
      );
    }

    try {
      final List<int>? pdfBytes;
      final String filename;

      if (_tabController.index == 0) {
        pdfBytes = await _apiService.downloadProfitLossReportPdf(seasonId: _selectedSeasonId);
        filename = _selectedSeasonId != null
            ? 'Laporan_Laba_Rugi_Musim_$_selectedSeasonId.pdf'
            : 'Laporan_Laba_Rugi_Semua_Musim.pdf';
      } else {
        pdfBytes = await _apiService.downloadTargetVsActualReportPdf();
        filename = 'Laporan_Target_vs_Realisasi.pdf';
      }

      // Close progress dialog
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isExporting = false);

      if (pdfBytes != null && pdfBytes.isNotEmpty) {
        downloadFile(pdfBytes, filename);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Laporan PDF berhasil diunduh!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Gagal mengunduh PDF: Data kosong'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Close progress dialog
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal ekspor PDF: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
      controller: _tabController,
      indicatorColor: AppTheme.green700,
      indicatorWeight: 3,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      unselectedLabelColor: AppTheme.textSecondary,
      labelColor: AppTheme.textPrimary,
      tabs: const [
        Tab(text: 'Laba / Rugi'),
        Tab(text: 'Realisasi Target'),
      ],
    );

    return AppShell(
      currentRoute: 'reports',
      title: 'Laporan & Analitik',
      subtitle: 'Analisis laba rugi dan realisasi target',
      onRefresh: _loadReportData,
      headerActions: [
        if (_isExporting)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: AppTheme.green700, strokeWidth: 2),
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            color: AppTheme.textSecondary,
            tooltip: 'Unduh PDF',
            onPressed: _exportPdf,
          ),
      ],
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppTheme.cardBg,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: tabBar,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProfitLossTab(),
                      _buildTargetVsActualTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitLossTab() {
    if (!_isPLReady) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bar_chart_outlined, size: 60, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              const Text(
                'Laporan belum tersedia saat ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReportData,
                child: const Text('Muat Ulang'),
              ),
            ],
          ),
        ),
      );
    }

    final costRatio = _totalRevenue > 0 ? (_totalCost / _totalRevenue) : 0.0;
    final profitRatio = _totalRevenue > 0 ? (_profit / _totalRevenue) : 0.0;
    final isLoss = _profit < 0;

    return RefreshIndicator(
      onRefresh: _loadReportData,
      color: const Color(0xFF27AE60),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Season filter and Export PDF Button
                isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 300,
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int?>(
                                    value: _selectedSeasonId,
                                    isExpanded: true,
                                    hint: const Text('Semua Musim Tanam'),
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Semua Musim Tanam'),
                                      ),
                                      ..._seasons.map((s) => DropdownMenuItem<int?>(
                                            value: s.id,
                                            child: Text(s.name),
                                          )),
                                    ],
                                    onChanged: (val) {
                                      setState(() => _selectedSeasonId = val);
                                      _loadReportData();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isExporting ? null : _exportPdf,
                            icon: _isExporting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.picture_as_pdf_rounded),
                            label: Text(_isExporting ? 'Membuat PDF...' : 'Ekspor PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isExporting ? Colors.grey : const Color(0xFF27AE60),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 2,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int?>(
                                  value: _selectedSeasonId,
                                  isExpanded: true,
                                  hint: const Text('Semua Musim Tanam'),
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('Semua Musim Tanam'),
                                    ),
                                    ..._seasons.map((s) => DropdownMenuItem<int?>(
                                          value: s.id,
                                          child: Text(s.name),
                                        )),
                                  ],
                                  onChanged: (val) {
                                    setState(() => _selectedSeasonId = val);
                                    _loadReportData();
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isExporting ? null : _exportPdf,
                              icon: _isExporting
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.picture_as_pdf_rounded),
                              label: Text(_isExporting ? 'Membuat PDF...' : 'Ekspor PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isExporting ? Colors.grey : const Color(0xFF27AE60),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                SizedBox(height: isDesktop ? 32 : 20),

                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildPLMainCard(isLoss),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rasio Keuangan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 16),
                            _buildRasioCard(costRatio, profitRatio, isLoss),
                            const SizedBox(height: 24),
                            const Text('Detail Neraca', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildBalanceDetailTile(icon: Icons.monetization_on_rounded, color: const Color(0xFF27AE60), title: 'Total Pendapatan', value: _formatRp(_totalRevenue), subtitle: 'Kotor')),
                                const SizedBox(width: 16),
                                Expanded(child: _buildBalanceDetailTile(icon: Icons.money_off_rounded, color: const Color(0xFFEB5757), title: 'Total Pengeluaran', value: _formatRp(_totalCost), subtitle: 'Lahan')),
                                const SizedBox(width: 16),
                                Expanded(child: _buildBalanceDetailTile(icon: Icons.scale_rounded, color: const Color(0xFF2D9CDB), title: 'Bobot Panen', value: '$_totalHarvest kg', subtitle: 'Aktual')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPLMainCard(isLoss),
                      const SizedBox(height: 24),
                      const Text('Rasio Keuangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 12),
                      _buildRasioCard(costRatio, profitRatio, isLoss),
                      const SizedBox(height: 24),
                      const Text('Detail Neraca', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 12),
                      _buildBalanceDetailTile(icon: Icons.monetization_on_rounded, color: const Color(0xFF27AE60), title: 'Total Pendapatan Kotor', value: _formatRp(_totalRevenue), subtitle: 'Penjualan kentang terverifikasi'),
                      const SizedBox(height: 12),
                      _buildBalanceDetailTile(icon: Icons.money_off_rounded, color: const Color(0xFFEB5757), title: 'Total Pengeluaran Lahan', value: _formatRp(_totalCost), subtitle: 'Bibit, pupuk, pestisida, & lainnya'),
                      const SizedBox(height: 12),
                      _buildBalanceDetailTile(icon: Icons.scale_rounded, color: const Color(0xFF2D9CDB), title: 'Total Bobot Panen', value: '$_totalHarvest kg', subtitle: 'Akumulasi ubi kentang yang dipanen'),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPLMainCard(bool isLoss) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLoss 
              ? [const Color(0xFFC0392B), const Color(0xFFE74C3C)]
              : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isLoss ? Colors.red : Colors.green).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            isLoss ? 'TOTAL KERUGIAN BERSIH' : 'TOTAL KEUNTUNGAN BERSIH',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Text(
            _formatRp(_profit.abs()),
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isLoss ? Icons.trending_down : Icons.trending_up, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  isLoss ? 'Beban biaya tinggi' : 'Margin keuntungan sehat',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRasioCard(double costRatio, double profitRatio, bool isLoss) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Biaya Produksi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                Text('${(costRatio * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: costRatio.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade100,
                color: Colors.red.shade400,
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Margin Keuntungan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                Text('${(profitRatio * 100).toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: isLoss ? Colors.red : Colors.green)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: profitRatio.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade100,
                color: isLoss ? Colors.red.shade300 : Colors.green.shade500,
                minHeight: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetVsActualTab() {
    if (!_isTvAReady) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timeline_outlined, size: 60, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              const Text(
                'Data target dan realisasi belum siap.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReportData,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReportData,
      color: const Color(0xFF27AE60),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Realisasi Hasil Panen per Musim', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(height: 8),
                                Text('Perbandingan total bobot panen (aktual) terhadap target awal yang ditetapkan kelompok tani.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isExporting ? null : _exportPdf,
                            icon: _isExporting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.picture_as_pdf_rounded),
                            label: Text(_isExporting ? 'Membuat PDF...' : 'Ekspor PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isExporting ? Colors.grey : const Color(0xFF27AE60),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 2,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Realisasi Hasil Panen per Musim', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 8),
                          Text('Perbandingan total bobot panen (aktual) terhadap target awal yang ditetapkan kelompok tani.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isExporting ? null : _exportPdf,
                              icon: _isExporting
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.picture_as_pdf_rounded),
                              label: Text(_isExporting ? 'Membuat PDF...' : 'Ekspor PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isExporting ? Colors.grey : const Color(0xFF27AE60),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 32),
                if (_tvaData.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60.0),
                      child: Column(
                        children: [
                          Icon(Icons.eco_rounded, size: 72, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Belum ada data musim tanam terdaftar', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  )
                else if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildTVAGraphCard(),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 4,
                        child: _buildTVADetailsList(),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildTVAGraphCard(),
                      const SizedBox(height: 20),
                      _buildTVADetailsList(),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTVAGraphCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IndicatorLegendBadge(color: Color(0xFF2D9CDB), label: 'Target (kg)'),
                SizedBox(width: 16),
                IndicatorLegendBadge(color: Color(0xFF27AE60), label: 'Aktual (kg)'),
              ],
            ),
            const SizedBox(height: 32),
            ..._tvaData.take(5).map((item) {
              final double targetVal = (item['target'] as num? ?? 0).toDouble();
              final double actualVal = (item['actual'] as num? ?? 0).toDouble();
              final name = item['season_name'] as String? ?? 'Musim';
              final double percent = (item['percentage'] as num? ?? 0).toDouble();
              
              double maxScale = targetVal > actualVal ? targetVal : actualVal;
              if (maxScale == 0) maxScale = 1.0;
              
              final double targetWidthFactor = targetVal / maxScale;
              final double actualWidthFactor = actualVal / maxScale;

              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6))),
                                  FractionallySizedBox(
                                    widthFactor: targetWidthFactor.clamp(0.02, 1.0),
                                    child: Container(height: 14, decoration: BoxDecoration(color: const Color(0xFF2D9CDB), borderRadius: BorderRadius.circular(6))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Stack(
                                children: [
                                  Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6))),
                                  FractionallySizedBox(
                                    widthFactor: actualWidthFactor.clamp(0.02, 1.0),
                                    child: Container(height: 14, decoration: BoxDecoration(color: const Color(0xFF27AE60), borderRadius: BorderRadius.circular(6))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '${percent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: percent >= 100 ? Colors.green.shade700 : (percent >= 70 ? Colors.orange.shade700 : Colors.red.shade700),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTVADetailsList() {
    return Column(
      children: _tvaData.map((item) {
        final target = item['target'] as int? ?? 0;
        final actual = item['actual'] as int? ?? 0;
        final double percent = (item['percentage'] as num? ?? 0).toDouble();
        final name = item['season_name'] as String? ?? 'Musim';
        final status = item['status'] as String? ?? 'danger';

        Color statusColor = Colors.red;
        IconData statusIcon = Icons.error_outline;
        String statusText = 'Kurang';

        if (status == 'success') {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle_outline;
          statusText = 'Tercapai';
        } else if (status == 'warning') {
          statusColor = Colors.orange;
          statusIcon = Icons.warning_amber_outlined;
          statusText = 'Hampir';
        }

        return Card(
          elevation: 0.5,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Target: $target kg', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(width: 12),
                          Text('Hasil: $actual kg', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBalanceDetailTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IndicatorLegendBadge extends StatelessWidget {
  final Color color;
  final String label;

  const IndicatorLegendBadge({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
