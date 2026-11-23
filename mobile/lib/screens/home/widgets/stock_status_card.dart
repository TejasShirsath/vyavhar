import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../inventory/filtered_stock_list_screen.dart';

class StockStatusCard extends StatelessWidget {
  final int lowStockCount;
  final int outOfStockCount;
  final VoidCallback onViewAll;

  const StockStatusCard({
    super.key,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final hasLowStock = lowStockCount > 0;
    final hasOutOfStock = outOfStockCount > 0;

    // Only display when there are actually low stock or out of stock items
    if (!hasLowStock && !hasOutOfStock) {
      return const SizedBox.shrink();
    }

    final List<Widget> statusRows = [];

    // Low stock warning row
    if (hasLowStock) {
      statusRows.add(
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FilteredStockListScreen(
                  filterType: StockFilterType.lowStock,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(AppDimens.r16),
            bottom: hasOutOfStock ? Radius.zero : const Radius.circular(AppDimens.r16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.warningLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 18,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Low Stock',
                    style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  '$lowStockCount items',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Divider between rows if both are present
    if (hasLowStock && hasOutOfStock) {
      statusRows.add(
        const Divider(height: 1, color: AppColors.divider, indent: 62),
      );
    }

    // Out of stock warning row
    if (hasOutOfStock) {
      statusRows.add(
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FilteredStockListScreen(
                  filterType: StockFilterType.outOfStock,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.vertical(
            top: hasLowStock ? Radius.zero : const Radius.circular(AppDimens.r16),
            bottom: const Radius.circular(AppDimens.r16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.errorLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Out of Stock',
                    style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  '$outOfStockCount items',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Stock Status',
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
        Container(
          decoration: AppDimens.cardDecoration(),
          child: Column(
            children: statusRows,
          ),
        ),
      ],
    );
  }
}
