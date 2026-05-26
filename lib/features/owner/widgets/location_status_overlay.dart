import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mechmate_app/core/theme/theme.dart';

class LocationStatusOverlay extends StatelessWidget {
  final bool isLoading;
  final bool permissionDenied;
  final String? message;
  final VoidCallback onRetry;

  const LocationStatusOverlay({
    super.key,
    required this.isLoading,
    required this.permissionDenied,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && message == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF11151C).withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: AppColors.primaryOrange,
                    ),
                  )
                else
                  const Icon(
                    Icons.location_off_rounded,
                    color: AppColors.primaryOrange,
                    size: 30,
                  ),
                const SizedBox(height: 12),
                Text(
                  isLoading
                      ? 'Finding your precise location...'
                      : (message ?? 'Location unavailable'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textDarkPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isLoading) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(permissionDenied ? 'Try again' : 'Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
