import 'package:flutter/material.dart';

// ─── 1. Scroll Reveal Animation (Fade + Slide Up) ───────────────────────────
class FadeSlideOnScroll extends StatefulWidget {
  final Widget child;
  final double offset;
  final Duration duration;
  final Curve curve;
  final Duration delay;

  const FadeSlideOnScroll({
    super.key,
    required this.child,
    this.offset = 40.0,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
  });

  @override
  State<FadeSlideOnScroll> createState() => _FadeSlideOnScrollState();
}

class _FadeSlideOnScrollState extends State<FadeSlideOnScroll> with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _hasStarted = false;
  bool _scheduled = false;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: widget.curve),
    );
    _slide = Tween<Offset>(begin: Offset(0, widget.offset), end: Offset.zero).animate(
      CurvedAnimation(parent: _animCtrl, curve: widget.curve),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibility());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollableState = Scrollable.maybeOf(context);
    final position = scrollableState?.position;
    if (position != _scrollPosition) {
      if (_scrollPosition != null) {
        _scrollPosition!.removeListener(_updateVisibility);
      }
      _scrollPosition = position;
      if (_scrollPosition != null) {
        _scrollPosition!.addListener(_updateVisibility);
      }
    }
  }

  void _updateVisibility() {
    if (_hasStarted || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final renderObject = context.findRenderObject();
      if (renderObject is RenderBox && renderObject.hasSize) {
        final topLeft = renderObject.localToGlobal(Offset.zero);
        final bottomRight = renderObject.localToGlobal(renderObject.size.bottomRight(Offset.zero));
        final viewport = Offset.zero & MediaQuery.of(context).size;

        final visible = topLeft.dy <= viewport.bottom && bottomRight.dy >= viewport.top &&
            topLeft.dx <= viewport.right && bottomRight.dx >= viewport.left;

        if (visible) {
          _hasStarted = true;
          if (widget.delay == Duration.zero) {
            _animCtrl.forward();
          } else {
            Future.delayed(widget.delay, () {
              if (mounted) _animCtrl.forward();
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    if (_scrollPosition != null) {
      _scrollPosition!.removeListener(_updateVisibility);
    }
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) {
        final offset = _hasStarted ? _slide.value : Offset.zero;
        final opacity = _hasStarted ? _opacity.value : 1.0;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: offset,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ─── 2. Scale + Fade on Scroll (for icons and small reveal effects) ─────────
class ScaleFadeOnScroll extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration delay;
  final double startScale;

  const ScaleFadeOnScroll({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
    this.startScale = 0.9,
  });

  @override
  State<ScaleFadeOnScroll> createState() => _ScaleFadeOnScrollState();
}

class _ScaleFadeOnScrollState extends State<ScaleFadeOnScroll> with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  bool _hasStarted = false;
  bool _scheduled = false;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: widget.curve),
    );
    _scale = Tween<double>(begin: widget.startScale, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: widget.curve),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibility());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollableState = Scrollable.maybeOf(context);
    final position = scrollableState?.position;
    if (position != _scrollPosition) {
      if (_scrollPosition != null) {
        _scrollPosition!.removeListener(_updateVisibility);
      }
      _scrollPosition = position;
      if (_scrollPosition != null) {
        _scrollPosition!.addListener(_updateVisibility);
      }
    }
  }

  void _updateVisibility() {
    if (_hasStarted || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final renderObject = context.findRenderObject();
      if (renderObject is RenderBox && renderObject.hasSize) {
        final topLeft = renderObject.localToGlobal(Offset.zero);
        final bottomRight = renderObject.localToGlobal(renderObject.size.bottomRight(Offset.zero));
        final viewport = Offset.zero & MediaQuery.of(context).size;

        final visible = topLeft.dy <= viewport.bottom && bottomRight.dy >= viewport.top &&
            topLeft.dx <= viewport.right && bottomRight.dx >= viewport.left;

        if (visible) {
          _hasStarted = true;
          if (widget.delay == Duration.zero) {
            _animCtrl.forward();
          } else {
            Future.delayed(widget.delay, () {
              if (mounted) _animCtrl.forward();
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    if (_scrollPosition != null) {
      _scrollPosition!.removeListener(_updateVisibility);
    }
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) {
        final scale = _hasStarted ? _scale.value : widget.startScale;
        final opacity = _hasStarted ? _opacity.value : 1.0;
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ─── 3. Count Up Text Animation ──────────────────────────────────────────────
class CountUpText extends StatefulWidget {
  final int targetValue;
  final String suffix;
  final TextStyle style;
  final Duration duration;
  final Duration delay;
  final bool start;

  const CountUpText({
    super.key,
    required this.targetValue,
    this.suffix = '',
    required this.style,
    this.duration = const Duration(milliseconds: 2000),
    this.delay = Duration.zero,
    this.start = false,
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<int> _counter;
  bool _hasStarted = false;
  bool _scheduled = false;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: widget.duration);
    _counter = IntTween(begin: 0, end: widget.targetValue).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateVisibility());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollableState = Scrollable.maybeOf(context);
    final position = scrollableState?.position;
    if (position != _scrollPosition) {
      if (_scrollPosition != null) {
        _scrollPosition!.removeListener(_updateVisibility);
      }
      _scrollPosition = position;
      if (_scrollPosition != null) {
        _scrollPosition!.addListener(_updateVisibility);
      }
    }
  }

  void _updateVisibility() {
    if (_hasStarted || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final renderObject = context.findRenderObject();
      if (renderObject is RenderBox && renderObject.hasSize) {
        final topLeft = renderObject.localToGlobal(Offset.zero);
        final bottomRight = renderObject.localToGlobal(renderObject.size.bottomRight(Offset.zero));
        final viewport = Offset.zero & MediaQuery.of(context).size;

        final visible = topLeft.dy <= viewport.bottom && bottomRight.dy >= viewport.top &&
            topLeft.dx <= viewport.right && bottomRight.dx >= viewport.left;

        if (visible && !_hasStarted) {
          _hasStarted = true;
          if (widget.delay == Duration.zero) {
            _animCtrl.forward();
          } else {
            Future.delayed(widget.delay, () {
              if (mounted) {
                _animCtrl.forward();
              }
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _counter,
      builder: (context, _) {
        final value = _counter.value;
        return Text(
          '$value${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

// ─── 3. Hover Card Interaction (Scale + Elevate) ─────────────────────────────
class HoverCard extends StatefulWidget {
  final Widget child;
  final double scale;
  final List<BoxShadow>? activeShadow;
  final List<BoxShadow>? normalShadow;
  final BorderRadius borderRadius;

  const HoverCard({
    super.key,
    required this.child,
    this.scale = 1.02,
    this.activeShadow,
    this.normalShadow,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final shadow = _isHovered
        ? (widget.activeShadow ?? [
            BoxShadow(
              color: const Color(0xFF2C2314).withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            )
          ])
        : (widget.normalShadow ?? []);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(
          _isHovered ? widget.scale : 1.0,
          _isHovered ? widget.scale : 1.0,
          1.0,
        ),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: shadow,
        ),
        child: widget.child,
      ),
    );
  }
}

// ─── 4. Hover Button Interaction ─────────────────────────────────────────────
class HoverButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final ButtonStyle? style;

  const HoverButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.style,
  });

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

// ─── 5. Visibility Detector (Simple Viewport Check) ──────────────────────────
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final ValueChanged<bool> onVisibilityChanged;

  const VisibilityDetector({
    super.key,
    required this.child,
    required this.onVisibilityChanged,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  bool _isFirst = true;

  @override
  Widget build(BuildContext context) {
    // Basic delayed activation to check visibility when rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isFirst) {
        _isFirst = false;
        widget.onVisibilityChanged(true);
      }
    });
    return widget.child;
  }
}
