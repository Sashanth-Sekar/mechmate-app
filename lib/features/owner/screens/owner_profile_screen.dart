import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mechmate_app/core/core.dart';
import 'package:mechmate_app/features/auth/providers/auth_provider.dart';
import 'package:mechmate_app/shared/shared.dart';
import 'package:mechmate_app/features/owner/widgets/edit_profile_sheet.dart';

class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({super.key});

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
                // Avatar
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primaryOrange,
                  child: Text(
                    (user?.name ?? 'U')[0].toUpperCase(),
                    style: GoogleFonts.rajdhani(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user?.name ?? 'Vehicle Owner',
                      style: GoogleFonts.rajdhani(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textLightPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      color: AppColors.primaryOrange,
                      onPressed: () async {
                        if (user != null) {
                          await showEditProfileSheet(context, user, isDark);
                          // We might want to refresh the user model here if needed. 
                          // Currently auth.userModel getter might not reflect the updated user unless reloaded, 
                          // but the user object inside authProvider doesn't change directly. 
                          // If we had a mechanism to refresh auth, we would call it here.
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.directions_car_rounded,
                        size: 13,
                        color: AppColors.primaryOrange,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Vehicle Owner',
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Info card
                GradientCard(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      _InfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user?.email ?? '—',
                        isDark: isDark,
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      _InfoTile(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: user?.phone ?? '—',
                        isDark: isDark,
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      _InfoTile(
                        icon: Icons.person_outline_rounded,
                        label: 'Member Since',
                        value: user?.createdAt != null
                            ? '${user!.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'
                            : '—',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Settings card
                GradientCard(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      _SettingTile(
                        icon: isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        label: isDark ? 'Dark Mode' : 'Light Mode',
                        isDark: isDark,
                        trailing: Switch(
                          value: isDark,
                          onChanged: (_) => themeProvider.toggleTheme(),
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      _SettingTile(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        isDark: isDark,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      _SettingTile(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & Support',
                        isDark: isDark,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sign out
                PrimaryButton(
                  label: 'Sign Out',
                  outlined: true,
                  onPressed: () async {
                    await auth.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.roleSelect,
                        (_) => false,
                      );
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textDarkMuted
                        : AppColors.textLightMuted,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textLightPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Widget trailing;
  const _SettingTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark
                ? AppColors.textDarkSecondary
                : AppColors.textLightSecondary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textLightPrimary,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
