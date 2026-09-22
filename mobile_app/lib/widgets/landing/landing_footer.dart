import 'package:flutter/material.dart';

class LandingFooter extends StatelessWidget {
  final bool isDesktop;
  final VoidCallback onFiturTap;
  final VoidCallback onCaraKerjaTap;
  final VoidCallback onUlasanTap;

  const LandingFooter({
    super.key,
    required this.isDesktop,
    required this.onFiturTap,
    required this.onCaraKerjaTap,
    required this.onUlasanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF2EDE3),
        border: Border(
          top: BorderSide(color: Color(0x1A2C2314), width: 1),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isDesktop
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFooterLogo(),
                    _buildFooterNav(),
                    _buildFooterCopyright(),
                  ],
                )
              : Column(
                  children: [
                    _buildFooterLogo(),
                    const SizedBox(height: 24),
                    _buildFooterNav(),
                    const SizedBox(height: 24),
                    _buildFooterCopyright(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFooterLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.agriculture_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SumberTani',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Color(0xFF1A3428),
              ),
            ),
            Text(
              'Sistem Informasi Manajemen Pertanian Modern Berbasis AI',
              style: TextStyle(
                fontSize: 11.2,
                color: Color(0xFF6B6050),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterNav() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFooterNavLink('Fitur', onFiturTap),
        const SizedBox(width: 24),
        _buildFooterNavLink('Cara Kerja', onCaraKerjaTap),
        const SizedBox(width: 24),
        _buildFooterNavLink('Ulasan', onUlasanTap),
      ],
    );
  }

  Widget _buildFooterNavLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.1,
          color: Color(0xFF6B6050),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFooterCopyright() {
    return const Text(
      '© 2026 SumberTani. All rights reserved.',
      style: TextStyle(
        fontSize: 12.5,
        color: Color(0xFFA8A090),
      ),
    );
  }
}
