import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mechmate_app/core/core.dart';
import 'package:mechmate_app/features/auth/providers/auth_provider.dart';
import 'package:mechmate_app/shared/shared.dart';

class MechanicProfileScreen extends StatelessWidget {
  const MechanicProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AppAuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.userModel;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.darkBgGradient
              : const LinearGradient(
                  colors: [Color(0xFFF4F5F0), Color(0xFFECEDE8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.cyanAccent,
                  child: Text(
                    (user?.name ?? 'M')[0].toUpperCase(),
                    style: GoogleFonts.rajdhani(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.black),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? 'Workshop Mechanic',
                    style: GoogleFonts.rajdhani(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textLightPrimary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cyanAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.build_rounded,
                          size: 13, color: AppColors.cyanAccent),
                      SizedBox(width: 5),
                      Text('Workshop Mechanic',
                          style: TextStyle(
                              color: AppColors.cyanAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Earnings summary card
                GradientCard(
                  gradientColors: [
                    AppColors.success.withValues(alpha: 0.12),
                    isDark ? AppColors.darkCard : AppColors.lightSurface,
                  ],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _EarningCell(
                          label: 'This Month',
                          value: '₹18,400',
                          isDark: isDark),
                      Container(
                          width: 1,
                          height: 40,
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      _EarningCell(
                          label: 'Total Jobs',
                          value: '142',
                          isDark: isDark),
                      Container(
                          width: 1,
                          height: 40,
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      _EarningCell(
                          label: 'Rating',
                          value: '4.8 ⭐',
                          isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                GradientCard(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      _InfoTile(Icons.email_outlined, 'Email',
                          user?.email ?? '—', isDark),
                      Divider(height: 1,
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      _InfoTile(Icons.phone_outlined, 'Phone',
                          user?.phone ?? '—', isDark),
                      Divider(height: 1,
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      _InfoTile(
                          Icons.location_city_outlined,
                          'Workshop',
                          'Speed Auto Works – Mumbai',
                          isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                GradientCard(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      _ToggleTile(
                        icon: isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        label: isDark ? 'Dark Mode' : 'Light Mode',
                        isDark: isDark,
                        value: isDark,
                        onToggle: (_) => themeProvider.toggleTheme(),
                      ),
                      Divider(height: 1,
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      _NavTile(
                          Icons.bar_chart_rounded,
                          'Earnings Report',
                          isDark),
                      Divider(height: 1,
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      _NavTile(
                          Icons.help_outline_rounded, 'Help & Support', isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                PrimaryButton(
                  label: 'Sign Out',
                  outlined: true,
                  onPressed: () async {
                    await auth.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, AppRoutes.roleSelect, (_) => false);
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EarningCell extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _EarningCell(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Rajdhani',
              color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary)),
      Text(label,
          style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted)),
    ]);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  const _InfoTile(this.icon, this.label, this.value, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon,
            size: 18,
            color: isDark
                ? AppColors.textDarkMuted
                : AppColors.textLightMuted),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textDarkMuted
                        : AppColors.textLightMuted)),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textLightPrimary)),
          ]),
        ),
      ]),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool value;
  final void Function(bool) onToggle;
  const _ToggleTile(
      {required this.icon,
      required this.label,
      required this.isDark,
      required this.value,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Icon(icon,
            size: 20,
            color: isDark
                ? AppColors.textDarkSecondary
                : AppColors.textLightSecondary),
        const SizedBox(width: 14),
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textLightPrimary))),
        Switch(value: value, onChanged: onToggle),
      ]),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _NavTile(this.icon, this.label, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon,
            size: 20,
            color: isDark
                ? AppColors.textDarkSecondary
                : AppColors.textLightSecondary),
        const SizedBox(width: 14),
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textLightPrimary))),
        const Icon(Icons.chevron_right_rounded, size: 20),
      ]),
    );
  }
}
