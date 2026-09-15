import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'app_theme.dart';

// ─── Chart Data Point ─────────────────────────────────────────────────────────
class ChartDataPoint {
  final String label;
  final double harvest;
  final double sales;
  const ChartDataPoint({required this.label, required this.harvest, required this.sales});
}

// ─── Harvest Sales Chart ──────────────────────────────────────────────────────
class HarvestSalesChart extends StatefulWidget {
  final List<double> harvestData;
  final List<double> salesData;
  final List<String> labels;

  const HarvestSalesChart({
    super.key,
    required this.harvestData,
    required this.salesData,
    this.labels = const ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul'],
  });

  @override
  State<HarvestSalesChart> createState() => _HarvestSalesChartState();
}

class _HarvestSalesChartState extends State<HarvestSalesChart> {
  bool _isArea = true;
  int? _hoveredIndex;
  Offset? _tooltipPos;

  List<ChartDataPoint> get _points {
    final count = math.max(widget.harvestData.length, widget.salesData.length);
    return List.generate(count, (i) {
      return ChartDataPoint(
        label: i < widget.labels.length ? widget.labels[i] : 'P${i + 1}',
        harvest: i < widget.harvestData.length ? widget.harvestData[i] : 0,
        sales: i < widget.salesData.length ? widget.salesData[i] : 0,
      );
    });
  }

  List<ChartDataPoint> get _effectivePoints {
    final pts = _points;
    if (pts.isEmpty) {
      return const [
        ChartDataPoint(label: 'Jan', harvest: 1200, sales: 980),
        ChartDataPoint(label: 'Feb', harvest: 1620, sales: 1380),
        ChartDataPoint(label: 'Mar', harvest: 920, sales: 840),
        ChartDataPoint(label: 'Apr', harvest: 1840, sales: 1660),
        ChartDataPoint(label: 'Mei', harvest: 1380, sales: 1220),
        ChartDataPoint(label: 'Jun', harvest: 2000, sales: 1820),
      ];
    }
    return pts;
  }

  bool get _hasData {
    if (_points.isEmpty) return false;
    return _points.any((p) => p.harvest > 0 || p.sales > 0);
  }

  @override
  Widget build(BuildContext context) {
    final pts = _effectivePoints;
    final hasData = _hasData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header row: title + toggle ──────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Grafik Panen & Penjualan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            if (hasData)
              _ToggleButtons(isArea: _isArea, onToggle: (v) => setState(() => _isArea = v)),
          ],
        ),
        const SizedBox(height: 16),

        // ── Chart area ──────────────────────────────────────────────────────
        SizedBox(
          height: 220,
          child: LayoutBuilder(builder: (context, box) {
            if (!hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.insert_chart_outlined_rounded,
                      size: 48,
                      color: AppTheme.textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Belum ada data panen & penjualan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Data grafik akan muncul setelah Anda mencatat panen atau penjualan.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }
            return _isArea
                ? _AreaChart(
                    points: pts,
                    hoveredIndex: _hoveredIndex,
                    tooltipPos: _tooltipPos,
                    onHover: (idx, pos) => setState(() { _hoveredIndex = idx; _tooltipPos = pos; }),
                  )
                : _BarChart(
                    points: pts,
                    hoveredIndex: _hoveredIndex,
                    tooltipPos: _tooltipPos,
                    onHover: (idx, pos) => setState(() { _hoveredIndex = idx; _tooltipPos = pos; }),
                  );
          }),
        ),

        const SizedBox(height: 12),

        // ── Legend ──────────────────────────────────────────────────────────
        Row(
          children: [
            legendDot(AppTheme.green700),
            const SizedBox(width: 6),
            const Text('Panen', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(width: 16),
            legendDot(const Color(0xFFE07C00)),
            const SizedBox(width: 6),
            const Text('Penjualan', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget legendDot(Color color) => Container(
    width: 12, height: 12,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ─── Toggle Buttons ────────────────────────────────────────────────────────────
class _ToggleButtons extends StatelessWidget {
  final bool isArea;
  final ValueChanged<bool> onToggle;
  const _ToggleButtons({required this.isArea, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn('Area', isArea,   () => onToggle(true)),
          btn('Bar',  !isArea,  () => onToggle(false)),
        ],
      ),
    );
  }

  Widget btn(String label, bool active, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.green700 : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Area Chart ───────────────────────────────────────────────────────────────
class _AreaChart extends StatelessWidget {
  final List<ChartDataPoint> points;
  final int? hoveredIndex;
  final Offset? tooltipPos;
  final void Function(int? idx, Offset? pos) onHover;

  const _AreaChart({
    required this.points,
    required this.hoveredIndex,
    required this.tooltipPos,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onExit: (_) => onHover(null, null),
      child: LayoutBuilder(builder: (context, bounds) {
        return GestureDetector(
          onTapDown: (d) => handlePointer(d.localPosition, bounds.maxWidth),
          child: Listener(
            onPointerMove: (e) => handlePointer(e.localPosition, bounds.maxWidth),
            onPointerHover: (e) => handlePointer(e.localPosition, bounds.maxWidth),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Chart canvas
                CustomPaint(
                  painter: _AreaPainter(
                    points: points,
                    hoveredIndex: hoveredIndex,
                  ),
                  size: Size.infinite,
                ),
                // Tooltip
                if (hoveredIndex != null && tooltipPos != null)
                  _Tooltip(
                    point: points[hoveredIndex!],
                    position: tooltipPos!,
                    maxWidth: bounds.maxWidth,
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void handlePointer(Offset pos, double width) {
    if (points.isEmpty) { onHover(null, null); return; }
    const double leftPad = 50;
    const double rightPad = 16;
    final count = points.length;
    final chartW = width - leftPad - rightPad;
    final xStep = chartW / (count > 1 ? count - 1 : 1);
    int closest = 0;
    double minDist = double.infinity;
    double closestX = leftPad;
    for (int i = 0; i < count; i++) {
      final x = leftPad + i * xStep;
      final dist = (pos.dx - x).abs();
      if (dist < minDist) { minDist = dist; closest = i; closestX = x; }
    }
    onHover(closest, Offset(closestX, pos.dy));
  }
}

// ─── Area Painter ──────────────────────────────────────────────────────────────
class _AreaPainter extends CustomPainter {
  final List<ChartDataPoint> points;
  final int? hoveredIndex;

  static const double leftPad  = 50;
  static const double rightPad = 16;
  static const double topPad   = 12;
  static const double botPad   = 24;

  const _AreaPainter({required this.points, this.hoveredIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - botPad;
    final count  = points.length;

    // ── Compute max value for Y scale ──────────────────────────────────────
    final allVals = [...points.map((p) => p.harvest), ...points.map((p) => p.sales)];
    final rawMax  = allVals.reduce(math.max);
    final yMax    = roundMax(rawMax);

    // ── Draw grid + Y labels ──────────────────────────────────────────────
    drawGrid(canvas, size, chartH, chartW, yMax);

    // ── Draw X labels ──────────────────────────────────────────────────────
    drawXLabels(canvas, size, chartW, count);

    // ── Draw filled areas ──────────────────────────────────────────────────
    drawFilledArea(canvas, size, chartH, chartW, count, yMax,
      points.map((p) => p.harvest).toList(), const Color(0xFF2D6A4F), const Color(0x152D6A4F));
    drawFilledArea(canvas, size, chartH, chartW, count, yMax,
      points.map((p) => p.sales).toList(), const Color(0xFFE07C00), const Color(0x15E07C00));

    // ── Draw lines ────────────────────────────────────────────────────────
    drawLine(canvas, size, chartH, chartW, count, yMax,
      points.map((p) => p.harvest).toList(), const Color(0xFF2D6A4F));
    drawLine(canvas, size, chartH, chartW, count, yMax,
      points.map((p) => p.sales).toList(), const Color(0xFFE07C00));
    drawDots(canvas, size, chartH, chartW, count, yMax);
  }

  double roundMax(double raw) {
    if (raw <= 0) return 100;
    final step = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    return (raw / step).ceil() * step * 1.15;
  }

  Offset pt(Size size, double chartH, double chartW, int i, int count, double val, double yMax) {
    final x = leftPad + (count > 1 ? i / (count - 1) : 0.5) * chartW;
    final y = topPad + chartH * (1 - val / yMax);
    return Offset(x, y);
  }

  void drawGrid(Canvas canvas, Size size, double chartH, double chartW, double yMax) {
    final dashPaint = Paint()
      ..color = const Color(0xFFDDE5E0)
      ..strokeWidth = 1;
    final steps = 4;
    final tp = TextPainter(textDirection: ui.TextDirection.ltr);

    for (int i = 0; i <= steps; i++) {
      final y = topPad + chartH * (1 - i / steps);
      final value = (yMax * i / steps).round();

      // Dashed line
      drawDashedLine(canvas, Offset(leftPad, y), Offset(size.width - rightPad, y), dashPaint);

      // Y-axis label
      tp.text = TextSpan(
        text: formatY(value),
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w400),
      );
      tp.layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 8, y - tp.height / 2));
    }
  }

  void drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLen = 4.0;
    const gapLen  = 4.0;
    final dx = end.dx - start.dx;
    final total = dx.abs();
    double drawn = 0;
    while (drawn < total) {
      final dEnd = math.min(drawn + dashLen, total);
      canvas.drawLine(
        Offset(start.dx + drawn, start.dy),
        Offset(start.dx + dEnd, start.dy),
        paint,
      );
      drawn = dEnd + gapLen;
    }
  }

  void drawXLabels(Canvas canvas, Size size, double chartW, int count) {
    final tp = TextPainter(textDirection: ui.TextDirection.ltr);
    for (int i = 0; i < count; i++) {
      final x = leftPad + (count > 1 ? i / (count - 1) : 0.5) * chartW;
      tp.text = TextSpan(
        text: points[i].label,
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - botPad + 6));
    }
  }

  void drawFilledArea(Canvas canvas, Size size, double chartH, double chartW,
      int count, double yMax, List<double> vals, Color lineColor, Color fillColor) {
    if (vals.isEmpty) return;
    final path = Path();
    final points2 = List.generate(count, (i) => pt(size, chartH, chartW, i, count, vals[i], yMax));

    path.moveTo(points2[0].dx, size.height - botPad);
    path.lineTo(points2[0].dx, points2[0].dy);
    addSmoothedPath(path, points2, moveTo: false);
    path.lineTo(points2.last.dx, size.height - botPad);
    path.close();

    // Gradient fill
    final rect = Rect.fromLTWH(0, topPad, size.width, chartH);
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [fillColor, fillColor.withValues(alpha: 0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);
  }

  void drawLine(Canvas canvas, Size size, double chartH, double chartW,
      int count, double yMax, List<double> vals, Color color) {
    if (vals.isEmpty) return;
    final pts = List.generate(count, (i) => pt(size, chartH, chartW, i, count, vals[i], yMax));
    final path = Path();
    path.moveTo(pts[0].dx, pts[0].dy);
    addSmoothedPath(path, pts, moveTo: false);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  void addSmoothedPath(Path path, List<Offset> pts, {required bool moveTo}) {
    if (pts.isEmpty) return;
    if (moveTo) path.moveTo(pts[0].dx, pts[0].dy);

    for (int i = 0; i < pts.length; i++) {
      if (i == 0 && !moveTo) continue;
      path.lineTo(pts[i].dx, pts[i].dy);
    }
  }

  void drawDots(Canvas canvas, Size size, double chartH, double chartW, int count, double yMax) {
    final harvestPts = List.generate(count, (i) =>
      pt(size, chartH, chartW, i, count, points[i].harvest, yMax));
    final salesPts = List.generate(count, (i) =>
      pt(size, chartH, chartW, i, count, points[i].sales, yMax));

    void dot(Offset p, Color color, {bool large = false}) {
      final r = large ? 5.5 : 4.0;
      canvas.drawCircle(p, r + 1.5, Paint()..color = Colors.white);
      canvas.drawCircle(p, r, Paint()..color = color);
    }

    for (int i = 0; i < count; i++) {
      final isHov = hoveredIndex == i;
      dot(harvestPts[i], const Color(0xFF2D6A4F), large: isHov);
      dot(salesPts[i],   const Color(0xFFE07C00), large: isHov);
    }
  }

  String formatY(int value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
    return value.toString();
  }

  @override
  bool shouldRepaint(_AreaPainter old) =>
    old.points != points || old.hoveredIndex != hoveredIndex;
}

// ─── Tooltip Overlay ──────────────────────────────────────────────────────────
class _Tooltip extends StatelessWidget {
  final ChartDataPoint point;
  final Offset position;
  final double maxWidth;

  const _Tooltip({
    required this.point,
    required this.position,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    const tooltipW = 185.0;
    const tooltipH = 78.0;
    const safeMargin = 28.0; // allow for box shadow and border space

    // Clamp tooltip position inside the widget width.
    final maxLeft = (maxWidth - tooltipW - safeMargin).clamp(0.0, double.infinity);
    double left = position.dx - tooltipW / 2;
    left = left.clamp(safeMargin, maxLeft);

    double top = position.dy - tooltipH - 16;
    if (top < 0) top = position.dy + 16;

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
            border: Border.all(color: const Color(0xFFE8EDE9)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(point.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF2D6A4F), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Panen: ${fmt(point.harvest)} kg${percent0(point.harvest, point.sales)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF2D6A4F), fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFE07C00), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Penjualan: ${fmt(point.sales)} kg${percent0(point.sales, point.harvest)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFE07C00), fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  String fmt(double v) {
    final i = v.round();
    return i.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }

  String percent0(double value, double other) {
    if (value == 0 && other == 0) return '';
    final total = value + other;
    if (total == 0) return '';
    final percent = (value / total) * 100;
    return ' (${percent.toStringAsFixed(1)}%)';
  }
}

// ─── Bar Chart ────────────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final List<ChartDataPoint> points;
  final int? hoveredIndex;
  final Offset? tooltipPos;
  final void Function(int? idx, Offset? pos) onHover;

  const _BarChart({
    required this.points,
    required this.hoveredIndex,
    required this.tooltipPos,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onExit: (_) => onHover(null, null),
      child: LayoutBuilder(builder: (context, bounds) {
        return GestureDetector(
          onTapDown: (d) => handlePointer(d.localPosition, bounds.maxWidth),
          child: Listener(
            onPointerMove: (e) => handlePointer(e.localPosition, bounds.maxWidth),
            onPointerHover: (e) => handlePointer(e.localPosition, bounds.maxWidth),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                SizedBox.expand(
                  child: CustomPaint(
                    painter: _BarPainter(points: points),
                  ),
                ),
                if (hoveredIndex != null && tooltipPos != null)
                  _Tooltip(point: points[hoveredIndex!], position: tooltipPos!, maxWidth: bounds.maxWidth),
              ],
            ),
          ),
        );
      }),
    );
  }

  void handlePointer(Offset pos, double width) {
    if (points.isEmpty) { onHover(null, null); return; }
    const leftPad = 50.0;
    const rightPad = 16.0;
    final chartW = width - leftPad - rightPad;
    final count = points.length;
    final slotW = chartW / count;

    int closest = 0;
    double minDist = double.infinity;
    double closestX = leftPad;
    for (int i = 0; i < count; i++) {
      final centerX = leftPad + slotW * i + slotW / 2;
      final dist = (pos.dx - centerX).abs();
      if (dist < minDist) { minDist = dist; closest = i; closestX = centerX; }
    }
    onHover(closest, Offset(closestX, pos.dy));
  }
}

class _BarPainter extends CustomPainter {
  final List<ChartDataPoint> points;
  static const double leftPad  = 50;
  static const double rightPad = 16;
  static const double topPad   = 12;
  static const double botPad   = 24;

  const _BarPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - botPad;
    final count  = points.length;

    final allVals = [...points.map((p) => p.harvest), ...points.map((p) => p.sales)];
    final rawMax  = allVals.reduce(math.max);
    final yMax    = roundMax(rawMax);

    final slotW = chartW / count;
    final barW = math.min(slotW * 0.34, 28.0);
    final gap = barW * 0.5;

    final gridP = Paint()..color = const Color(0xFFDDE5E0)..strokeWidth = 1;
    final tp = TextPainter(textDirection: ui.TextDirection.ltr);
    for (int i = 0; i <= 4; i++) {
      final y = topPad + chartH * (1 - i / 4);
      drawDash(canvas, Offset(leftPad, y), Offset(size.width - rightPad, y), gridP);
      final val = (yMax * i / 4).round();
      tp.text = TextSpan(text: fmtY(val), style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11));
      tp.layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 8, y - tp.height / 2));
    }

    for (int i = 0; i < count; i++) {
      final slotX = leftPad + i * slotW;
      final centerX = slotX + slotW / 2;

      final hH = yMax > 0 ? (points[i].harvest / yMax) * chartH : 4.0;
      drawBar(canvas, Offset(centerX - barW - gap / 2, topPad + chartH - hH), barW, hH,
        const Color(0xFF2D6A4F), const Color(0xFF52B788));

      final sH = yMax > 0 ? (points[i].sales / yMax) * chartH : 4.0;
      drawBar(canvas, Offset(centerX + gap / 2, topPad + chartH - sH), barW, sH,
        const Color(0xFFB45309), const Color(0xFFE07C00));

      tp.text = TextSpan(text: points[i].label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11));
      tp.layout();
      tp.paint(canvas, Offset(centerX - tp.width / 2, size.height - botPad + 6));
    }
  }

  void drawBar(Canvas canvas, Offset origin, double w, double h, Color dark, Color light) {
    final barHeight = h < 4 ? 4.0 : h;
    final rect = RRect.fromRectAndCorners(
      Rect.fromLTWH(origin.dx, origin.dy - (barHeight - h), w, barHeight),
      topLeft: const Radius.circular(5), topRight: const Radius.circular(5),
    );
    final paint = Paint()
      ..shader = LinearGradient(colors: [light, dark], begin: Alignment.topCenter, end: Alignment.bottomCenter)
          .createShader(rect.outerRect);
    canvas.drawRRect(rect, paint);
  }

  void drawDash(Canvas canvas, Offset s, Offset e, Paint paint) {
    const dl = 4.0, gl = 4.0;
    double d = 0;
    final total = (e.dx - s.dx).abs();
    while (d < total) {
      canvas.drawLine(Offset(s.dx + d, s.dy), Offset(s.dx + math.min(d + dl, total), s.dy), paint);
      d += dl + gl;
    }
  }

  double roundMax(double raw) {
    if (raw <= 0) return 100;
    final step = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    return (raw / step).ceil() * step * 1.15;
  }

  String fmtY(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k' : v.toString();

  @override
  bool shouldRepaint(_BarPainter old) => old.points != points;
}
