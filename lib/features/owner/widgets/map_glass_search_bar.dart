import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mechmate_app/core/theme/theme.dart';

class MapGlassSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool readOnly;

  const MapGlassSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Where do you need service?',
    this.onChanged,
    this.onTap,
    this.onClear,
    this.autofocus = false,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF11151C).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            style: const TextStyle(
              color: AppColors.textDarkPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: AppColors.primaryOrange,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: AppColors.textDarkSecondary,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primaryOrange,
              ),
              suffixIcon: controller != null && controller!.text.isNotEmpty
                  ? IconButton(
                      onPressed: onClear,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textDarkSecondary,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
