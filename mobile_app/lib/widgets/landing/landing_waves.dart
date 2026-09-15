import 'package:flutter/material.dart';

class LandingWaveTransition extends StatelessWidget {
  final Color fill;
  final double opacity;
  final bool isBottom;
  final AnimationController? wave1Ctrl;
  final AnimationController? wave2Ctrl;

  const LandingWaveTransition({
    super.key,
    required this.fill,
    required this.opacity,
    required this.isBottom,
    this.wave1Ctrl,
    this.wave2Ctrl,
  });

  @override
  Widget build(BuildContext context) {
    if (wave1Ctrl == null || wave2Ctrl == null) {
      return SizedBox(
        height: 120,
        width: double.infinity,
        child: Container(color: fill.withValues(alpha: opacity)),
      );
    }

    return SizedBox(
      height: 120,
      width: double.infinity,
      child: Stack(
        children: [
          // Wave layer 1 (background, slower)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: wave1Ctrl!,
              builder: (context, _) {
                return Opacity(
                  opacity: opacity * 0.45,
                  child: CustomPaint(
                    painter: AnimatedWavePainter(
                      fill: fill,
                      phase: wave1Ctrl!.value * 2 * 3.14159,
                      isBottom: isBottom,
                      isLayer2: false,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),
          // Wave layer 2 (foreground, faster)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: wave2Ctrl!,
              builder: (context, _) {
                return Opacity(
                  opacity: opacity,
                  child: CustomPaint(
                    painter: AnimatedWavePainter(
                      fill: fill,
                      phase: wave2Ctrl!.value * 2 * 3.14159,
                      isBottom: isBottom,
                      isLayer2: true,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedWavePainter extends CustomPainter {
  final Color fill;
  final double phase;
  final bool isBottom;
  final bool isLayer2;

  AnimatedWavePainter({
    required this.fill,
    required this.phase,
    required this.isBottom,
    required this.isLayer2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = fill;
    final path = Path();

    final w = size.width / 1440.0;
    final h = size.height / 120.0;
    final waveAmp = isLayer2 ? 8.0 * h : 13.0 * h;

    if (isBottom) {
      if (!isLayer2) {
        final y0 = (60.0 + waveAmp * _sin(phase)) * h;
        final y1C1 = (20.0 + waveAmp * _sin(phase + 1.0)) * h;
        final y1C2 = (100.0 + waveAmp * _sin(phase + 2.0)) * h;
        final y1End = (60.0 + waveAmp * _sin(phase + 3.0)) * h;

        final y2C1 = (20.0 + waveAmp * _sin(phase + 4.0)) * h;
        final y2C2 = (100.0 + waveAmp * _sin(phase + 5.0)) * h;
        final y2End = (60.0 + waveAmp * _sin(phase + 0.5)) * h;

        final y3C1 = (20.0 + waveAmp * _sin(phase + 1.5)) * h;
        final y3C2 = (100.0 + waveAmp * _sin(phase + 2.5)) * h;
        final y3End = (60.0 + waveAmp * _sin(phase + 3.5)) * h;

        path.moveTo(0, y0);
        path.cubicTo(180 * w, y1C1, 360 * w, y1C2, 540 * w, y1End);
        path.cubicTo(720 * w, y2C1, 900 * w, y2C2, 1080 * w, y2End);
        path.cubicTo(1260 * w, y3C1, 1440 * w, y3C2, size.width, y3End);
      } else {
        final y0 = (70.0 + waveAmp * _sin(phase + 1.5)) * h;
        final y1C1 = (30.0 + waveAmp * _sin(phase + 2.5)) * h;
        final y1C2 = (110.0 + waveAmp * _sin(phase + 3.5)) * h;
        final y1End = (70.0 + waveAmp * _sin(phase + 0.5)) * h;

        final y2C1 = (30.0 + waveAmp * _sin(phase + 1.2)) * h;
        final y2C2 = (110.0 + waveAmp * _sin(phase + 2.2)) * h;
        final y2End = (70.0 + waveAmp * _sin(phase + 3.2)) * h;

        final y3C1 = (30.0 + waveAmp * _sin(phase + 0.2)) * h;
        final y3C2 = (110.0 + waveAmp * _sin(phase + 1.2)) * h;
        final y3End = (70.0 + waveAmp * _sin(phase + 2.2)) * h;

        path.moveTo(0, y0);
        path.cubicTo(120 * w, y1C1, 240 * w, y1C2, 360 * w, y1End);
        path.cubicTo(480 * w, y2C1, 600 * w, y2C2, 720 * w, y2End);
        path.cubicTo(840 * w, y3C1, 960 * w, y3C2, 1080 * w, y3End);
        path.cubicTo(1200 * w, y1C1, 1320 * w, y1C2, size.width, y1End);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      if (!isLayer2) {
        final y0 = (60.0 + waveAmp * _sin(phase)) * h;
        final y1C1 = (100.0 + waveAmp * _sin(phase + 1.0)) * h;
        final y1C2 = (20.0 + waveAmp * _sin(phase + 2.0)) * h;
        final y1End = (60.0 + waveAmp * _sin(phase + 3.0)) * h;

        final y2C1 = (100.0 + waveAmp * _sin(phase + 4.0)) * h;
        final y2C2 = (20.0 + waveAmp * _sin(phase + 5.0)) * h;
        final y2End = (60.0 + waveAmp * _sin(phase + 0.5)) * h;

        final y3C1 = (100.0 + waveAmp * _sin(phase + 1.5)) * h;
        final y3C2 = (20.0 + waveAmp * _sin(phase + 2.5)) * h;
        final y3End = (60.0 + waveAmp * _sin(phase + 3.5)) * h;

        path.moveTo(0, y0);
        path.cubicTo(180 * w, y1C1, 360 * w, y1C2, 540 * w, y1End);
        path.cubicTo(720 * w, y2C1, 900 * w, y2C2, 1080 * w, y2End);
        path.cubicTo(1260 * w, y3C1, 1440 * w, y3C2, size.width, y3End);
      } else {
        final y0 = (70.0 + waveAmp * _sin(phase + 1.5)) * h;
        final y1C1 = (110.0 + waveAmp * _sin(phase + 2.5)) * h;
        final y1C2 = (30.0 + waveAmp * _sin(phase + 3.5)) * h;
        final y1End = (70.0 + waveAmp * _sin(phase + 0.5)) * h;

        final y2C1 = (110.0 + waveAmp * _sin(phase + 1.2)) * h;
        final y2C2 = (30.0 + waveAmp * _sin(phase + 2.2)) * h;
        final y2End = (70.0 + waveAmp * _sin(phase + 3.2)) * h;

        final y3C1 = (110.0 + waveAmp * _sin(phase + 0.2)) * h;
        final y3C2 = (30.0 + waveAmp * _sin(phase + 1.2)) * h;
        final y3End = (70.0 + waveAmp * _sin(phase + 2.2)) * h;

        path.moveTo(0, y0);
        path.cubicTo(120 * w, y1C1, 240 * w, y1C2, 360 * w, y1End);
        path.cubicTo(480 * w, y2C1, 600 * w, y2C2, 720 * w, y2End);
        path.cubicTo(840 * w, y3C1, 960 * w, y3C2, 1080 * w, y3End);
        path.cubicTo(1200 * w, y1C1, 1320 * w, y1C2, size.width, y1End);
      }
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  double _sin(double x) {
    double v = x % (2 * 3.14159);
    if (v < 0) v += 2 * 3.14159;
    if (v > 3.14159) v -= 2 * 3.14159;
    final x2 = v * v;
    return v * (1.0 - x2 / 6.0 * (1.0 - x2 / 20.0 * (1.0 - x2 / 42.0 * (1.0 - x2 / 72.0))));
  }

  @override
  bool shouldRepaint(AnimatedWavePainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}
