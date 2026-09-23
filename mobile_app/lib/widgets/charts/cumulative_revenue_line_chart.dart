import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';

class CumulativeRevenuePoint {
  final int month;
  final String label;
  final int monthlyRevenue;
  final int cumulativeRevenue;

  const CumulativeRevenuePoint({
    required this.month,
    required this.label,
    required this.monthlyRevenue,
    required this.cumulativeRevenue,
  });

  factory CumulativeRevenuePoint.fromJson(Map<String, dynamic> json) {
    return CumulativeRevenuePoint(
      month: json['month'] as int? ?? 1,
      label: json['label'] as String? ?? '',
      monthlyRevenue: (json['monthly_revenue'] as num?)?.toInt() ?? 0,
      cumulativeRevenue: (json['cumulative_revenue'] as num?)?.toInt() ?? 0,
    );
  }
}

class CumulativeRevenueLineChart extends StatefulWidget {
  final List<CumulativeRevenuePoint> data;
  final int? totalYearRevenue;
  final String? cachedAt;

  const CumulativeRevenueLineChart({
    super.key,
    required this.data,
    this.totalYearRevenue,
    this.cachedAt,
  });

  @override
  State<CumulativeRevenueLineChart> createState() => _CumulativeRevenueLineChartState();
}

class _CumulativeRevenueLineChartState extends State<CumulativeRevenueLineChart> {
  int? _hoveredIndex;

  String _formatRp(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.data;
    final int maxVal = points.isEmpty
        ? 100000
        : points.map((p) => p.cumulativeRevenue).reduce(math.max);
    final double safeMax = maxVal <= 0 ? 100000.0 : maxVal.toDouble();
    final int totalRevenue = widget.totalYearRevenue ??
        (points.isEmpty ? 0 : points.last.cumulativeRevenue);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.blue100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.show_chart_rounded,
                            color: AppTheme.blue600,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Akumulasi Penghasilan Petani',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.dark900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total: ${_formatRp(totalRevenue)} tahun ini',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, size: 13, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Update tiap jam',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart Body
          SizedBox(
            height: 190,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return MouseRegion(
                  onHover: (event) {
                    final widthPerPoint = constraints.maxWidth / (points.isEmpty ? 1 : points.length);
                    final idx = (event.localPosition.dx / widthPerPoint).floor().clamp(0, points.length - 1);
                    if (_hoveredIndex != idx) {
                      setState(() => _hoveredIndex = idx);
                    }
                  },
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size(constraints.maxWidth, 190),
                        painter: _LineChartPainter(
                          points: points,
                          maxValue: safeMax,
                          hoveredIndex: _hoveredIndex,
                        ),
                      ),
                      if (_hoveredIndex != null && _hoveredIndex! < points.length)
                        _buildTooltipOverlay(constraints.maxWidth, points[_hoveredIndex!]),
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

  Widget _buildTooltipOverlay(double totalWidth, CumulativeRevenuePoint point) {
    final widthPerPoint = totalWidth / widget.data.length;
    final posX = (widget.data.indexOf(point) * widthPerPoint) + (widthPerPoint / 2);

    return Positioned(
      left: (posX - 75).clamp(8.0, totalWidth - 158.0),
      top: 4,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${point.label}: ${_formatRp(point.cumulativeRevenue)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (point.monthlyRevenue > 0)
                Text(
                  'Bulan ini: +${_formatRp(point.monthlyRevenue)}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF4ADE80)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<CumulativeRevenuePoint> points;
  final double maxValue;
  final int? hoveredIndex;

  _LineChartPainter({
    required this.points,
    required this.maxValue,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final bottomPadding = 26.0;
    final topPadding = 20.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final count = points.length;
    final slotWidth = size.width / count;

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight * (i / 3));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final offsets = <Offset>[];
    for (int i = 0; i < count; i++) {
      final p = points[i];
      final x = (i * slotWidth) + (slotWidth / 2);
      final ratio = (p.cumulativeRevenue / maxValue).clamp(0.0, 1.0);
      final y = topPadding + chartHeight - (ratio * chartHeight);
      offsets.add(Offset(x, y));
    }

    // Build smooth cubic bezier path
    final linePath = Path();
    linePath.moveTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final curr = offsets[i];
      final next = offsets[i + 1];
      final controlX1 = curr.dx + (next.dx - curr.dx) * 0.45;
      final controlY1 = curr.dy;
      final controlX2 = curr.dx + (next.dx - curr.dx) * 0.55;
      final controlY2 = next.dy;
      linePath.cubicTo(controlX1, controlY1, controlX2, controlY2, next.dx, next.dy);
    }

    // Area Gradient Fill
    final areaPath = Path.from(linePath);
    areaPath.lineTo(offsets.last.dx, topPadding + chartHeight);
    areaPath.lineTo(offsets.first.dx, topPadding + chartHeight);
    areaPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2563EB).withValues(alpha: 0.22),
          const Color(0xFF2563EB).withValues(alpha: 0.01),
        ],
      ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight));

    canvas.drawPath(areaPath, fillPaint);

    // Stroke Path
    final strokePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, strokePaint);

    // Draw Points and Month Labels
    final dotPaint = Paint()..color = const Color(0xFF2563EB);
    final innerDotPaint = Paint()..color = Colors.white;

    for (int i = 0; i < count; i++) {
      final p = points[i];
      final pt = offsets[i];
      final isHovered = hoveredIndex == i;

      // Draw dot
      if (p.cumulativeRevenue > 0 || isHovered) {
        canvas.drawCircle(pt, isHovered ? 5.5 : 4.0, dotPaint);
        canvas.drawCircle(pt, isHovered ? 3.0 : 2.0, innerDotPaint);
      }

      // Draw Month Label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: p.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isHovered ? FontWeight.bold : FontWeight.w500,
            color: isHovered ? const Color(0xFF2563EB) : AppTheme.textSecondary,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final labelOffset = Offset(
        pt.dx - (labelPainter.width / 2),
        size.height - bottomPadding + 6,
      );
      labelPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.points != points;
  }
}
