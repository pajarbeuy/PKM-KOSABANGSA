import 'dart:ui';
import 'package:flutter/material.dart';

class LandingBlobsBackground extends StatelessWidget {
  final Size size;
  final AnimationController blob1Ctrl;
  final AnimationController blob2Ctrl;
  final AnimationController blob3Ctrl;
  final AnimationController blob4Ctrl;
  final AnimationController blob5Ctrl;

  final Animation<Offset> blob1Trans;
  final Animation<Offset> blob2Trans;
  final Animation<Offset> blob3Trans;
  final Animation<Offset> blob4Trans;
  final Animation<Offset> blob5Trans;

  final Animation<double> blob1Rot;
  final Animation<double> blob2Rot;
  final Animation<double> blob3Rot;
  final Animation<double> blob4Rot;
  final Animation<double> blob5Rot;

  const LandingBlobsBackground({
    super.key,
    required this.size,
    required this.blob1Ctrl,
    required this.blob2Ctrl,
    required this.blob3Ctrl,
    required this.blob4Ctrl,
    required this.blob5Ctrl,
    required this.blob1Trans,
    required this.blob2Trans,
    required this.blob3Trans,
    required this.blob4Trans,
    required this.blob5Trans,
    required this.blob1Rot,
    required this.blob2Rot,
    required this.blob3Rot,
    required this.blob4Rot,
    required this.blob5Rot,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Blob 1 ── large green, top-left ────────────────────────────
        Positioned(
          top: -200,
          left: -200,
          width: 700,
          height: 700,
          child: AnimatedBuilder(
            animation: blob1Ctrl,
            builder: (context, child) {
              return Transform.translate(
                offset: blob1Trans.value,
                child: Transform.rotate(
                  angle: blob1Rot.value,
                  child: child,
                ),
              );
            },
            child: Opacity(
              opacity: 0.30,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.3, -0.3),
                      radius: 0.8,
                      colors: [
                        Color(0xFF74C69D),
                        Color(0xFF52B788),
                        Color(0xFF2D6A4F),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.38, 0.77, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Blob 2 ── amber, top-right ─────────────────────────────────
        Positioned(
          top: 80,
          right: -150,
          width: 500,
          height: 500,
          child: AnimatedBuilder(
            animation: blob2Ctrl,
            builder: (context, child) {
              return Transform.translate(
                offset: blob2Trans.value,
                child: Transform.rotate(
                  angle: blob2Rot.value,
                  child: child,
                ),
              );
            },
            child: Opacity(
              opacity: 0.25,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(0.2, 0.2),
                      radius: 0.8,
                      colors: [
                        Color(0xFFFCD34D),
                        Color(0xFFF59E0B),
                        Color(0xFFD97706),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.47, 0.82, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Blob 3 ── green, bottom-center ─────────────────────────────
        Positioned(
          bottom: 40,
          left: size.width / 2 - 300,
          width: 600,
          height: 600,
          child: AnimatedBuilder(
            animation: blob3Ctrl,
            builder: (context, child) {
              return Transform.translate(
                offset: blob3Trans.value,
                child: Transform.rotate(
                  angle: blob3Rot.value,
                  child: child,
                ),
              );
            },
            child: Opacity(
              opacity: 0.28,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(0.0, 0.2),
                      radius: 0.7,
                      colors: [
                        Color(0xFF52B788),
                        Color(0xFF2D6A4F),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.51, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Blob 4 ── amber, bottom-right ──────────────────────────────
        Positioned(
          bottom: -30,
          right: size.width * 0.05,
          width: 380,
          height: 380,
          child: AnimatedBuilder(
            animation: blob4Ctrl,
            builder: (context, child) {
              return Transform.translate(
                offset: blob4Trans.value,
                child: Transform.rotate(
                  angle: blob4Rot.value,
                  child: child,
                ),
              );
            },
            child: Opacity(
              opacity: 0.22,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFFD97706),
                        Color(0xFFF5A623),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.57, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Blob 5 ── small green, bottom-left ─────────────────────────
        Positioned(
          bottom: 20,
          left: size.width * 0.03,
          width: 300,
          height: 300,
          child: AnimatedBuilder(
            animation: blob5Ctrl,
            builder: (context, child) {
              return Transform.translate(
                offset: blob5Trans.value,
                child: Transform.rotate(
                  angle: blob5Rot.value,
                  child: child,
                ),
              );
            },
            child: Opacity(
              opacity: 0.20,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF74C69D),
                        Colors.transparent,
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
