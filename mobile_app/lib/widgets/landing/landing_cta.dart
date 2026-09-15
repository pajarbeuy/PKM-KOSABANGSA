import 'package:flutter/material.dart';
import '../landing_animations.dart';

class LandingCtaSection extends StatelessWidget {
  final VoidCallback onRegisterTap;
  final VoidCallback onLoginTap;

  const LandingCtaSection({
    super.key,
    required this.onRegisterTap,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1A3428),
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const Text(
                '🌿',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Siap Kelola Pertanian\nLebih Cerdas?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 28.8,
                  color: Color(0xFFD4E8D0),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bergabunglah dengan 1.200+ petani yang sudah menggunakan SIMHPSK dan rasakan perbedaannya.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xB2D4E8D0),
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 40),

              // Buttons
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  HoverButton(
                    onPressed: onRegisterTap,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shadowColor: const Color(0xFF52B788).withValues(alpha: 0.35),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: onRegisterTap,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Daftar Sekarang — Gratis',
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
                        foregroundColor: const Color(0xFFD4E8D0),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: onLoginTap,
                      child: const Text(
                        'Sudah punya akun? Masuk',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Trust points
              Wrap(
                spacing: 20,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: const [
                  CtaTrustPoint(text: 'Tanpa kartu kredit'),
                  CtaTrustPoint(text: 'Setup 5 menit'),
                  CtaTrustPoint(text: 'Support 7 hari'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CtaTrustPoint extends StatelessWidget {
  final String text;

  const CtaTrustPoint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF52B788),
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13.6,
            color: const Color(0xFFD4E8D0).withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
