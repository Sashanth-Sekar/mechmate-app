import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mechmate_app/core/core.dart';
import 'package:mechmate_app/features/auth/providers/auth_provider.dart';
import 'package:mechmate_app/features/owner/models/vehicle_model.dart';
import 'package:mechmate_app/shared/widgets/widgets.dart';

class RegisterOwnerScreen extends StatefulWidget {
  const RegisterOwnerScreen({super.key});

  @override
  State<RegisterOwnerScreen> createState() => _RegisterOwnerScreenState();
}

class _RegisterOwnerScreenState extends State<RegisterOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _vehicleNumCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  GeoSelection _geo = const GeoSelection.empty();

  bool _showPwd = false;
  bool _showConfirm = false;
  String _vehicleType = 'Car';
  int _step = 0; // 0=account, 1=vehicle

  String _selectedCountryCode = '+91';
  final List<String> _countryCodes = ['+91', '+1', '+44', '+61', '+971'];

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _passwordCtrl,
      _confirmCtrl,
      _vehicleNumCtrl,
      _makeCtrl,
      _modelCtrl,
      _yearCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vehicleError = _validateVehicleDetails();
    if (vehicleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vehicleError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = context.read<AppAuthProvider>();
    final phone = '$_selectedCountryCode${_phoneCtrl.text.trim()}';

    if (!_geo.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please select Country, State/Province, and City.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ok = await auth.registerOwner(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone: phone,
      initialVehicle: _buildInitialVehicle(),
      geo: _geo,
    );
    if (!mounted) return;

    if (ok) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.ownerMain,
        (_) => false,
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool get _hasVehicleDetails =>
      _vehicleNumCtrl.text.trim().isNotEmpty ||
      _makeCtrl.text.trim().isNotEmpty ||
      _modelCtrl.text.trim().isNotEmpty ||
      _yearCtrl.text.trim().isNotEmpty;

  String? _validateVehicleDetails() {
    if (!_hasVehicleDetails) return null;

    return AppValidators.vehicleNumber(_vehicleNumCtrl.text) ??
        AppValidators.required(_makeCtrl.text, field: 'Make') ??
        AppValidators.required(_modelCtrl.text, field: 'Model') ??
        AppValidators.year(_yearCtrl.text);
  }

  VehicleModel? _buildInitialVehicle() {
    if (!_hasVehicleDetails) return null;

    final number = _vehicleNumCtrl.text.trim().toUpperCase();
    final id = number.replaceAll(RegExp(r'\s+'), '');
    return VehicleModel(
      id: id,
      type: _vehicleType,
      number: number,
      make: _makeCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      year: int.tryParse(_yearCtrl.text.trim()) ?? DateTime.now().year,
    );
  }

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
              if (_step == 0) {
                if (mounted) Navigator.pop(context);
              } else {
                setState(() => _step = 0);
              }
            },
          ),
          title: Text(
            'Register as Owner',
            style: GoogleFonts.rajdhani(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textDarkPrimary
                  : AppColors.textLightPrimary,
            ),
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
                    _StepIndicator(current: _step, isDark: isDark),
                    const SizedBox(height: 28),
                    if (_step == 0)
                      ..._accountStep(isDark)
                    else
                      ..._vehicleStep(isDark),
                    const SizedBox(height: 28),
                    if (_step == 0)
                      PrimaryButton(
                        label: 'Continue',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _step = 1);
                          }
                        },
                      )
                    else
                      PrimaryButton(
                        label: 'Create Account',
                        icon: Icons.check_rounded,
                        onPressed: _submit,
                        isLoading: auth.isLoading,
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.login,
                            arguments: {'role': UserRole.owner},
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _accountStep(bool isDark) => [
    Text(
      'Account Details',
      style: GoogleFonts.rajdhani(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
      ),
    ),
    const SizedBox(height: 20),
    AppTextField(
      controller: _nameCtrl,
      label: 'Full Name',
      prefixIcon: Icons.person_outline_rounded,
      textInputAction: TextInputAction.next,
      validator: (v) => AppValidators.required(v, field: 'Name'),
    ),
    const SizedBox(height: 14),
    AppTextField(
      controller: _emailCtrl,
      label: 'Email Address',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: AppValidators.email,
    ),
    const SizedBox(height: 14),
    AppTextField(
      controller: _phoneCtrl,
      label: 'Phone Number',
      prefixWidget: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 8.0),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedCountryCode,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.primaryOrange,
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textDarkPrimary
                  : AppColors.textLightPrimary,
            ),
            dropdownColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedCountryCode = newValue;
                });
              }
            },
            items: _countryCodes.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
          ),
        ),
      ),
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: AppValidators.phone,
    ),
    const SizedBox(height: 16),

    GeoSelector(
      enabled: true,
      initial: _geo,
      onChanged: (next) => setState(() => _geo = next),
      // If you want to visually emphasize requiredness later, we can add another prop.
    ),

    const SizedBox(height: 14),
    AppTextField(
      controller: _passwordCtrl,
      label: 'Password',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: !_showPwd,
      textInputAction: TextInputAction.next,
      validator: AppValidators.password,
      suffix: IconButton(
        icon: Icon(
          _showPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
        ),
        onPressed: () => setState(() => _showPwd = !_showPwd),
      ),
    ),
    const SizedBox(height: 14),
    AppTextField(
      controller: _confirmCtrl,
      label: 'Confirm Password',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: !_showConfirm,
      textInputAction: TextInputAction.done,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Confirm your password';
        if (v != _passwordCtrl.text) return 'Passwords do not match';
        return null;
      },
      suffix: IconButton(
        icon: Icon(
          _showConfirm
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 20,
        ),
        onPressed: () => setState(() => _showConfirm = !_showConfirm),
      ),
    ),
  ];

  List<Widget> _vehicleStep(bool isDark) => [
    Text(
      'Vehicle Details',
      style: GoogleFonts.rajdhani(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
      ),
    ),
    Text(
      '(Optional – you can add this later)',
      style: TextStyle(
        fontSize: 12,
        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
      ),
    ),
    const SizedBox(height: 20),
    Text(
      'Vehicle Type',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: isDark
            ? AppColors.textDarkSecondary
            : AppColors.textLightSecondary,
      ),
    ),
    const SizedBox(height: 10),
    Row(
      children: ['Car', 'Bike'].map((t) {
        final selected = _vehicleType == t;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: t == 'Car' ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _vehicleType = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.orangeGradient : null,
                  color: selected
                      ? null
                      : (isDark ? AppColors.darkCard : AppColors.lightSurface),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t == 'Car'
                          ? Icons.directions_car_rounded
                          : Icons.two_wheeler_rounded,
                      size: 18,
                      color: selected ? Colors.white : AppColors.primaryOrange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : (isDark
                                  ? AppColors.textDarkPrimary
                                  : AppColors.textLightPrimary),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
    const SizedBox(height: 16),
    AppTextField(
      controller: _vehicleNumCtrl,
      label: 'Vehicle Number (e.g. MH12AB1234)',
      prefixIcon: Icons.pin_outlined,
      textInputAction: TextInputAction.next,
    ),
    const SizedBox(height: 14),
    AppTextField(
      controller: _makeCtrl,
      label: 'Make (e.g. Honda, Maruti)',
      prefixIcon: Icons.branding_watermark_outlined,
      textInputAction: TextInputAction.next,
    ),
    const SizedBox(height: 14),
    AppTextField(
      controller: _modelCtrl,
      label: 'Model (e.g. City, Swift)',
      prefixIcon: Icons.directions_car_outlined,
      textInputAction: TextInputAction.next,
    ),
    const SizedBox(height: 14),
    AppTextField(
      controller: _yearCtrl,
      label: 'Year (e.g. 2021)',
      prefixIcon: Icons.calendar_today_outlined,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      textInputAction: TextInputAction.done,
    ),
  ];
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final bool isDark;

  const _StepIndicator({required this.current, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(2, (i) {
        final active = i == current;
        final done = i < current;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 0 ? 8 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                gradient: active || done ? AppColors.orangeGradient : null,
                color: active || done
                    ? null
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}
