import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../services/reports_service.dart';

class StockValuationTab extends StatelessWidget {
  final StockValuationSummary summary;

  const StockValuationTab({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Valuation Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimens.r20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.24),
                  offset: const Offset(0, 6),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL STOCK VALUE IN SHOP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(summary.totalStockValue),
                  style: AppTypography.heroAmount,
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // All Products Stock Valuation Ranked by Value
          const Text(
            'All Products Stock Valuation',
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              // Sort products descending by stockValue to rank them
              final rankedProducts = List.from(summary.products)
                ..sort((a, b) => b.stockValue.compareTo(a.stockValue));

              return Container(
                decoration: AppDimens.cardDecoration(),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rankedProducts.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (context, index) {
                    final p = rankedProducts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? AppColors.primary
                                  : AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '#${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: index == 0
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: AppTypography.cardTitle.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${p.currentStock.toStringAsFixed(p.currentStock % 1 == 0 ? 0 : 1)} ${p.unit}',
                                      style: AppTypography.bodySmall,
                                    ),
                                    if (p.isOutOfStock) ...[
                                      const SizedBox(width: 6),
                                      StatusBadge.outOfStock(),
                                    ] else if (p.isLowStock) ...[
                                      const SizedBox(width: 6),
                                      StatusBadge.lowStock(),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(p.stockValue),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Cost: ${CurrencyFormatter.format(p.purchasePrice)}/${p.unit}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(
    String label,
    String value, {
    bool isWarning = false,
    bool isError = false,
  }) {
    Color col = Colors.white;
    if (isWarning) col = const Color(0xFFFFD580);
    if (isError) col = const Color(0xFFFF9999);

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: col,
          ),
        ),
      ],
    );
  }
}
