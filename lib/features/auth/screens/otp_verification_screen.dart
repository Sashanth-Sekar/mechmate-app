import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mechmate_app/core/core.dart';
import 'package:mechmate_app/features/auth/providers/auth_provider.dart';
import 'package:mechmate_app/shared/widgets/widgets.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpCtrl = TextEditingController();
  Map<String, dynamic>? _registrationData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registrationData ??= ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyAndRegister() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid 6-digit OTP.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final auth = context.read<AppAuthProvider>();
    
    // Step 1: Verify OTP
    final isOtpValid = await auth.verifyOTP(otp);
    if (!mounted) return;

    if (!isOtpValid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage ?? 'Invalid OTP.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    // Step 2: Proceed with Registration
    if (_registrationData != null) {
      bool success = false;
      final role = _registrationData!['role'] as UserRole;
      
      if (role == UserRole.owner) {
        success = await auth.registerOwner(
          name: _registrationData!['name'],
          email: _registrationData!['email'],
          password: _registrationData!['password'],
          phone: _registrationData!['phone'],
          geo: _registrationData!['geo'] ?? const GeoSelection.empty(),
        );
      } else if (role == UserRole.mechanic) {
        success = await auth.registerMechanic(
          name: _registrationData!['name'],
          email: _registrationData!['email'],
          password: _registrationData!['password'],
          phone: _registrationData!['phone'],
          geo: _registrationData!['geo'] ?? const GeoSelection.empty(),
          workshopName: _registrationData!['workshopName'] ?? '',
          workshopAddress: _registrationData!['workshopAddress'] ?? '',
          workshopPincode: _registrationData!['workshopPincode'] ?? '',
          openTime: _registrationData!['openTime'] ?? '09:00 AM',
          closeTime: _registrationData!['closeTime'] ?? '07:00 PM',
          vehicleTypes: List<String>.from(_registrationData!['vehicleTypes'] ?? []),
          services: List<String>.from(_registrationData!['services'] ?? []),
          workshopGeo: _registrationData!['workshopGeo'] ?? const GeoSelection.empty(),
        );
      }

      if (!mounted) return;

      if (success) {
        final route = role == UserRole.owner ? AppRoutes.ownerMain : AppRoutes.mechanicMain;
        Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed.'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AppAuthProvider>();

    final phone = _registrationData?['phone'] ?? '';
    final maskedPhone = phone.length >= 4 
      ? '******${phone.substring(phone.length - 4)}' 
      : phone;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.message_rounded,
                      size: 40,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verify Your Number',
                    style: GoogleFonts.rajdhani(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textDarkPrimary
                          : AppColors.textLightPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit code we sent to\n+91 $maskedPhone',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Simple OTP Input
                  TextField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32, 
                      letterSpacing: 16, 
                      fontWeight: FontWeight.bold
                    ),
                    decoration: InputDecoration(
                      hintText: '------',
                      counterText: '',
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Verify & Register',
                    onPressed: _verifyAndRegister,
                    isLoading: auth.isLoading,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive code? ",
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (!auth.isLoading && phone.isNotEmpty) {
                             auth.sendOTP(phone);
                          }
                        },
                        child: Text(
                          'Resend',
                          style: TextStyle(
                            color: auth.isLoading 
                                ? AppColors.textDarkMuted 
                                : AppColors.primaryOrange,
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
    );
  }
}
