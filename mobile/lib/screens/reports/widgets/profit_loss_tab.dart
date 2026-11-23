import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../services/reports_service.dart';

class ProfitLossTab extends StatelessWidget {
  final ProfitLossSummary summary;

  const ProfitLossTab({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isProfit = summary.netProfit >= 0;
    final totalMoneyOut =
        summary.costOfGoodsSold + summary.totalExpenses + summary.wastageLoss;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Big Hero Card: Final Profit / Loss in Plain Language
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isProfit ? AppColors.primary : AppColors.error,
              borderRadius: BorderRadius.circular(AppDimens.r20),
              boxShadow: [
                BoxShadow(
                  color: (isProfit ? AppColors.primary : AppColors.error)
                      .withValues(alpha: 0.24),
                  offset: const Offset(0, 6),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isProfit ? 'TOTAL PROFIT (EARNING)' : 'TOTAL LOSS',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppDimens.rFull),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isProfit
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isProfit ? 'Profitable' : 'In Loss',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  CurrencyFormatter.format(summary.netProfit.abs()),
                  style: AppTypography.heroAmount,
                ),
                const SizedBox(height: 14),

                // Quick 2-pill snapshot: Total Sales vs Total Costs
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimens.r12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSimpleStat(
                        icon: Icons.call_received,
                        label: 'Total Sales (In)',
                        amount: CurrencyFormatter.format(
                          summary.totalSalesRevenue,
                        ),
                        iconColor: const Color(0xFF81C784),
                      ),
                      Container(width: 1, height: 28, color: Colors.white30),
                      _buildSimpleStat(
                        icon: Icons.call_made,
                        label: 'Total Costs (Out)',
                        amount: CurrencyFormatter.format(totalMoneyOut),
                        iconColor: const Color(0xFFFF8A80),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Simple Visual Step-by-Step Breakdown
          const Text('Summary', style: AppTypography.sectionTitle),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDimens.cardDecoration(),
            child: Column(
              children: [
                _buildSimpleStepRow(
                  icon: Icons.payments_outlined,
                  iconColor: AppColors.success,
                  title: 'Total Sales',
                  amount:
                      '+ ${CurrencyFormatter.format(summary.totalSalesRevenue)}',
                  amountColor: AppColors.success,
                ),
                const Divider(height: 20, color: AppColors.divider),
                _buildSimpleStepRow(
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFFF57C00),
                  title: 'Cost of Items',
                  amount:
                      '- ${CurrencyFormatter.format(summary.costOfGoodsSold)}',
                  amountColor: AppColors.error,
                ),
                const Divider(height: 20, color: AppColors.divider),
                _buildSimpleStepRow(
                  icon: Icons.receipt_long_outlined,
                  iconColor: AppColors.error,
                  title: 'Other Expenses (Rent, Bills, etc.)',
                  amount:
                      '- ${CurrencyFormatter.format(summary.totalExpenses)}',
                  amountColor: AppColors.error,
                ),
                if (summary.wastageLoss > 0) ...[
                  const Divider(height: 20, color: AppColors.divider),
                  _buildSimpleStepRow(
                    icon: Icons.delete_outline,
                    iconColor: AppColors.error,
                    title: 'Damaged Items',
                    amount:
                        '- ${CurrencyFormatter.format(summary.wastageLoss)}',
                    amountColor: AppColors.error,
                  ),
                ],
                const Divider(
                  height: 24,
                  thickness: 1.5,
                  color: AppColors.primary,
                ),
                _buildSimpleStepRow(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: isProfit ? AppColors.success : AppColors.error,
                  title: 'Total',
                  amount:
                      (isProfit ? '+ ' : '- ') +
                      CurrencyFormatter.format(summary.netProfit.abs()),
                  amountColor: isProfit ? AppColors.success : AppColors.error,
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSimpleStat({
    required IconData icon,
    required String label,
    required String amount,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimpleStepRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    required Color amountColor,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: amountColor,
          ),
        ),
      ],
    );
  }
}
