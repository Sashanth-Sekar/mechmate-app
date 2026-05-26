import 'package:flutter/material.dart';
import 'package:mechmate_app/core/theme/theme.dart';

/// Wraps the entire app to catch unhandled rendering errors and show a
/// user-friendly fallback instead of the red error screen.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Replace the default Flutter error widget builder
    ErrorWidget.builder = (FlutterErrorDetails details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasError) {
          setState(() => _hasError = true);
        }
      });
      return const SizedBox.shrink();
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _RecoveryScreen(onRetry: () => setState(() => _hasError = false));
    }
    return widget.child;
  }
}

class _RecoveryScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const _RecoveryScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.primaryOrange.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textLightPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'An unexpected error occurred. Tap below to try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 180,
                height: 48,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
