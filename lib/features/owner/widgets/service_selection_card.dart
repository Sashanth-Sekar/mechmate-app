import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mechmate_app/core/theme/theme.dart';
import 'package:mechmate_app/features/owner/models/shop_model.dart';

class ServiceSelectionCard extends StatelessWidget {
  final List<ShopModel> shops;
  final VoidCallback onBookService;
  final VoidCallback onSeeAll;

  const ServiceSelectionCard({
    super.key,
    required this.shops,
    required this.onBookService,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final nearest = shops.isNotEmpty ? shops.first : null;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          decoration: BoxDecoration(
            color: const Color(0xFF11151C).withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Choose a service',
                        style: TextStyle(
                          color: AppColors.textDarkPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Rajdhani',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onSeeAll,
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ServicePill(
                      icon: Icons.car_repair_rounded,
                      label: 'Repair',
                      selected: true,
                      onTap: onBookService,
                    ),
                    const SizedBox(width: 10),
                    _ServicePill(
                      icon: Icons.oil_barrel_rounded,
                      label: 'Service',
                      onTap: onBookService,
                    ),
                    const SizedBox(width: 10),
                    _ServicePill(
                      icon: Icons.emergency_rounded,
                      label: 'SOS',
                      onTap: onBookService,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.055),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: AppColors.orangeGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.garage_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nearest?.name ?? 'Nearby workshops loading',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textDarkPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              nearest == null
                                  ? 'We will show the closest garage here'
                                  : '${nearest.rating} rating • ${nearest.distanceLabel} away',
                              style: const TextStyle(
                                color: AppColors.textDarkSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: nearest == null ? null : onBookService,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Book'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServicePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ServicePill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected
            ? AppColors.primaryOrange.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? const Color(0xFFFFD166)
                      : AppColors.textDarkSecondary,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.textDarkPrimary
                        : AppColors.textDarkSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
