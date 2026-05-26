import 'package:flutter/material.dart';
import 'package:mechmate_app/core/theme/theme.dart';
import 'package:mechmate_app/features/auth/models/user_model.dart';
import 'package:mechmate_app/shared/shared.dart';

Future<void> showEditProfileSheet(BuildContext context, UserModel user, bool isDark) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EditProfileSheet(user: user, isDark: isDark),
  );
}

class EditProfileSheet extends StatefulWidget {
  final UserModel user;
  final bool isDark;

  const EditProfileSheet({super.key, required this.user, required this.isDark});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _isSaving = false;
  late final UserApiService _apiService;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _apiService = UserApiService();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final updatedUser = await _apiService.updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      // We should ideally update the AppAuthProvider's userModel here if there's a setter,
      // but for MVP, we might just require a refresh or we can mutate if possible.
      // AppAuthProvider only exposes a getter for userModel. We can trigger a reload.
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated'), backgroundColor: AppColors.success));
      Navigator.pop(context, updatedUser);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: 
                FontWeight.bold,
                color: widget.isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
              ),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _nameCtrl,
              label: 'Full Name',
              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              validator: (v) => v == null || v.trim().isEmpty ? 'Phone is required' : null,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: PrimaryButton(
                label: 'Save Changes',
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
