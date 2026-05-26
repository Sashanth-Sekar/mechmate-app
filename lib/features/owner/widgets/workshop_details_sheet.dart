import 'package:mechmate_app/features/owner/owner.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mechmate_app/core/theme/theme.dart';

Future<void> showWorkshopDetailsSheet(BuildContext context, ShopModel shop) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => WorkshopDetailsSheet(shop: shop),
  );
}

class WorkshopDetailsSheet extends StatelessWidget {
  final ShopModel shop;

  const WorkshopDetailsSheet({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          decoration: BoxDecoration(
            color: const Color(0xFF11151C).withValues(alpha: 0.94),
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
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: AppColors.orangeGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.build_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            style: const TextStyle(
                              color: AppColors.textDarkPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Rajdhani',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.warning,
                                size: 16,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                shop.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: AppColors.textDarkSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.near_me_rounded,
                                color: AppColors.primaryOrange,
                                size: 15,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                shop.distanceLabel,
                                style: const TextStyle(
                                  color: AppColors.textDarkSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: shop.services
                      .map(
                        (service) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            service,
                            style: const TextStyle(
                              color: Color(0xFFFFD166),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (context.mounted) {
                          Navigator.pop(context); // Close sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateBookingScreen(shop: shop),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Book Service',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
