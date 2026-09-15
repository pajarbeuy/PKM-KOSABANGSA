import 'package:flutter/material.dart';
import '../landing_animations.dart';

class LandingStatsSection extends StatelessWidget {
  final bool isDesktop;
  final bool hasStatSectionEntered;

  const LandingStatsSection({
    super.key,
    required this.isDesktop,
    required this.hasStatSectionEntered,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideOnScroll(
      child: Container(
        width: double.infinity,
        color: const Color(0xFF1A3428),
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                const Text(
                  'Dipercaya Petani di Seluruh Indonesia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: Color(0xFFD4E8D0),
                  ),
                ),
                const SizedBox(height: 40),
                isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(child: _buildStatItem(1200, '+', 'Petani Aktif', Icons.people_alt_rounded, delay: 0)),
                          Expanded(child: _buildStatItem(98, '%', 'Kepuasan Pengguna', Icons.star_rounded, delay: 100)),
                          Expanded(child: _buildStatItem(45, ' jt', 'Transaksi Tercatat', Icons.trending_up_rounded, delay: 200)),
                          Expanded(child: _buildStatItem(100, '%', 'Aman & Terenkripsi', Icons.shield_rounded, delay: 300)),
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildStatItem(1200, '+', 'Petani Aktif', Icons.people_alt_rounded, delay: 0)),
                              Expanded(child: _buildStatItem(98, '%', 'Kepuasan', Icons.star_rounded, delay: 100)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _buildStatItem(45, ' jt', 'Transaksi', Icons.trending_up_rounded, delay: 200)),
                              Expanded(child: _buildStatItem(100, '%', 'Aman', Icons.shield_rounded, delay: 300)),
                            ],
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(int targetVal, String suffix, String label, IconData icon, {int delay = 0}) {
    return FadeSlideOnScroll(
      delay: Duration(milliseconds: delay),
      child: Column(
        children: [
          ScaleFadeOnScroll(
            duration: const Duration(milliseconds: 500),
            startScale: 0.9,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF52B788).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFF52B788), size: 24),
            ),
          ),
          const SizedBox(height: 12),
          CountUpText(
            targetValue: targetVal,
            suffix: suffix,
            duration: const Duration(milliseconds: 2000),
            delay: Duration(milliseconds: delay + 300),
            start: hasStatSectionEntered,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 32,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xB2D4E8D0),
              fontSize: 13.1,
            ),
          ),
        ],
      ),
    );
  }
}
