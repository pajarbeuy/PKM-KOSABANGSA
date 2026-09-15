import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Reusable statistics card — matches Figma stat card design.
/// Shows icon, value, label, optional badge and optional progress bar.
class StatCard extends StatefulWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String? badgeLabel;
  final Color? badgeBg;
  final Color? badgeTextColor;
  final IconData? badgeIcon;
  final String? subLabel;
  final double? progressValue;     // 0.0 - 1.0
  final Color? progressColor;
  final String? progressMin;
  final String? progressMax;
  final Color? valueColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    this.badgeLabel,
    this.badgeBg,
    this.badgeTextColor,
    this.badgeIcon,
    this.subLabel,
    this.progressValue,
    this.progressColor,
    this.progressMin,
    this.progressMax,
    this.valueColor,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;
  late Animation<double> _elevAnim;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), lowerBound: 0, upperBound: 1);
    _elevAnim = _hoverCtrl;
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => _hoverCtrl.forward(),
      onExit:  (_) => _hoverCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _elevAnim,
        builder: (_, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: AppTheme.card,
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05 + _elevAnim.value * 0.05),
                  blurRadius: 12 + _elevAnim.value * 8,
                  offset: Offset(0, 4 + _elevAnim.value * 4),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon + optional badge row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: widget.iconBg, borderRadius: AppTheme.tag),
                  child: Icon(widget.icon, color: widget.iconColor, size: 22),
                ),
                if (widget.badgeLabel != null)
                  _Badge(
                    label: widget.badgeLabel!,
                    bg: widget.badgeBg ?? AppTheme.green100,
                    textColor: widget.badgeTextColor ?? AppTheme.green700,
                    icon: widget.badgeIcon,
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Label
            Text(widget.label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),

            // Value
            Text(
              widget.value,
              style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800,
                color: widget.valueColor ?? AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),

            // Sub label
            if (widget.subLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.subLabel!,
                style: AppTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Progress bar
            if (widget.progressValue != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.progressValue!.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppTheme.cardBorder,
                  color: widget.progressColor ?? AppTheme.green500,
                ),
              ),
              if (widget.progressMin != null || widget.progressMax != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.progressMin ?? '', style: AppTheme.caption),
                      Text(widget.progressMax ?? '', style: AppTheme.caption),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  final IconData? icon;

  const _Badge({required this.label, required this.bg, required this.textColor, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppTheme.chip),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 3),
          ],
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }
}
