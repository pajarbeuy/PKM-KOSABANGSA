import 'package:flutter/material.dart';
import '../landing_animations.dart';

class LandingTestimonialsSection extends StatelessWidget {
  final bool isDesktop;

  const LandingTestimonialsSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final testimonials = [
      {
        'nama': 'Pak Hendra Wijaya',
        'lokasi': 'Wonosobo',
        'bintang': 5,
        'komentar': 'Aplikasi ini luar biasa mudah digunakan! Sekarang saya bisa pantau stok dan untung-rugi dengan mudah dari HP.',
        'avatar': '👨‍🌾'
      },
      {
        'nama': 'Bu Sari Dewi',
        'lokasi': 'Dieng, Jawa Tengah',
        'bintang': 5,
        'komentar': 'Sangat membantu untuk mencatat hasil panen. Tulisannya besar dan jelas, cocok untuk saya yang sudah tua.',
        'avatar': '👩‍🌾'
      },
      {
        'nama': 'Pak Bambang Susilo',
        'lokasi': 'Magelang',
        'bintang': 5,
        'komentar': 'Laporan keuangannya sangat detail. Saya jadi tahu persis berapa untung setiap musim panen.',
        'avatar': '🧑‍🌾'
      }
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFFF2EDE3),
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
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF92400E).withValues(alpha: 0.2),
                  ),
                ),
                child: const Text(
                  '⭐ Ulasan Pengguna',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kata Mereka',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  color: Color(0xFF1A3428),
                ),
              ),
              const SizedBox(height: 56),

              // Testimonial Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 1,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: isDesktop ? 1.3 : 1.8,
                ),
                itemCount: testimonials.length,
                itemBuilder: (context, index) {
                  final t = testimonials[index];
                  return FadeSlideOnScroll(
                    delay: Duration(milliseconds: 120 * index),
                    child: HoverCard(
                      child: TestimonialCard(
                        name: t['nama'] as String,
                        location: t['lokasi'] as String,
                        stars: t['bintang'] as int,
                        comment: t['komentar'] as String,
                        avatar: t['avatar'] as String,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TestimonialCard extends StatelessWidget {
  final String name;
  final String location;
  final int stars;
  final String comment;
  final String avatar;

  const TestimonialCard({
    super.key,
    required this.name,
    required this.location,
    required this.stars,
    required this.comment,
    required this.avatar,
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
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            width: 112,
            height: 112,
            child: Opacity(
              opacity: 0.1,
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
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    stars,
                    (index) => const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFD97706),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    '"$comment"',
                    style: const TextStyle(
                      fontSize: 14.7,
                      color: Color(0xFF374151),
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: const Color(0xFF2C2314).withValues(alpha: 0.07),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F2EC),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        avatar,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            fontSize: 14.4,
                            color: Color(0xFF1A3428),
                          ),
                        ),
                        Text(
                          '📍 $location',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B6050),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
