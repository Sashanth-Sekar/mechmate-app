import 'package:flutter/material.dart';
import 'package:mechmate_app/core/theme/theme.dart';

export 'section_header.dart';
export 'status_badge.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x88000000),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryOrange),
                ),
              ),
            ),
          ),
      ],
    );
  }
}


