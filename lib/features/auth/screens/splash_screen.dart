import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mechmate_app/core/core.dart';
import 'package:mechmate_app/features/auth/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _gearCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _gearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _fadeAnim = CurvedAnimation(
      parent: _logoCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoCtrl,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2800), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final auth = context.read<AppAuthProvider>();
    if (auth.isAuthenticated && auth.userModel != null) {
      final route = auth.userModel!.role == UserRole.owner
          ? AppRoutes.ownerMain
          : AppRoutes.mechanicMain;
      Navigator.pushReplacementNamed(context, route);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelect);
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _gearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.darkBgGradient
              : const LinearGradient(
                  colors: [Color(0xFFF4F5F0), Color(0xFFE8E9E4)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -80,
              child: AnimatedBuilder(
                animation: _gearCtrl,
                builder: (_, child) => Transform.rotate(
                  angle: _gearCtrl.value * 2 * math.pi,
                  child: child,
                ),
                child: Icon(Icons.settings,
                    size: 260,
                    color: AppColors.primaryOrange.withValues(alpha: 0.04)),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: AnimatedBuilder(
                animation: _gearCtrl,
                builder: (_, child) => Transform.rotate(
                  angle: -_gearCtrl.value * 2 * math.pi,
                  child: child,
                ),
                child: Icon(Icons.settings,
                    size: 200,
                    color: AppColors.primaryOrange.withValues(alpha: 0.04)),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _gearCtrl,
                    builder: (_, child) => Transform.rotate(
                      angle: _gearCtrl.value * 2 * math.pi,
                      child: child,
                    ),
                    child: Icon(Icons.settings,
                        size: 60,
                        color: AppColors.primaryOrange.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: 'MECH',
                            style: GoogleFonts.rajdhani(
                              fontSize: 58,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textDarkPrimary
                                  : AppColors.textLightPrimary,
                              letterSpacing: 3,
                            ),
                          ),
                          TextSpan(
                            text: 'MATE',
                            style: GoogleFonts.rajdhani(
                              fontSize: 58,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryOrange,
                              letterSpacing: 3,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SlideTransition(
                    position: _taglineSlide,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Text(
                        'Your Automobile Service Partner',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: const _PulsingDots(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();
  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final v = ((_ctrl.value - i * 0.3) % 1.0).clamp(0.0, 1.0);
          final opacity = v < 0.5 ? v * 2 : (1 - v) * 2;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryOrange
                  .withValues(alpha: opacity.clamp(0.15, 1.0)),
            ),
          );
        }),
      ),
    );
  }
}
