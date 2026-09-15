import 'package:flutter/material.dart';
import '../landing_animations.dart';

class LandingFeaturesSection extends StatelessWidget {
  final bool isDesktop;
  final Map<String, String> landingContent;

  const LandingFeaturesSection({
    super.key,
    required this.isDesktop,
    required this.landingContent,
  });

  String _landingValue(String key, String fallback) {
    return landingContent[key] ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'title': _landingValue('feature_1_title', 'Pencatatan Panen'),
        'desc': _landingValue('feature_1_desc', 'Catat setiap hasil panen lengkap dengan foto, berat, dan keterangan blok kebun.'),
        'emoji': '🌾',
        'color': const Color(0xFF2D6A4F),
        'bg': const Color(0xFFE8F2EC)
      },
      {
        'title': _landingValue('feature_2_title', 'Manajemen Stok'),
        'desc': _landingValue('feature_2_desc', 'Pantau stok gudang secara real-time dengan notifikasi batas minimum otomatis.'),
        'emoji': '📦',
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFEF3C7)
      },
      {
        'title': _landingValue('feature_3_title', 'Laporan Keuangan'),
        'desc': _landingValue('feature_3_desc', 'Hitung pendapatan, biaya produksi, dan estimasi untung-rugi per musim tanam.'),
        'emoji': '💰',
        'color': const Color(0xFF1E40AF),
        'bg': const Color(0xFFDBEAFE)
      },
      {
        'title': _landingValue('feature_4_title', 'Manajemen Penjualan'),
        'desc': _landingValue('feature_4_desc', 'Kelola transaksi penjualan dan data pembeli dalam satu platform terpadu.'),
        'emoji': '🛒',
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFEDE9FE)
      },
      {
        'title': _landingValue('feature_5_title', 'Analitik & Grafik'),
        'desc': _landingValue('feature_5_desc', 'Visualisasi data panen dan penjualan dengan grafik interaktif yang mudah dipahami.'),
        'emoji': '📊',
        'color': const Color(0xFF0E7490),
        'bg': const Color(0xFFCFFAFE)
      },
      {
        'title': _landingValue('feature_6_title', 'Musim Tanam'),
        'desc': _landingValue('feature_6_desc', 'Atur dan pantau setiap periode musim tanam dengan riwayat lengkap.'),
        'emoji': '🌱',
        'color': const Color(0xFF166534),
        'bg': const Color(0xFFDCFCE7)
      },
    ];

    return FadeSlideOnScroll(
      child: Container(
        width: double.infinity,
        color: const Color(0xFFF2EDE3),
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F2EC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2D6A4F).withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Text(
                    '🌿 Fitur Lengkap',
                    style: TextStyle(
                      color: Color(0xFF2D6A4F),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Semua yang Anda Butuhkan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    color: Color(0xFF1A3428),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Dari pencatatan panen hingga laporan keuangan, SIMHPSK menyediakan semua alat untuk petani modern.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 56),

                // Grid/Column list
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: isDesktop ? 1.4 : 1.5,
                  ),
                  itemCount: features.length,
                  itemBuilder: (context, index) {
                    final f = features[index];
                    return FadeSlideOnScroll(
                      delay: Duration(milliseconds: 100 * index),
                      child: HoverCard(
                        child: FeatureCard(
                          emoji: f['emoji'] as String,
                          title: f['title'] as String,
                          desc: f['desc'] as String,
                          color: f['color'] as Color,
                          bg: f['bg'] as Color,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  final Color color;
  final Color bg;

  const FeatureCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.desc,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2C2314).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C2314).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.4,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [color, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A3428),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              desc,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
