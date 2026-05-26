import 'package:flutter/material.dart';
import 'package:mechmate_app/core/theme/theme.dart';
import 'package:mechmate_app/features/owner/models/shop_model.dart';

class WorkshopListItem extends StatelessWidget {
  final ShopModel shop;
  final bool selected;
  final VoidCallback onTap;

  const WorkshopListItem({
    super.key,
    required this.shop,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF25201A) : AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? const Color(0xFFFFD166)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.orangeGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.garage_rounded, color: Colors.white),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shop.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textDarkPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Icon(
                            shop.isOpen
                                ? Icons.verified_rounded
                                : Icons.schedule_rounded,
                            color: shop.isOpen
                                ? AppColors.success
                                : AppColors.textDarkMuted,
                            size: 17,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.warning,
                            size: 15,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            shop.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.textDarkSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.near_me_rounded,
                            color: AppColors.primaryOrange,
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            shop.distanceLabel,
                            style: const TextStyle(
                              color: AppColors.textDarkSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        shop.services.take(3).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textDarkMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
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
