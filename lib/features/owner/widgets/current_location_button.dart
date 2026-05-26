import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mechmate_app/core/theme/theme.dart';

class CurrentLocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CurrentLocationButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: const Color(0xFF151922).withValues(alpha: 0.82),
          shape: CircleBorder(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: IconButton(
            onPressed: onPressed,
            tooltip: 'Current location',
            icon: const Icon(
              Icons.my_location_rounded,
              color: AppColors.primaryOrange,
            ),
          ),
        ),
      ),
    );
  }
}
