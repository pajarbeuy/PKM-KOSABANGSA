import 'package:flutter/material.dart';
import '../landing_animations.dart';

class LandingWorkflowSection extends StatelessWidget {
  final bool isDesktop;

  const LandingWorkflowSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'num': '01',
        'emoji': '👤',
        'title': 'Daftar & Masuk',
        'desc': 'Buat akun gratis dalam hitungan menit.'
      },
      {
        'num': '02',
        'emoji': '📅',
        'title': 'Atur Musim Tanam',
        'desc': 'Tentukan periode dan blok kebun Anda.'
      },
      {
        'num': '03',
        'emoji': '✏️',
        'title': 'Catat Aktivitas',
        'desc': 'Rekam panen, transaksi, dan pengeluaran.'
      },
      {
        'num': '04',
        'emoji': '📈',
        'title': 'Analisis & Tumbuh',
        'desc': 'Gunakan laporan untuk keputusan lebih cerdas.'
      },
    ];

    return FadeSlideOnScroll(
      child: Container(
        width: double.infinity,
        color: const Color(0xFF1E3A2A),
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF52B788).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF52B788).withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Text(
                    'Cara Kerja',
                    style: TextStyle(
                      color: Color(0xFF74C69D),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mulai dalam 4 Langkah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    color: Color(0xFFD4E8D0),
                  ),
                ),
                const SizedBox(height: 56),

                // Steps Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 4 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: isDesktop ? 1.0 : 1.25,
                  ),
                  itemCount: steps.length,
                  itemBuilder: (context, index) {
                    final s = steps[index];
                    return FadeSlideOnScroll(
                      delay: Duration(milliseconds: 100 * index),
                      child: HoverCard(
                        child: StepCard(
                          num: s['num']!,
                          emoji: s['emoji']!,
                          title: s['title']!,
                          desc: s['desc']!,
                          showNextArrow: index < steps.length - 1,
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

class StepCard extends StatelessWidget {
  final String num;
  final String emoji;
  final String title;
  final String desc;
  final bool showNextArrow;

  const StepCard({
    super.key,
    required this.num,
    required this.emoji,
    required this.title,
    required this.desc,
    required this.showNextArrow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -32,
            width: 96,
            height: 96,
            child: Opacity(
              opacity: 0.2,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF52B788), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF52B788), Color(0xFF74C69D)],
                    ).createShader(bounds),
                    child: Text(
                      num,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 44.8,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFD4E8D0),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13.6,
                    color: const Color(0xFFD4E8D0).withValues(alpha: 0.6),
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
