import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/dashboard.dart';
import '../app_theme.dart';

enum ProcessedChartMode { all, pcs, rupiah }

class ProcessedSalesChart extends StatefulWidget {
  final List<MonthlyStat> monthlyStats;

  const ProcessedSalesChart({
    super.key,
    required this.monthlyStats,
  });

  @override
  State<ProcessedSalesChart> createState() => _ProcessedSalesChartState();
}

class _ProcessedSalesChartState extends State<ProcessedSalesChart> {
  ProcessedChartMode _mode = ProcessedChartMode.all;
  int? _hoveredIndex;
  Offset? _tooltipPos;

  bool get _hasData {
    if (widget.monthlyStats.isEmpty) return false;
    return widget.monthlyStats.any(
      (s) => s.processedSalesPcs > 0 || s.processedSalesRp > 0,
    );
  }

  double get _totalPcs =>
      widget.monthlyStats.fold(0.0, (acc, s) => acc + s.processedSalesPcs);

  double get _totalRp =>
      widget.monthlyStats.fold(0.0, (acc, s) => acc + s.processedSalesRp);

  @override
  Widget build(BuildContext context) {
    final hasData = _hasData;
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.card,
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header Row: Title, summary badges & Mode toggle ────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Grafik Produk Olahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'pcs & Rp',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Volume produk terjual (pcs) & total nominal penjualan (Rp)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasData)
                _buildModeToggle(),
            ],
          ),
          const SizedBox(height: 16),

          // ── Chart Canvas / Empty State ─────────────────────────────────────
          SizedBox(
            height: 220,
            child: LayoutBuilder(
              builder: (context, bounds) {
                if (!hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 46,
                          color: AppTheme.textSecondary.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Belum ada penjualan produk olahan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Grafik ini akan otomatis aktif saat ada transaksi produk olahan.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return MouseRegion(
                  onExit: (_) => setState(() {
                    _hoveredIndex = null;
                    _tooltipPos = null;
                  }),
                  child: GestureDetector(
                    onTapDown: (details) => _handlePointer(details.localPosition, bounds.maxWidth),
                    child: Listener(
                      onPointerMove: (e) => _handlePointer(e.localPosition, bounds.maxWidth),
                      onPointerHover: (e) => _handlePointer(e.localPosition, bounds.maxWidth),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            painter: _ProcessedChartPainter(
                              stats: widget.monthlyStats,
                              mode: _mode,
                              hoveredIndex: _hoveredIndex,
                            ),
                            size: Size.infinite,
                          ),
                          if (_hoveredIndex != null &&
                              _tooltipPos != null &&
                              _hoveredIndex! >= 0 &&
                              _hoveredIndex! < widget.monthlyStats.length)
                            _buildTooltip(
                              context,
                              widget.monthlyStats[_hoveredIndex!],
                              _tooltipPos!,
                              bounds.maxWidth,
                              currencyFormatter,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // ── Legend & Summary ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                children: [
                  if (_mode == ProcessedChartMode.all || _mode == ProcessedChartMode.pcs)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Volume (pcs)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  if (_mode == ProcessedChartMode.all || _mode == ProcessedChartMode.rupiah)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Penjualan (Rp)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (hasData)
                Text(
                  'Total: ${_totalPcs.toInt()} pcs · ${currencyFormatter.format(_totalRp)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeBtn('Semua', ProcessedChartMode.all),
          _modeBtn('pcs', ProcessedChartMode.pcs),
          _modeBtn('Rp', ProcessedChartMode.rupiah),
        ],
      ),
    );
  }

  Widget _modeBtn(String label, ProcessedChartMode mode) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  void _handlePointer(Offset pos, double width) {
    if (widget.monthlyStats.isEmpty) return;
    const double leftPad = 52.0;
    const double rightPad = 52.0;
    final chartW = width - leftPad - rightPad;
    final count = widget.monthlyStats.length;
    final step = chartW / (count > 1 ? count - 1 : 1);

    int closest = 0;
    double minDist = double.infinity;
    double closestX = leftPad;

    for (int i = 0; i < count; i++) {
      final x = leftPad + i * step;
      final dist = (pos.dx - x).abs();
      if (dist < minDist) {
        minDist = dist;
        closest = i;
        closestX = x;
      }
    }

    setState(() {
      _hoveredIndex = closest;
      _tooltipPos = Offset(closestX, pos.dy);
    });
  }

  Widget _buildTooltip(
    BuildContext context,
    MonthlyStat stat,
    Offset position,
    double maxWidth,
    NumberFormat currencyFormatter,
  ) {
    const double tooltipW = 210.0;
    const double tooltipH = 88.0;
    const double safeMargin = 16.0;

    double left = position.dx - tooltipW / 2;
    left = left.clamp(safeMargin, (maxWidth - tooltipW - safeMargin).clamp(0.0, double.infinity));

    double top = position.dy - tooltipH - 14;
    if (top < 0) top = position.dy + 14;

    return Positioned(
      left: left,
      top: top,
      width: tooltipW,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stat.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Olahan Terjual: ${stat.processedSalesPcs.toInt()} pcs',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Penjualan: ${currencyFormatter.format(stat.processedSalesRp)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Custom Painter ─────────────────────────────────────────────────────────
class _ProcessedChartPainter extends CustomPainter {
  final List<MonthlyStat> stats;
  final ProcessedChartMode mode;
  final int? hoveredIndex;

  static const double leftPad = 52.0;
  static const double rightPad = 52.0;
  static const double topPad = 16.0;
  static const double botPad = 26.0;

  const _ProcessedChartPainter({
    required this.stats,
    required this.mode,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stats.isEmpty) return;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - botPad;
    final count = stats.length;

    // ── Calculate scales ──────────────────────────────────────────────────
    final maxPcsRaw = stats.map((s) => s.processedSalesPcs).reduce(math.max);
    final maxRpRaw = stats.map((s) => s.processedSalesRp).reduce(math.max);

    final maxPcs = _roundUpMax(maxPcsRaw > 0 ? maxPcsRaw : 10);
    final maxRp = _roundUpMax(maxRpRaw > 0 ? maxRpRaw : 100000);

    // ── Draw grid and Y labels ────────────────────────────────────────────
    _drawGridAndAxes(canvas, size, chartH, chartW, maxPcs, maxRp);

    // ── Draw X month labels ───────────────────────────────────────────────
    _drawXLabels(canvas, size, chartW, count);

    // ── Draw Bars for pcs ─────────────────────────────────────────────────
    if (mode == ProcessedChartMode.all || mode == ProcessedChartMode.pcs) {
      _drawBars(canvas, size, chartH, chartW, count, maxPcs);
    }

    // ── Draw Line / Area for Rp ───────────────────────────────────────────
    if (mode == ProcessedChartMode.all || mode == ProcessedChartMode.rupiah) {
      _drawLineAndArea(canvas, size, chartH, chartW, count, maxRp);
    }

    // ── Draw Hover indicator ──────────────────────────────────────────────
    if (hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < count) {
      final x = leftPad + (count > 1 ? hoveredIndex! / (count - 1) : 0.5) * chartW;
      final hoverPaint = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(x, topPad),
        Offset(x, size.height - botPad),
        hoverPaint,
      );
    }
  }

  void _drawGridAndAxes(
    Canvas canvas,
    Size size,
    double chartH,
    double chartW,
    double maxPcs,
    double maxRp,
  ) {
    const steps = 4;
    final linePaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    final tpLeft = TextPainter(textDirection: ui.TextDirection.ltr);
    final tpRight = TextPainter(textDirection: ui.TextDirection.ltr);

    for (int i = 0; i <= steps; i++) {
      final y = topPad + chartH * (1 - i / steps);

      // Horizontal dashed / grid line
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        linePaint,
      );

      // Left axis: pcs
      if (mode == ProcessedChartMode.all || mode == ProcessedChartMode.pcs) {
        final pcsVal = (maxPcs * i / steps).round();
        tpLeft.text = TextSpan(
          text: '$pcsVal pcs',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        );
        tpLeft.layout();
        tpLeft.paint(canvas, Offset(leftPad - tpLeft.width - 6, y - tpLeft.height / 2));
      }

      // Right axis: Rp
      if (mode == ProcessedChartMode.all || mode == ProcessedChartMode.rupiah) {
        final rpVal = (maxRp * i / steps).round();
        tpRight.text = TextSpan(
          text: _formatCompactRp(rpVal),
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        );
        tpRight.layout();
        tpRight.paint(canvas, Offset(size.width - rightPad + 6, y - tpRight.height / 2));
      }
    }
  }

  void _drawXLabels(Canvas canvas, Size size, double chartW, int count) {
    final tp = TextPainter(textDirection: ui.TextDirection.ltr);
    for (int i = 0; i < count; i++) {
      final x = leftPad + (count > 1 ? i / (count - 1) : 0.5) * chartW;
      final isHovered = hoveredIndex == i;

      tp.text = TextSpan(
        text: stats[i].label,
        style: TextStyle(
          color: isHovered ? AppTheme.textPrimary : const Color(0xFF94A3B8),
          fontSize: 11,
          fontWeight: isHovered ? FontWeight.w700 : FontWeight.w500,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - botPad + 6));
    }
  }

  void _drawBars(
    Canvas canvas,
    Size size,
    double chartH,
    double chartW,
    int count,
    double maxPcs,
  ) {
    const barWidth = 24.0;

    for (int i = 0; i < count; i++) {
      final x = leftPad + (count > 1 ? i / (count - 1) : 0.5) * chartW;
      final pcs = stats[i].processedSalesPcs;
      final barH = maxPcs > 0 ? (pcs / maxPcs) * chartH : 0.0;
      final isHovered = hoveredIndex == i;

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x - barWidth / 2,
          topPad + chartH - barH,
          barWidth,
          math.max(barH, 3.0),
        ),
        const Radius.circular(5),
      );

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isHovered
              ? [const Color(0xFF4338CA), const Color(0xFF6366F1)]
              : [
                  const Color(0xFF4F46E5).withValues(alpha: 0.85),
                  const Color(0xFF818CF8).withValues(alpha: 0.65),
                ],
        ).createShader(barRect.outerRect)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(barRect, barPaint);
    }
  }

  void _drawLineAndArea(
    Canvas canvas,
    Size size,
    double chartH,
    double chartW,
    int count,
    double maxRp,
  ) {
    final points = <Offset>[];
    for (int i = 0; i < count; i++) {
      final x = leftPad + (count > 1 ? i / (count - 1) : 0.5) * chartW;
      final rp = stats[i].processedSalesRp;
      final y = topPad + chartH * (1 - (maxRp > 0 ? (rp / maxRp) : 0.0));
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // Filled area below line
    final path = Path();
    path.moveTo(points.first.dx, size.height - botPad);
    path.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    path.lineTo(points.last.dx, size.height - botPad);
    path.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF10B981).withValues(alpha: 0.22),
          const Color(0xFF10B981).withValues(alpha: 0.01),
        ],
      ).createShader(Rect.fromLTWH(0, topPad, size.width, chartH))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, areaPaint);

    // Stroke line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cx = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    final strokePaint = Paint()
      ..color = const Color(0xFF059669)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, strokePaint);

    // Points dot
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final isHovered = hoveredIndex == i;
      final radius = isHovered ? 6.0 : 4.0;

      canvas.drawCircle(p, radius + 2.0, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        radius,
        Paint()..color = isHovered ? const Color(0xFF047857) : const Color(0xFF10B981),
      );
    }
  }

  double _roundUpMax(double raw) {
    if (raw <= 0) return 100;
    final step = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    return (raw / step).ceil() * step * 1.20;
  }

  String _formatCompactRp(int value) {
    if (value >= 1000000) {
      final jt = value / 1000000;
      return '${jt.toStringAsFixed(jt % 1 == 0 ? 0 : 1)}jt';
    }
    if (value >= 1000) {
      final rb = value / 1000;
      return '${rb.toStringAsFixed(rb % 1 == 0 ? 0 : 1)}rb';
    }
    return value.toString();
  }

  @override
  bool shouldRepaint(_ProcessedChartPainter old) =>
      old.stats != stats || old.mode != mode || old.hoveredIndex != hoveredIndex;
}
