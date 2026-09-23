import 'package:flutter/material.dart';
import '../landing_animations.dart';

class WaveUnderlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF52B788)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, 4)
      ..cubicTo(25, 0, 50, 8, 75, 4)
      ..cubicTo(100, 0, 125, 8, 150, 4)
      ..cubicTo(175, 0, 200, 8, 220, 4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LandingHeroSection extends StatelessWidget {
  final bool isDesktop;
  final String heroTitle;
  final String heroTitleEmphasis;
  final String heroDescription;
  final VoidCallback onStartFreeTap;
  final VoidCallback onLoginTap;

  const LandingHeroSection({
    super.key,
    required this.isDesktop,
    required this.heroTitle,
    required this.heroTitleEmphasis,
    required this.heroDescription,
    required this.onStartFreeTap,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48.0 : 20.0,
        vertical: 48.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // Badge
              FadeSlideOnScroll(
                delay: Duration.zero,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0x40166534),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D6A4F).withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D6A4F),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Platform Manajemen Pertanian Digital #1',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              FadeSlideOnScroll(
                delay: const Duration(milliseconds: 100),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 42.0,
                      color: Color(0xFF1A3428),
                      height: 1.1,
                      letterSpacing: -1.0,
                    ),
                    children: [
                      TextSpan(text: '$heroTitle '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              heroTitleEmphasis,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w900,
                                fontSize: 42.0,
                                color: Color(0xFF2D6A4F),
                                letterSpacing: -1.0,
                              ),
                            ),
                            CustomPaint(
                              size: const Size(220, 8),
                              painter: WaveUnderlinePainter(),
                            ),
                          ],
                        ),
                      ),
                      const TextSpan(text: '\nLebih '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
                          ).createShader(bounds),
                          child: const Text(
                            'Cerdas',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w900,
                              fontSize: 42.0,
                              color: Colors.white,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Subtitle
              FadeSlideOnScroll(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  heroDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF374151),
                    height: 1.75,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // CTA buttons
              FadeSlideOnScroll(
                delay: const Duration(milliseconds: 300),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    HoverButton(
                      onPressed: onStartFreeTap,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          shadowColor: const Color(0xFF2D6A4F).withValues(alpha: 0.35),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: onStartFreeTap,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Mulai Sekarang — Gratis',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                    HoverButton(
                      onPressed: onLoginTap,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          side: const BorderSide(color: Color(0x262C2314), width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          backgroundColor: Colors.white.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: onLoginTap,
                        child: const Text(
                          'Masuk ke Akun',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Trust Indicators
              FadeSlideOnScroll(
                delay: const Duration(milliseconds: 400),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: const [
                    TrustItem(emoji: '✅', text: 'Tidak perlu kartu kredit'),
                    TrustItem(emoji: '🆓', text: 'Gratis selamanya'),
                    TrustItem(emoji: '🔒', text: 'Data aman & terenkripsi'),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Mockup Dashboard Illustration
              FadeSlideOnScroll(
                delay: const Duration(milliseconds: 500),
                child: HoverCard(
                  borderRadius: BorderRadius.circular(24),
                  child: MockupDashboard(isDesktop: isDesktop),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrustItem extends StatelessWidget {
  final String emoji;
  final String text;

  const TrustItem({super.key, required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B6050),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class MockupDashboard extends StatelessWidget {
  final bool isDesktop;

  const MockupDashboard({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C2314).withValues(alpha: 0.22),
            blurRadius: 100,
            offset: const Offset(0, 40),
          ),
          BoxShadow(
            color: const Color(0xFF2C2314).withValues(alpha: 0.1),
            blurRadius: 1,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Browser header bar
          Container(
            color: const Color(0xFF1A3428),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Row(
                  children: [
                    _buildDot(const Color(0xFFC0392B)),
                    const SizedBox(width: 6),
                    _buildDot(const Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    _buildDot(const Color(0xFF52B788)),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'sumbertani.app/dashboard',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Browser Body
          Container(
            color: const Color(0xFFF2EDE3),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A3428), Color(0xFF2D6A4F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -40,
                        width: 120,
                        height: 120,
                        child: Opacity(
                          opacity: 0.2,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [Color(0xFF74C69D), Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        top: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat datang 👋',
                              style: TextStyle(
                                color: const Color(0xFFD4E8D0).withValues(alpha: 0.7),
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Petani Mitra — Musim 1 · 2026',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Stats row
                isDesktop
                    ? Row(
                        children: const [
                          Expanded(child: MockStatCard(label: 'Stok Gudang', value: '4.500 kg', textCol: Color(0xFFD97706), bgCol: Color(0xFFFEF3C7))),
                          SizedBox(width: 10),
                          Expanded(child: MockStatCard(label: 'Total Panen', value: '12.400 kg', textCol: Color(0xFF166534), bgCol: Color(0xFFDCFCE7))),
                          SizedBox(width: 10),
                          Expanded(child: MockStatCard(label: 'Pendapatan', value: 'Rp 74,4 jt', textCol: Color(0xFF1E40AF), bgCol: Color(0xFFDBEAFE))),
                          SizedBox(width: 10),
                          Expanded(child: MockStatCard(label: 'Est. Untung', value: 'Rp 28,6 jt', textCol: Color(0xFF2D6A4F), bgCol: Color(0xFFE8F2EC))),
                        ],
                      )
                    : Column(
                        children: const [
                          Row(
                            children: [
                              Expanded(child: MockStatCard(label: 'Stok Gudang', value: '4.500 kg', textCol: Color(0xFFD97706), bgCol: Color(0xFFFEF3C7))),
                              SizedBox(width: 10),
                              Expanded(child: MockStatCard(label: 'Total Panen', value: '12.400 kg', textCol: Color(0xFF166534), bgCol: Color(0xFFDCFCE7))),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: MockStatCard(label: 'Pendapatan', value: 'Rp 74,4 jt', textCol: Color(0xFF1E40AF), bgCol: Color(0xFFDBEAFE))),
                              SizedBox(width: 10),
                              Expanded(child: MockStatCard(label: 'Est. Untung', value: 'Rp 28,6 jt', textCol: Color(0xFF2D6A4F), bgCol: Color(0xFFE8F2EC))),
                            ],
                          ),
                        ],
                      ),
                const SizedBox(height: 10),

                // Chart card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2C2314).withValues(alpha: 0.08),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Grafik Panen & Penjualan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3428),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(
                        height: 56,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            MockChartBar(heightFactor: 0.6, isGreen: true),
                            MockChartBar(heightFactor: 0.8, isGreen: false),
                            MockChartBar(heightFactor: 0.45, isGreen: true),
                            MockChartBar(heightFactor: 0.9, isGreen: false),
                            MockChartBar(heightFactor: 0.7, isGreen: true),
                            MockChartBar(heightFactor: 1.0, isGreen: false),
                            MockChartBar(heightFactor: 0.75, isGreen: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('Jan', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.6, color: Color(0xFF6B6050)))),
                          Expanded(child: Text('Feb', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.6, color: Color(0xFF6B6050)))),
                          Expanded(child: Text('Mar', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.6, color: Color(0xFF6B6050)))),
                          Expanded(child: Text('Apr', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.6, color: Color(0xFF6B6050)))),
                          Expanded(child: Text('Mei', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.6, color: Color(0xFF6B6050)))),
                          Expanded(child: Text('Jun', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.6, color: Color(0xFF6B6050)))),
                          Expanded(child: Text('Jul', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.6, color: Color(0xFF6B6050)))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class MockStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color textCol;
  final Color bgCol;

  const MockStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.textCol,
    required this.bgCol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF6B6050),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 15.2,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }
}

class MockChartBar extends StatelessWidget {
  final double heightFactor;
  final bool isGreen;

  const MockChartBar({
    super.key,
    required this.heightFactor,
    required this.isGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: FractionallySizedBox(
          heightFactor: heightFactor,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              gradient: LinearGradient(
                colors: isGreen
                    ? [const Color(0xFF2D6A4F), const Color(0xFF52B788)]
                    : [const Color(0xFFD97706), const Color(0xFFF5A623)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
