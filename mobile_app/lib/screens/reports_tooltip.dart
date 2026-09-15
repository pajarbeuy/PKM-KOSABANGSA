import 'package:flutter/material.dart';
import '../widgets/app_theme.dart';
import '../models/monthly_data.dart';

class MonthlyTrendTooltip extends StatelessWidget {
  final MonthlyData data;
  final Offset position;
  final double maxWidth;

  const MonthlyTrendTooltip({super.key, 
    required this.data,
    required this.position,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    const tooltipW = 180.0;
    const tooltipH = 88.0;
    const margin = 16.0;

    final left = position.dx - tooltipW / 2;
    final clampedLeft = left.clamp(margin, (maxWidth - tooltipW - margin).clamp(0.0, double.infinity));
    final top = position.dy - tooltipH - 16;
    final correctedTop = top < 0 ? position.dy + 16 : top;

    return Positioned(
      left: clampedLeft,
      top: correctedTop,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: tooltipW,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(data.label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Pendapatan: ${_formatMoney(data.revenue)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF87171), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Biaya: ${_formatMoney(data.cost)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMoney(double value) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  }
}
