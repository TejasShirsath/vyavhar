import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/activity_item.dart';

class RecentActivityList extends StatelessWidget {
  final List<BusinessActivityItem> activities;
  final VoidCallback onViewAll;
  final ValueChanged<BusinessActivityItem>? onActivityTap;

  const RecentActivityList({
    super.key,
    required this.activities,
    required this.onViewAll,
    this.onActivityTap,
  });

  IconData _getIcon(ActivityType type) {
    switch (type) {
      case ActivityType.sale:
        return Icons.receipt_long;
      case ActivityType.purchase:
        return Icons.add_business_outlined;
      case ActivityType.wastage:
        return Icons.delete_outline;
      case ActivityType.expense:
        return Icons.account_balance_wallet_outlined;
      case ActivityType.initialStock:
      case ActivityType.productCreated:
        return Icons.inventory_2_outlined;
      case ActivityType.productDeleted:
        return Icons.remove_circle_outline;
    }
  }

  Color _getIconColor(ActivityType type) {
    switch (type) {
      case ActivityType.sale:
        return AppColors.primary;
      case ActivityType.purchase:
        return AppColors.success;
      case ActivityType.wastage:
        return AppColors.error;
      case ActivityType.expense:
        return const Color(0xFFD97706); // Warm Amber
      case ActivityType.initialStock:
      case ActivityType.productCreated:
        return const Color(0xFF2563EB); // Royal Blue
      case ActivityType.productDeleted:
        return AppColors.textMuted;
    }
  }

  Color _getBadgeBgColor(ActivityType type) {
    switch (type) {
      case ActivityType.sale:
        return AppColors.primaryContainer;
      case ActivityType.purchase:
        return AppColors.successLight;
      case ActivityType.wastage:
        return AppColors.errorLight;
      case ActivityType.expense:
        return const Color(0xFFFEF3C7); // Light Amber
      case ActivityType.initialStock:
      case ActivityType.productCreated:
        return const Color(0xFFEFF6FF); // Light Blue
      case ActivityType.productDeleted:
        return AppColors.surfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: AppTypography.sectionTitle,
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                children: [
                  Text(
                    'View all',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: AppDimens.cardDecoration(),
            child: const Center(
              child: Text(
                'No activity recorded yet.',
                style: AppTypography.bodySmall,
              ),
            ),
          )
        else
          Container(
            decoration: AppDimens.cardDecoration(),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.take(6).length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppColors.divider,
                indent: 62,
              ),
              itemBuilder: (context, index) {
                final item = activities[index];
                final icon = _getIcon(item.type);
                final iconColor = _getIconColor(item.type);
                final badgeBg = _getBadgeBgColor(item.type);

                return InkWell(
                  onTap: () => onActivityTap?.call(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Activity Icon badge
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: badgeBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            size: 18,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Title & Subtitle / Time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: AppTypography.cardTitle.copyWith(fontSize: 13.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${item.subtitle} • ${DateFormatter.formatTime(item.timestamp)}',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Right Side: Amount and/or status badge
                        if (item.amount != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item.amountPrefix ?? ''}${CurrencyFormatter.format(item.amount!)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: item.amountColor ?? AppColors.textPrimary,
                                ),
                              ),
                              if (item.badgeText != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    item.badgeText!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: item.badgeColor ?? AppColors.textMuted,
                                    ),
                                  ),
                                ),
                            ],
                          )
                        else if (item.badgeText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.badgeText!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: iconColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
