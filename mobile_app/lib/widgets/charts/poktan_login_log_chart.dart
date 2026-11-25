import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../app_theme.dart';

class LoginDailyPoint {
  final String date;
  final String label;
  final int count;

  const LoginDailyPoint({
    required this.date,
    required this.label,
    required this.count,
  });

  factory LoginDailyPoint.fromJson(Map<String, dynamic> json) {
    return LoginDailyPoint(
      date: json['date'] as String? ?? '',
      label: json['label'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class LoginLocationSummary {
  final String location;
  final int count;

  const LoginLocationSummary({
    required this.location,
    required this.count,
  });

  factory LoginLocationSummary.fromJson(Map<String, dynamic> json) {
    return LoginLocationSummary(
      location: json['location'] as String? ?? 'Tidak Diketahui',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class PoktanLoginLogEntry {
  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final String farmName;
  final String farmerGroupName;
  final String loginMethod;
  final String? ipAddress;
  final String location;
  final String loggedInAt;
  final String loggedInAtFormatted;

  const PoktanLoginLogEntry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.farmName,
    required this.farmerGroupName,
    required this.loginMethod,
    this.ipAddress,
    required this.location,
    required this.loggedInAt,
    required this.loggedInAtFormatted,
  });

  factory PoktanLoginLogEntry.fromJson(Map<String, dynamic> json) {
    return PoktanLoginLogEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      userName: json['user_name'] as String? ?? '-',
      userEmail: json['user_email'] as String? ?? '-',
      farmName: json['farm_name'] as String? ?? '-',
      farmerGroupName: json['farmer_group_name'] as String? ?? '-',
      loginMethod: json['login_method'] as String? ?? 'password',
      ipAddress: json['ip_address'] as String?,
      location: json['location'] as String? ?? 'Tidak Diketahui',
      loggedInAt: json['logged_in_at'] as String? ?? '',
      loggedInAtFormatted: json['logged_in_at_formatted'] as String? ?? '-',
    );
  }
}

class PoktanLoginLogChart extends StatefulWidget {
  final List<LoginDailyPoint> dailyCounts;
  final List<LoginLocationSummary> locationSummary;
  final List<PoktanLoginLogEntry> logs;
  final int totalLogins;
  final int uniqueUsers;
  final String selectedPeriod;
  final String startDate;
  final String endDate;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<String> onPeriodChanged;

  const PoktanLoginLogChart({
    super.key,
    required this.dailyCounts,
    required this.locationSummary,
    required this.logs,
    required this.totalLogins,
    required this.uniqueUsers,
    required this.selectedPeriod,
    required this.startDate,
    required this.endDate,
    required this.isLoading,
    this.errorMessage,
    required this.onPeriodChanged,
  });

  @override
  State<PoktanLoginLogChart> createState() => _PoktanLoginLogChartState();
}

class _PoktanLoginLogChartState extends State<PoktanLoginLogChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final points = widget.dailyCounts;
    final int maxVal = points.isEmpty
        ? 5
        : points.map((p) => p.count).reduce(math.max);
    final double safeMax = maxVal <= 0 ? 5.0 : maxVal.toDouble();

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
          // Header Card + Period Filter
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.purple100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.login_rounded,
                      color: AppTheme.purple600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aktivitas Login User Poktan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dark900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.startDate.isNotEmpty && widget.endDate.isNotEmpty
                            ? 'Periode ${widget.startDate} s/d ${widget.endDate}'
                            : 'Statistik jumlah login, lokasi, dan waktu akses',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatPill(
                    icon: Icons.bar_chart_rounded,
                    label: '${widget.totalLogins} Login',
                    bg: AppTheme.purple100,
                    fg: AppTheme.purple600,
                  ),
                  const SizedBox(width: 8),
                  _buildStatPill(
                    icon: Icons.people_alt_outlined,
                    label: '${widget.uniqueUsers} Poktan',
                    bg: AppTheme.green100,
                    fg: AppTheme.green700,
                  ),
                  const SizedBox(width: 10),
                  _buildPeriodSelector(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart Body
          if (widget.isLoading)
            const SizedBox(
              height: 190,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (widget.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.errorMessage!,
                      style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else if (points.isEmpty)
            const SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  'Belum ada data login user Poktan pada periode ini.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
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
                    child: GestureDetector(
                      onTapDown: (details) {
                        final widthPerBar = constraints.maxWidth / (points.isEmpty ? 1 : points.length);
                        final idx = (details.localPosition.dx / widthPerBar).floor().clamp(0, points.length - 1);
                        setState(() => _hoveredIndex = (_hoveredIndex == idx) ? null : idx);
                      },
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, 190),
                        painter: _LoginBarChartPainter(
                          points: points,
                          maxValue: safeMax,
                          hoveredIndex: _hoveredIndex,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Location Summary Chips
          if (!widget.isLoading && widget.locationSummary.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 14),
            const Text(
              'Lokasi Login Terbanyak',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.dark900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.locationSummary.map((loc) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.purple600),
                      const SizedBox(width: 4),
                      Text(
                        loc.location,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.dark900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.purple100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${loc.count}x',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.purple600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // Recent Login Logs Table/List
          if (!widget.isLoading) ...[
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Log Login Terbaru',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark900,
                  ),
                ),
                Text(
                  'Menampilkan ${widget.logs.length} log',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (widget.logs.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Belum ada riwayat login user Poktan pada kurun waktu ini.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.logs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final log = widget.logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.green100,
                            child: Text(
                              log.userName.isNotEmpty ? log.userName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: AppTheme.green700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.userName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.dark900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  log.farmerGroupName != '-'
                                      ? '${log.farmerGroupName} • ${log.farmName}'
                                      : log.farmName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.purple600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    log.location,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.dark900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                log.loggedInAtFormatted,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.dark900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: log.loginMethod == 'google'
                                      ? AppTheme.blue100
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  log.loginMethod == 'google' ? 'Google' : 'Password',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: log.loginMethod == 'google'
                                        ? AppTheme.blue600
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    const periods = [
      ('7d', '7 Hari'),
      ('30d', '30 Hari'),
      ('90d', '90 Hari'),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: periods.map((p) {
          final isSelected = widget.selectedPeriod == p.$1;
          return GestureDetector(
            onTap: () => widget.onPeriodChanged(p.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1))]
                    : null,
              ),
              child: Text(
                p.$2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppTheme.purple600 : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LoginBarChartPainter extends CustomPainter {
  final List<LoginDailyPoint> points;
  final double maxValue;
  final int? hoveredIndex;

  _LoginBarChartPainter({
    required this.points,
    required this.maxValue,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double bottomLabelHeight = 26;
    const double topPadding = 24;
    final double chartHeight = size.height - bottomLabelHeight - topPadding;

    // Grid lines (4 levels)
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + chartHeight * (1 - i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;

    final int count = points.length;
    final double slotWidth = size.width / count;
    final double barWidth = math.min(26.0, math.max(3.0, slotWidth * 0.62));
    // Show at most ~8 x-axis labels so they don't overlap on 30d/90d
    final int labelStep = math.max(1, (count / 7).ceil());

    for (int i = 0; i < count; i++) {
      final point = points[i];
      final double xCenter = i * slotWidth + slotWidth / 2;
      final double barHeight = (point.count / maxValue) * chartHeight;
      final double barTop = topPadding + chartHeight - barHeight;
      final bool isHovered = hoveredIndex == i;

      final Rect barRect = Rect.fromLTWH(
        xCenter - barWidth / 2,
        barTop,
        barWidth,
        math.max(barHeight, point.count > 0 ? 4 : 0),
      );

      final RRect rRect = RRect.fromRectAndCorners(
        barRect,
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );

      final Paint barPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(xCenter, barTop),
          Offset(xCenter, topPadding + chartHeight),
          isHovered
              ? [const Color(0xFF7C3AED), const Color(0xFF9333EA)]
              : [const Color(0xFF9333EA), const Color(0xFFA855F7)],
        );

      if (point.count > 0) {
        canvas.drawRRect(rRect, barPaint);
      } else {
        canvas.drawRect(
          Rect.fromLTWH(xCenter - barWidth / 2, topPadding + chartHeight - 2, barWidth, 2),
          Paint()..color = const Color(0xFFE2E8F0),
        );
      }

      // Hover tooltip
      if (isHovered) {
        final String tooltipText = '${point.label}: ${point.count} login';
        final tp = TextPainter(
          text: TextSpan(
            text: tooltipText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final double boxW = tp.width + 14;
        final double boxH = tp.height + 8;
        final double boxX = (xCenter - boxW / 2).clamp(0.0, size.width - boxW);
        final double boxY = math.max(0.0, barTop - boxH - 6);

        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(boxX, boxY, boxW, boxH), const Radius.circular(6)),
          Paint()..color = AppTheme.dark900,
        );
        tp.paint(canvas, Offset(boxX + 7, boxY + 4));
      }

      // X-axis label (stepped to avoid crowding)
      if (i % labelStep == 0 || i == count - 1) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: point.label,
            style: TextStyle(
              color: isHovered ? AppTheme.purple600 : AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: isHovered ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final double lx = (xCenter - labelPainter.width / 2).clamp(0.0, size.width - labelPainter.width);
        labelPainter.paint(canvas, Offset(lx, topPadding + chartHeight + 8));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LoginBarChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}
