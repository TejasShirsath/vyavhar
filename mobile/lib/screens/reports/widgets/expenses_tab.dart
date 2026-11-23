import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../providers/reports_provider.dart';
import 'add_expense_dialog.dart';

class ExpensesTab extends StatelessWidget {
  const ExpensesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportsProvider>();
    final totalExpenses = reports.totalExpenses;
    final byCategory = reports.expensesByCategory;
    final expenses = reports.expensesList;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Expenses Hero Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(AppDimens.r20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.24),
                  offset: const Offset(0, 6),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL SHOP EXPENSES (SPENT)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFD5D5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(totalExpenses),
                  style: AppTypography.heroAmount,
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Add Expense Button
          CustomButton(
            text: 'Add Business Expense',
            icon: Icons.add,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddExpenseDialog(),
              );
            },
          ),
          const SizedBox(height: 20),

          // Category Breakdown
          const Text('Expenses by Category', style: AppTypography.sectionTitle),
          const SizedBox(height: 10),
          if (byCategory.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppDimens.cardDecoration(),
              child: const Center(
                child: Text(
                  'No expenses recorded in this period.',
                  style: AppTypography.bodySmall,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDimens.cardDecoration(),
              child: Column(
                children: byCategory.entries.map((entry) {
                  final percent = totalExpenses > 0
                      ? (entry.value / totalExpenses) * 100
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: AppTypography.cardTitle.copyWith(
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${CurrencyFormatter.format(entry.value)} (${percent.toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (percent / 100).clamp(0.0, 1.0),
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 20),

          // Expenses Log
          const Text('Expense Transactions', style: AppTypography.sectionTitle),
          const SizedBox(height: 10),
          if (expenses.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppDimens.cardDecoration(),
              child: const Center(
                child: Text(
                  'No expense transactions found.',
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
                itemCount: expenses.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, index) {
                  final exp = expenses[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exp.title,
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${exp.category} • ${DateFormatter.format(exp.date)}',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                              if (exp.notes != null && exp.notes!.isNotEmpty)
                                Text(
                                  exp.notes!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '-${CurrencyFormatter.format(exp.amount)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
