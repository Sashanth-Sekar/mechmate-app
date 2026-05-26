import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mechmate_app/core/core.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<Offset> _ownerSlide;
  late Animation<Offset> _mechanicSlide;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn);
    _ownerSlide = Tween<Offset>(
      begin: const Offset(-1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _mechanicSlide = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  void _goRegister(String route, UserRole role) =>
      Navigator.pushNamed(context, route, arguments: {'role': role});

  void _goLogin(UserRole role) =>
      Navigator.pushNamed(context, AppRoutes.login,
          arguments: {'role': role});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.darkBgGradient
              : const LinearGradient(
                  colors: [Color(0xFFF4F5F0), Color(0xFFE0E1DC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: 'MECH',
                            style: GoogleFonts.rajdhani(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textDarkPrimary
                                  : AppColors.textLightPrimary,
                              letterSpacing: 2,
                            ),
                          ),
                          TextSpan(
                            text: 'MATE',
                            style: GoogleFonts.rajdhani(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryOrange,
                              letterSpacing: 2,
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Who are you?',
                        style: AppTextStyles.headline(isDark, size: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose your role to get started',
                        style: AppTextStyles.body(isDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SlideTransition(
                  position: _ownerSlide,
                  child: _RoleCard(
                    isDark: isDark,
                    title: 'Vehicle Owner',
                    subtitle:
                        'Find nearby workshops, book services,\ntrack your car or bike repairs.',
                    icon: Icons.directions_car_rounded,
                    gradient: AppColors.orangeGradient,
                    onRegister: () =>
                        _goRegister(AppRoutes.registerOwner, UserRole.owner),
                    onLogin: () => _goLogin(UserRole.owner),
                  ),
                ),
                const SizedBox(height: 16),
                SlideTransition(
                  position: _mechanicSlide,
                  child: _RoleCard(
                    isDark: isDark,
                    title: 'Workshop Mechanic',
                    subtitle:
                        'Manage bookings, create job cards,\ngrow your workshop business.',
                    icon: Icons.build_rounded,
                    gradient: AppColors.cyanGradient,
                    onRegister: () => _goRegister(
                        AppRoutes.registerMechanic, UserRole.mechanic),
                    onLogin: () => _goLogin(UserRole.mechanic),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onRegister;
  final VoidCallback onLogin;

  const _RoleCard({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onRegister,
    required this.onLogin,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: widget.isDark
                ? const LinearGradient(
                    colors: [Color(0xFF1E2430), Color(0xFF252C3A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFF7F8F4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          widget.gradient.colors.first.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Free',
                      style: TextStyle(
                        color: widget.gradient.colors.first,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: GoogleFonts.rajdhani(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textLightPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: widget.isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _GradBtn(
                      label: 'Register',
                      gradient: widget.gradient,
                      onPressed: widget.onRegister,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OutlineBtn(
                      label: 'Login',
                      color: widget.gradient.colors.first,
                      onPressed: widget.onLogin,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradBtn extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final VoidCallback onPressed;
  const _GradBtn(
      {required this.label,
      required this.gradient,
      required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _OutlineBtn(
      {required this.label, required this.color, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }
}
