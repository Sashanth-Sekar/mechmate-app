import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mechmate_app/core/theme/theme.dart';
import 'package:mechmate_app/shared/services/services.dart';

/// Shows a persistent banner when the device is offline.
///
/// Place this at the top of your widget tree (e.g. inside Scaffold body).
class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  late bool _isOnline;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    _isOnline = ConnectivityService.instance.isOnline;
    _sub = ConnectivityService.instance.onlineStream.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isOnline ? 0 : 36,
          color: AppColors.error,
          child: _isOnline
              ? const SizedBox.shrink()
              : const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'No Internet Connection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
