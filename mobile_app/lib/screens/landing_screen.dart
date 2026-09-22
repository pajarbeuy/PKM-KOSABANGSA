import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../widgets/landing_animations.dart';
import '../widgets/landing/landing_blobs.dart';
import '../widgets/landing/landing_waves.dart';
import '../widgets/landing/landing_nav.dart';
import '../widgets/landing/landing_hero.dart';
import '../widgets/landing/landing_stats.dart';
import '../widgets/landing/landing_features.dart';
import '../widgets/landing/landing_workflow.dart';
import '../widgets/landing/landing_testimonials.dart';
import '../widgets/landing/landing_cta.dart';
import '../widgets/landing/landing_footer.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Map<String, String> _landingContent = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Scroll controller to track sticky navigation style
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  bool _isMobileMenuOpen = false;
  bool _hasStatSectionEntered = false;

  // Scroll to a specific section by its key/id (simulating HTML anchor)
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _fiturKey = GlobalKey();
  final GlobalKey _statistikKey = GlobalKey();
  final GlobalKey _caraKerjaKey = GlobalKey();
  final GlobalKey _testimoniKey = GlobalKey();
  final GlobalKey _ctaKey = GlobalKey();

  // ── Blob animation controllers (liquid morph effect) ──────────────────────
  late final AnimationController _blob1Ctrl;
  late final AnimationController _blob2Ctrl;
  late final AnimationController _blob3Ctrl;
  late final AnimationController _blob4Ctrl;
  late final AnimationController _blob5Ctrl;

  // Translate animations (dx, dy)
  late final Animation<Offset> _blob1Trans;
  late final Animation<Offset> _blob2Trans;
  late final Animation<Offset> _blob3Trans;
  late final Animation<Offset> _blob4Trans;
  late final Animation<Offset> _blob5Trans;

  // Rotation animations (radians)
  late final Animation<double> _blob1Rot;
  late final Animation<double> _blob2Rot;
  late final Animation<double> _blob3Rot;
  late final Animation<double> _blob4Rot;
  late final Animation<double> _blob5Rot;

  // ── Wave animation controllers (nullable to prevent hot restart crashes) ──
  AnimationController? _wave1Ctrl;
  AnimationController? _wave2Ctrl;

  @override
  void initState() {
    super.initState();
    _initBlobAnimations();
    _scrollController.addListener(_onScroll);
    _loadLandingContent();
  }

  void _initBlobAnimations() {
    // Blob 1 — large green top-left (12s cycle)
    _blob1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat(reverse: true);
    _blob1Trans = Tween<Offset>(
      begin: const Offset(-20, -15),
      end: const Offset(80, 60),
    ).animate(CurvedAnimation(parent: _blob1Ctrl, curve: Curves.easeInOut));
    _blob1Rot = Tween<double>(begin: -0.12, end: 0.12)
        .animate(CurvedAnimation(parent: _blob1Ctrl, curve: Curves.easeInOut));

    // Blob 2 — amber top-right (7s, offset phase)
    _blob2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat(reverse: true);
    _blob2Trans = Tween<Offset>(
      begin: const Offset(15, -10),
      end: const Offset(-70, 90),
    ).animate(CurvedAnimation(parent: _blob2Ctrl, curve: Curves.easeInOut));
    _blob2Rot = Tween<double>(begin: 0.10, end: -0.10)
        .animate(CurvedAnimation(parent: _blob2Ctrl, curve: Curves.easeInOut));

    // Blob 3 — green bottom-center (16s)
    _blob3Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16000),
    )..repeat(reverse: true);
    _blob3Trans = Tween<Offset>(
      begin: const Offset(-30, 20),
      end: const Offset(100, -80),
    ).animate(CurvedAnimation(parent: _blob3Ctrl, curve: Curves.easeInOut));
    _blob3Rot = Tween<double>(begin: -0.08, end: 0.08)
        .animate(CurvedAnimation(parent: _blob3Ctrl, curve: Curves.easeInOut));

    // Blob 4 — amber bottom-right (18s)
    _blob4Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 18000),
    )..repeat(reverse: true);
    _blob4Trans = Tween<Offset>(
      begin: const Offset(10, 15),
      end: const Offset(-60, -70),
    ).animate(CurvedAnimation(parent: _blob4Ctrl, curve: Curves.easeInOut));
    _blob4Rot = Tween<double>(begin: 0.07, end: -0.12)
        .animate(CurvedAnimation(parent: _blob4Ctrl, curve: Curves.easeInOut));

    // Blob 5 — small green bottom-left (14s)
    _blob5Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 14000),
    )..repeat(reverse: true);
    _blob5Trans = Tween<Offset>(
      begin: const Offset(-15, 10),
      end: const Offset(50, -60),
    ).animate(CurvedAnimation(parent: _blob5Ctrl, curve: Curves.easeInOut));
    _blob5Rot = Tween<double>(begin: -0.06, end: 0.10)
        .animate(CurvedAnimation(parent: _blob5Ctrl, curve: Curves.easeInOut));

    // Wave controllers — continuous horizontal phase shift
    _wave1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    _wave2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _blob1Ctrl.dispose();
    _blob2Ctrl.dispose();
    _blob3Ctrl.dispose();
    _blob4Ctrl.dispose();
    _blob5Ctrl.dispose();
    _wave1Ctrl?.dispose();
    _wave2Ctrl?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasStatSectionEntered && _scrollController.hasClients) {
      final context = _statistikKey.currentContext;
      if (context != null) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final position = renderBox.localToGlobal(Offset.zero, ancestor: null);
          final viewportHeight = MediaQuery.of(context).size.height;
          final triggerPoint = viewportHeight * 0.35;

          if (position.dy <= triggerPoint) {
            setState(() {
              _hasStatSectionEntered = true;
            });
          }
        }
      }
    }

    if (_scrollController.hasClients) {
      final scrolled = _scrollController.offset > 30;
      if (scrolled != _isScrolled) {
        setState(() {
          _isScrolled = scrolled;
        });
      }
    }
  }

  Future<void> _loadLandingContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getLandingContent();
      if (mounted) {
        setState(() {
          _landingContent = data?.map((key, value) => MapEntry(key, value?.toString() ?? '')) ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _landingValue(String key, String fallback) {
    final value = _landingContent[key];
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return fallback;
  }

  void _scrollToKey(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return;

    if (Scrollable.maybeOf(targetContext) != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    } else if (_scrollController.hasClients) {
      final targetBox = targetContext.findRenderObject() as RenderBox?;
      final scrollBox = _scrollController.position.context.storageContext.findRenderObject() as RenderBox?;
      if (targetBox != null && scrollBox != null) {
        final targetOffset = targetBox.localToGlobal(Offset.zero, ancestor: scrollBox).dy +
            _scrollController.offset;
        final alignedOffset = targetOffset.clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.animateTo(
          alignedOffset,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    }

    setState(() {
      _isMobileMenuOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE3),
      body: Stack(
        children: [
          // Background Blobs
          Positioned.fill(
            child: LandingBlobsBackground(
              size: size,
              blob1Ctrl: _blob1Ctrl,
              blob2Ctrl: _blob2Ctrl,
              blob3Ctrl: _blob3Ctrl,
              blob4Ctrl: _blob4Ctrl,
              blob5Ctrl: _blob5Ctrl,
              blob1Trans: _blob1Trans,
              blob2Trans: _blob2Trans,
              blob3Trans: _blob3Trans,
              blob4Trans: _blob4Trans,
              blob5Trans: _blob5Trans,
              blob1Rot: _blob1Rot,
              blob2Rot: _blob2Rot,
              blob3Rot: _blob3Rot,
              blob4Rot: _blob4Rot,
              blob5Rot: _blob5Rot,
            ),
          ),

          // Main Scroll View
          Positioned.fill(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2D6A4F),
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        SizedBox(height: isDesktop ? 70 : 70 + MediaQuery.of(context).padding.top),

                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            color: const Color(0xFFFEE2E2),
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFC0392B),
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Hero Section
                        FadeSlideOnScroll(
                          child: Container(
                            key: _heroKey,
                            child: LandingHeroSection(
                              isDesktop: isDesktop,
                              heroTitle: _landingValue('hero_title', 'Kelola Pencatatan Pertanian'),
                              heroTitleEmphasis: _landingValue('hero_title_emphasis', 'Lebih Cerdas & Modern'),
                              heroDescription: _landingValue(
                                'hero_description',
                                'SumberTani hadir membantu petani mengelola panen, stok produk olahan, penjualan, dan laporan keuangan — dalam satu platform yang modern, mudah, dan bisa diakses kapan saja.',
                              ),
                              onStartFreeTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                );
                              },
                              onLoginTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              },
                            ),
                          ),
                        ),

                        // Wave transition between Hero and Stats Section
                        LandingWaveTransition(
                          fill: const Color(0xFF1A3428),
                          opacity: 0.97,
                          isBottom: true,
                          wave1Ctrl: _wave1Ctrl,
                          wave2Ctrl: _wave2Ctrl,
                        ),

                        // Stats Section
                        Container(
                          key: _statistikKey,
                          child: LandingStatsSection(
                            isDesktop: isDesktop,
                            hasStatSectionEntered: _hasStatSectionEntered,
                          ),
                        ),

                        // Wave transition between Stats and Features Section
                        LandingWaveTransition(
                          fill: const Color(0xFFF2EDE3),
                          opacity: 0.95,
                          isBottom: false,
                          wave1Ctrl: _wave1Ctrl,
                          wave2Ctrl: _wave2Ctrl,
                        ),

                        // Features Section
                        Container(
                          key: _fiturKey,
                          child: LandingFeaturesSection(
                            isDesktop: isDesktop,
                            landingContent: _landingContent,
                          ),
                        ),

                        // Wave transition between Features and How It Works Section
                        LandingWaveTransition(
                          fill: const Color(0xFF1E3A2A),
                          opacity: 0.9,
                          isBottom: true,
                          wave1Ctrl: _wave1Ctrl,
                          wave2Ctrl: _wave2Ctrl,
                        ),

                        // How It Works Section
                        Container(
                          key: _caraKerjaKey,
                          child: LandingWorkflowSection(isDesktop: isDesktop),
                        ),

                        // Wave transition between How It Works and Testimonials Section
                        LandingWaveTransition(
                          fill: const Color(0xFFF2EDE3),
                          opacity: 0.9,
                          isBottom: false,
                          wave1Ctrl: _wave1Ctrl,
                          wave2Ctrl: _wave2Ctrl,
                        ),

                        // Testimonials Section
                        FadeSlideOnScroll(
                          child: Container(
                            key: _testimoniKey,
                            child: LandingTestimonialsSection(isDesktop: isDesktop),
                          ),
                        ),

                        // Wave transition between Testimonials and CTA Section
                        LandingWaveTransition(
                          fill: const Color(0xFF1A3428),
                          opacity: 0.92,
                          isBottom: true,
                          wave1Ctrl: _wave1Ctrl,
                          wave2Ctrl: _wave2Ctrl,
                        ),

                        // CTA Section
                        FadeSlideOnScroll(
                          child: Container(
                            key: _ctaKey,
                            child: LandingCtaSection(
                              onRegisterTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                );
                              },
                              onLoginTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              },
                            ),
                          ),
                        ),

                        // Footer
                        FadeSlideOnScroll(
                          child: LandingFooter(
                            isDesktop: isDesktop,
                            onFiturTap: () => _scrollToKey(_fiturKey),
                            onCaraKerjaTap: () => _scrollToKey(_caraKerjaKey),
                            onUlasanTap: () => _scrollToKey(_testimoniKey),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Sticky Top Navigation
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: true,
              bottom: false,
              child: LandingNavbar(
                isDesktop: isDesktop,
                isScrolled: _isScrolled,
                isMobileMenuOpen: _isMobileMenuOpen,
                onLogoTap: () => _scrollToKey(_heroKey),
                onFiturTap: () => _scrollToKey(_fiturKey),
                onStatistikTap: () => _scrollToKey(_statistikKey),
                onCaraKerjaTap: () => _scrollToKey(_caraKerjaKey),
                onUlasanTap: () => _scrollToKey(_testimoniKey),
                onLoginTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                onRegisterTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                onToggleMobileMenu: () {
                  setState(() {
                    _isMobileMenuOpen = !_isMobileMenuOpen;
                  });
                },
              ),
            ),
          ),

          // Mobile Drawer Overlay Menu
          if (_isMobileMenuOpen && !isDesktop)
            Positioned(
              top: 70 + MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              bottom: 0,
              child: LandingMobileMenuOverlay(
                onClose: () {
                  setState(() {
                    _isMobileMenuOpen = false;
                  });
                },
                onFiturTap: () => _scrollToKey(_fiturKey),
                onStatistikTap: () => _scrollToKey(_statistikKey),
                onCaraKerjaTap: () => _scrollToKey(_caraKerjaKey),
                onUlasanTap: () => _scrollToKey(_testimoniKey),
                onLoginTap: () {
                  setState(() => _isMobileMenuOpen = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                onRegisterTap: () {
                  setState(() => _isMobileMenuOpen = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
