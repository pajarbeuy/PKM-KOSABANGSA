import 'package:flutter/material.dart';
import '../landing_animations.dart';

class LandingNavbar extends StatelessWidget {
  final bool isDesktop;
  final bool isScrolled;
  final bool isMobileMenuOpen;
  final VoidCallback onLogoTap;
  final VoidCallback onFiturTap;
  final VoidCallback onStatistikTap;
  final VoidCallback onCaraKerjaTap;
  final VoidCallback onUlasanTap;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;
  final VoidCallback onToggleMobileMenu;

  const LandingNavbar({
    super.key,
    required this.isDesktop,
    required this.isScrolled,
    required this.isMobileMenuOpen,
    required this.onLogoTap,
    required this.onFiturTap,
    required this.onStatistikTap,
    required this.onCaraKerjaTap,
    required this.onUlasanTap,
    required this.onLoginTap,
    required this.onRegisterTap,
    required this.onToggleMobileMenu,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 70,
      decoration: BoxDecoration(
        color: isScrolled ? Colors.white.withValues(alpha: 0.95) : Colors.transparent,
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: const Color(0xFF2C2314).withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
        border: isScrolled
            ? const Border(
                bottom: BorderSide(
                  color: Color(0x1A2C2314),
                  width: 1.0,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              GestureDetector(
                onTap: onLogoTap,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.agriculture_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SumberTani',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: Color(0xFF1A3428),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -2),
                          child: const Text(
                            'PENCATATAN PERTANIAN',
                            style: TextStyle(
                              color: Color(0xFF6B6050),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Navigation Links (Desktop)
              if (isDesktop)
                Row(
                  children: [
                    _buildNavLink('Fitur', onFiturTap),
                    const SizedBox(width: 28),
                    _buildNavLink('Statistik', onStatistikTap),
                    const SizedBox(width: 28),
                    _buildNavLink('Cara Kerja', onCaraKerjaTap),
                    const SizedBox(width: 28),
                    _buildNavLink('Ulasan', onUlasanTap),
                  ],
                ),

              // Actions (Desktop)
              if (isDesktop)
                Row(
                  children: [
                    HoverButton(
                      onPressed: onLoginTap,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onLoginTap,
                        child: const Text(
                          'Masuk',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    HoverButton(
                      onPressed: onRegisterTap,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F),
                          foregroundColor: Colors.white,
                          shadowColor: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onRegisterTap,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Mulai Gratis',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              // Hamburger Menu Button (Mobile)
              if (!isDesktop)
                IconButton(
                  icon: Icon(
                    isMobileMenuOpen ? Icons.close : Icons.menu,
                    color: const Color(0xFF374151),
                  ),
                  onPressed: onToggleMobileMenu,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF374151),
          fontSize: 14.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class LandingMobileMenuOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onFiturTap;
  final VoidCallback onStatistikTap;
  final VoidCallback onCaraKerjaTap;
  final VoidCallback onUlasanTap;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;

  const LandingMobileMenuOverlay({
    super.key,
    required this.onClose,
    required this.onFiturTap,
    required this.onStatistikTap,
    required this.onCaraKerjaTap,
    required this.onUlasanTap,
    required this.onLoginTap,
    required this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 70,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Column(
          children: [
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMobileMenuLink('Fitur', onFiturTap),
                  _buildMobileMenuLink('Statistik', onStatistikTap),
                  _buildMobileMenuLink('Cara Kerja', onCaraKerjaTap),
                  _buildMobileMenuLink('Ulasan', onUlasanTap),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0x1A2C2314)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: onLoginTap,
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6A4F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: onRegisterTap,
                          child: const Text(
                            'Daftar Gratis',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMenuLink(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF52B788),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
