import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mechmate_app/core/core.dart';
import 'package:mechmate_app/features/auth/providers/auth_provider.dart';
import 'package:mechmate_app/shared/widgets/widgets.dart';

class RegisterMechanicScreen extends StatefulWidget {
  const RegisterMechanicScreen({super.key});

  @override
  State<RegisterMechanicScreen> createState() =>
      _RegisterMechanicScreenState();
}

class _RegisterMechanicScreenState extends State<RegisterMechanicScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Account fields ──────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // ── Workshop fields ─────────────────────────────────────────────
  final _workshopCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _openCtrl = TextEditingController(text: '09:00 AM');
  final _closeCtrl = TextEditingController(text: '07:00 PM');

  bool _showPwd = false;
  bool _showConfirm = false;
  int _step = 0; // 0=account, 1=workshop, 2=services

  String _selectedCountryCode = '+91';
  final List<String> _countryCodes = ['+91', '+1', '+44', '+61', '+971'];

  final Set<String> _vehicleTypes = {'Car'};
  final Set<String> _selectedServices = {};

  /// Personal / account location (Step 0)
  GeoSelection _geo = const GeoSelection.empty();

  /// Workshop geographic location (Step 1)
  GeoSelection _workshopGeo = const GeoSelection.empty();

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _emailCtrl, _phoneCtrl, _passwordCtrl, _confirmCtrl,
      _workshopCtrl, _addressCtrl, _pincodeCtrl,
      _openCtrl, _closeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Submit ───────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_geo.isComplete) {
      _showError('Please select your personal Country, State/Province, and City.');
      return;
    }

    if (!_workshopGeo.isComplete) {
      _showError('Please select the workshop Country, State/Province, and City.');
      return;
    }

    final auth = context.read<AppAuthProvider>();
    final phone = '$_selectedCountryCode${_phoneCtrl.text.trim()}';

    final ok = await auth.registerMechanic(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone: phone,
      geo: _geo,
      workshopName: _workshopCtrl.text.trim(),
      workshopAddress: _addressCtrl.text.trim(),
      workshopPincode: _pincodeCtrl.text.trim(),
      openTime: _openCtrl.text.trim(),
      closeTime: _closeCtrl.text.trim(),
      vehicleTypes: _vehicleTypes.toList(),
      services: _selectedServices.toList(),
      workshopGeo: _workshopGeo,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.mechanicMain, (_) => false);
    } else if (auth.errorMessage != null) {
      _showError(auth.errorMessage!);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Continue button logic ────────────────────────────────────────

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;

    // Step 0 → 1: validate personal geo
    if (_step == 0 && !_geo.isComplete) {
      _showError('Please select your Country, State/Province, and City.');
      return;
    }

    // Step 1 → 2: validate workshop geo
    if (_step == 1 && !_workshopGeo.isComplete) {
      _showError('Please select the workshop Country, State/Province, and City.');
      return;
    }

    setState(() => _step++);
  }

  // ── Build ────────────────────────────────────────────────────────

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
                setState(() => _step--);
              }
            },
          ),
          title: Text(
            'Register Workshop',
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
                    _StepBar(current: _step, total: 3, isDark: isDark),
                    const SizedBox(height: 28),
                    if (_step == 0) ..._step0(isDark)
                    else if (_step == 1) ..._step1(isDark)
                    else ..._step2(isDark),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: _step < 2 ? 'Continue' : 'Create Account',
                      icon: _step < 2
                          ? Icons.arrow_forward_rounded
                          : Icons.check_rounded,
                      onPressed: _step < 2 ? _onContinue : _submit,
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
                              context, AppRoutes.login,
                              arguments: {'role': UserRole.mechanic}),
                          child: const Text('Login',
                              style: TextStyle(
                                  color: AppColors.primaryOrange,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
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

  // ── Step 0: Account & Personal Location ─────────────────────────

  List<Widget> _step0(bool isDark) => [
        Text('Your Account',
            style: GoogleFonts.rajdhani(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textLightPrimary)),
        const SizedBox(height: 20),
        AppTextField(
          controller: _nameCtrl,
          label: 'Your Full Name',
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
                icon: const Icon(Icons.keyboard_arrow_down,
                    size: 20, color: AppColors.primaryOrange),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textLightPrimary,
                ),
                dropdownColor:
                    isDark ? AppColors.darkCard : AppColors.lightSurface,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedCountryCode = newValue);
                  }
                },
                items: _countryCodes
                    .map<DropdownMenuItem<String>>(
                        (v) => DropdownMenuItem<String>(
                            value: v, child: Text(v)))
                    .toList(),
              ),
            ),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.next,
          validator: AppValidators.phone,
        ),
        const SizedBox(height: 20),
        _SectionHeading(
          icon: Icons.person_pin_circle_outlined,
          label: 'Your Location',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        GeoSelector(
          enabled: true,
          initial: _geo,
          onChanged: (next) => setState(() => _geo = next),
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
                _showPwd
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20),
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
                size: 20),
            onPressed: () => setState(() => _showConfirm = !_showConfirm),
          ),
        ),
      ];

  // ── Step 1: Workshop Details & Location ──────────────────────────

  List<Widget> _step1(bool isDark) => [
        Text('Workshop Details',
            style: GoogleFonts.rajdhani(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textLightPrimary)),
        const SizedBox(height: 20),
        AppTextField(
          controller: _workshopCtrl,
          label: 'Workshop Name',
          prefixIcon: Icons.store_outlined,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              AppValidators.required(v, field: 'Workshop name'),
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _addressCtrl,
          label: 'Street Address',
          prefixIcon: Icons.location_on_outlined,
          textInputAction: TextInputAction.next,
          maxLines: 2,
          validator: (v) => AppValidators.required(v, field: 'Address'),
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: _pincodeCtrl,
          label: 'Pincode / Postal Code',
          prefixIcon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          textInputAction: TextInputAction.next,
          validator: AppValidators.pincode,
        ),
        const SizedBox(height: 20),
        _SectionHeading(
          icon: Icons.store_mall_directory_outlined,
          label: 'Workshop Location',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        GeoSelector(
          enabled: true,
          initial: _workshopGeo,
          onChanged: (next) => setState(() => _workshopGeo = next),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: AppTextField(
              controller: _openCtrl,
              label: 'Opens At',
              prefixIcon: Icons.access_time_rounded,
              readOnly: true,
              onTap: () => _pickTime(_openCtrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppTextField(
              controller: _closeCtrl,
              label: 'Closes At',
              prefixIcon: Icons.access_time_outlined,
              readOnly: true,
              onTap: () => _pickTime(_closeCtrl),
            ),
          ),
        ]),
      ];

  // ── Step 2: Services & Vehicle Types ────────────────────────────

  List<Widget> _step2(bool isDark) => [
        Text('Services & Vehicles',
            style: GoogleFonts.rajdhani(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textLightPrimary)),
        const SizedBox(height: 20),
        Text('Vehicle Types Served',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: ['Car', 'Bike'].map((v) {
            final selected = _vehicleTypes.contains(v);
            return FilterChip(
              label: Text(v),
              selected: selected,
              onSelected: (s) =>
                  setState(() => s ? _vehicleTypes.add(v) : _vehicleTypes.remove(v)),
              selectedColor: AppColors.primaryOrange.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primaryOrange,
              labelStyle: TextStyle(
                color: selected
                    ? AppColors.primaryOrange
                    : (isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('Services Offered',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: ServiceTypes.all.map((s) {
            final selected = _selectedServices.contains(s);
            return FilterChip(
              label: Text(s),
              selected: selected,
              onSelected: (v) => setState(() =>
                  v ? _selectedServices.add(s) : _selectedServices.remove(s)),
              selectedColor: AppColors.primaryOrange.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primaryOrange,
              labelStyle: TextStyle(
                fontSize: 12,
                color: selected
                    ? AppColors.primaryOrange
                    : (isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary),
              ),
            );
          }).toList(),
        ),
      ];

  Future<void> _pickTime(TextEditingController ctrl) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null && mounted) {
      ctrl.text = t.format(context);
    }
  }
}

// ── Shared helpers ─────────────────────────────────────────────────

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _SectionHeading({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryOrange),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.textDarkSecondary
                : AppColors.textLightSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _StepBar extends StatelessWidget {
  final int current;
  final int total;
  final bool isDark;

  const _StepBar(
      {required this.current, required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i == current;
        final done = i < current;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                gradient: active || done ? AppColors.orangeGradient : null,
                color: active || done
                    ? null
                    : (isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}
