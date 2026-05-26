import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mechmate_app/core/core.dart';
import 'package:mechmate_app/features/auth/providers/auth_provider.dart';
import 'package:mechmate_app/shared/widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;
  UserRole _role = UserRole.owner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _role = args?['role'] as UserRole? ?? UserRole.owner;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AppAuthProvider>();
    final ok = await auth.signIn(_emailCtrl.text, _passwordCtrl.text, _role);
    if (!mounted) return;
    if (ok && auth.userModel != null) {
      final route = auth.userModel!.role == UserRole.owner
          ? AppRoutes.ownerMain
          : AppRoutes.mechanicMain;
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage!),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  String get _registerRoute => _role == UserRole.owner
      ? AppRoutes.registerOwner
      : AppRoutes.registerMechanic;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AppAuthProvider>();

    return LoadingOverlay(
      isLoading: auth.isLoading,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
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
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _role == UserRole.owner
                                ? Icons.directions_car_rounded
                                : Icons.build_rounded,
                            size: 16,
                            color: AppColors.primaryOrange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _role == UserRole.owner
                                ? 'Vehicle Owner'
                                : 'Workshop Mechanic',
                            style: const TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.rajdhani(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textLightPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to continue to MechMate',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                      ),
                    ),
                    const SizedBox(height: 36),
                    AppTextField(
                      controller: _emailCtrl,
                      label: 'Email Address',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.email,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _passwordCtrl,
                      label: 'Password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.done,
                      validator: AppValidators.password,
                      suffix: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotDialog,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Sign In',
                      onPressed: _submit,
                      isLoading: auth.isLoading,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                              context, _registerRoute,
                              arguments: {'role': _role}),
                          child: const Text(
                            'Register',
                            style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Enter your email to receive a password reset link.'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration:
                  const InputDecoration(labelText: 'Email Address'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final auth = context.read<AppAuthProvider>();
              await auth.resetPassword(ctrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Reset link sent!'),
                  backgroundColor: AppColors.success,
                ));
              }
            },
            child: const Text('Send',
                style: TextStyle(color: AppColors.primaryOrange)),
          ),
        ],
      ),
    );
  }
}
