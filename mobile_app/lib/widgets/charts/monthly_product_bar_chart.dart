import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../app_theme.dart';

class MonthlyProductBarPoint {
  final int month;
  final String label;
  final int totalSold;

  const MonthlyProductBarPoint({
    required this.month,
    required this.label,
    required this.totalSold,
  });

  factory MonthlyProductBarPoint.fromJson(Map<String, dynamic> json) {
    return MonthlyProductBarPoint(
      month: json['month'] as int? ?? 1,
      label: json['label'] as String? ?? '',
      totalSold: (json['total_sold'] as num?)?.toInt() ?? 0,
    );
  }
}

class MonthlyProductBarChart extends StatefulWidget {
  final List<MonthlyProductBarPoint> data;
  final int? totalYearSold;
  final String? cachedAt;

  const MonthlyProductBarChart({
    super.key,
    required this.data,
    this.totalYearSold,
    this.cachedAt,
  });

  @override
  State<MonthlyProductBarChart> createState() => _MonthlyProductBarChartState();
}

class _MonthlyProductBarChartState extends State<MonthlyProductBarChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final points = widget.data;
    final int maxVal = points.isEmpty
        ? 10
        : points.map((p) => p.totalSold).reduce(math.max);
    final double safeMax = maxVal <= 0 ? 10.0 : maxVal.toDouble();
    final int totalSold = widget.totalYearSold ??
        (points.isEmpty ? 0 : points.map((p) => p.totalSold).reduce((a, b) => a + b));

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
                            color: AppTheme.green100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bar_chart_rounded,
                            color: AppTheme.green700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Produk Olahan Terjual',
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
                      'Total: $totalSold pcs terjual tahun ini',
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
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, size: 13, color: Colors.amber.shade800),
                    const SizedBox(width: 4),
                    Text(
                      'Update tiap jam',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
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
                    final widthPerBar = constraints.maxWidth / (points.isEmpty ? 1 : points.length);
                    final idx = (event.localPosition.dx / widthPerBar).floor().clamp(0, points.length - 1);
                    if (_hoveredIndex != idx) {
                      setState(() => _hoveredIndex = idx);
                    }
                  },
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 190),
                    painter: _BarChartPainter(
                      points: points,
                      maxValue: safeMax,
                      hoveredIndex: _hoveredIndex,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<MonthlyProductBarPoint> points;
  final double maxValue;
  final int? hoveredIndex;

  _BarChartPainter({
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
    final barCount = points.length;
    final slotWidth = size.width / barCount;
    final barWidth = math.max(10.0, math.min(slotWidth * 0.52, 28.0));

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight * (i / 3));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final barRadius = Radius.circular(barWidth / 2);

    for (int i = 0; i < barCount; i++) {
      final p = points[i];
      final isHovered = hoveredIndex == i;
      final slotCenterX = (i * slotWidth) + (slotWidth / 2);
      final barLeft = slotCenterX - (barWidth / 2);

      // Height
      final ratio = (p.totalSold / maxValue).clamp(0.0, 1.0);
      final barHeight = math.max(ratio * chartHeight, p.totalSold > 0 ? 6.0 : 2.0);
      final barTop = topPadding + chartHeight - barHeight;

      // Paint
      final Paint barPaint = Paint();
      if (p.totalSold > 0) {
        barPaint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isHovered
              ? [const Color(0xFF27AE60), const Color(0xFF1E8449)]
              : [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
        ).createShader(Rect.fromLTWH(barLeft, barTop, barWidth, barHeight));
      } else {
        barPaint.color = isHovered ? Colors.grey.shade300 : const Color(0xFFE8ECEF);
      }

      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
        topLeft: barRadius,
        topRight: barRadius,
        bottomLeft: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      );
      canvas.drawRRect(rrect, barPaint);

      // Tooltip/Value on top if hovered or value > 0
      if (isHovered || (p.totalSold > 0 && barHeight > 18)) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${p.totalSold}',
            style: TextStyle(
              fontSize: isHovered ? 12 : 10,
              fontWeight: FontWeight.bold,
              color: isHovered ? AppTheme.green700 : AppTheme.dark900,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();

        final textOffset = Offset(
          slotCenterX - (textPainter.width / 2),
          barTop - textPainter.height - 3,
        );
        textPainter.paint(canvas, textOffset);
      }

      // Month Label on bottom
      final labelPainter = TextPainter(
        text: TextSpan(
          text: p.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isHovered ? FontWeight.bold : FontWeight.w500,
            color: isHovered ? AppTheme.green700 : AppTheme.textSecondary,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final labelOffset = Offset(
        slotCenterX - (labelPainter.width / 2),
        size.height - bottomPadding + 6,
      );
      labelPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.points != points;
  }
}
