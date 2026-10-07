import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _glowController;
  late AnimationController _dotsController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Logo entrance animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );

    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );

    // Soft glowing animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    // Loading dots
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _logoController.forward();

    // Keep the original 3-second navigation.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF9FC),
              Color(0xFFF4ECF9),
              Color(0xFFEDE3F5),
              Color(0xFFFFF9FC),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ------------------------------------------
            // BACKGROUND AURA
            // ------------------------------------------

            Positioned(
              top: -100,
              right: -80,
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _glowAnimation.value * 0.35,
                    child: Container(
                      height: 260,
                      width: 260,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFC8B6E2),
                      ),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              bottom: -120,
              left: -100,
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _glowAnimation.value * 0.30,
                    child: Container(
                      height: 280,
                      width: 280,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF7DDE7),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ------------------------------------------
            // SMALL DECORATIVE STARS
            // ------------------------------------------

            const Positioned(
              top: 125,
              left: 55,
              child: Text(
                '✦',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFFC8B6E2),
                ),
              ),
            ),

            const Positioned(
              top: 185,
              right: 65,
              child: Text(
                '✧',
                style: TextStyle(
                  fontSize: 25,
                  color: Color(0xFFD8C5E8),
                ),
              ),
            ),

            const Positioned(
              bottom: 165,
              right: 75,
              child: Text(
                '✦',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFFE1C4D5),
                ),
              ),
            ),

            // ------------------------------------------
            // MAIN CONTENT
            // ------------------------------------------

            Center(
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // --------------------------------
                          // READAURA LOGO
                          // --------------------------------

                          AnimatedBuilder(
                            animation: _glowAnimation,
                            builder: (context, child) {
                              return Container(
                                height: 125,
                                width: 125,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFE8DDF1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFC8B6E2,
                                      ).withOpacity(
                                        0.30 * _glowAnimation.value,
                                      ),
                                      blurRadius:
                                      35 * _glowAnimation.value,
                                      spreadRadius:
                                      8 * _glowAnimation.value,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: Image.asset(
                                      'assets/images/readaura_app_icon.png',
                                      height: 88,
                                      width: 88,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 25),

                          // --------------------------------
                          // READAURA
                          // --------------------------------

                          const Text(
                            'READAURA',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 5,
                              color: Color(0xFF6B5B7B),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // --------------------------------
                          // SMALL DIVIDER
                          // --------------------------------

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 1,
                                width: 28,
                                color: Color(0xFFC8B6E2),
                              ),
                              const SizedBox(width: 9),
                              const Text(
                                '✦',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFC8B6E2),
                                ),
                              ),
                              const SizedBox(width: 9),
                              Container(
                                height: 1,
                                width: 28,
                                color: Color(0xFFC8B6E2),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Where every story finds its aura.',
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 0.8,
                              color: Color(0xFF9A8FA3),
                            ),
                          ),

                          const SizedBox(height: 38),

                          // --------------------------------
                          // ANIMATED LOADING DOTS
                          // --------------------------------

                          AnimatedBuilder(
                            animation: _dotsController,
                            builder: (context, child) {
                              final value = _dotsController.value;

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _loadingDot(
                                    0,
                                    value,
                                  ),
                                  const SizedBox(width: 7),
                                  _loadingDot(
                                    1,
                                    value,
                                  ),
                                  const SizedBox(width: 7),
                                  _loadingDot(
                                    2,
                                    value,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ------------------------------------------
            // BOTTOM TEXT
            // ------------------------------------------

            const Positioned(
              bottom: 35,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'READ • FEEL • REFLECT',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB0A3B8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingDot(
      int index,
      double animationValue,
      ) {
    final double difference =
    (animationValue - (index * 0.2)).abs();

    final double opacity =
    difference < 0.2 ? 1.0 : 0.35;

    final double size =
    difference < 0.2 ? 8.0 : 5.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFC8B6E2)
            .withOpacity(opacity),
      ),
    );
  }
}