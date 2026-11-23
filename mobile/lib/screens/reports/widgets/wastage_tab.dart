import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../services/reports_service.dart';

class WastageTab extends StatelessWidget {
  final WastageSummary summary;

  const WastageTab({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Wastage Card
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
                  'TOTAL WASTAGE & DAMAGE LOSS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFD5D5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(summary.totalWastageLoss),
                  style: AppTypography.heroAmount,
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Wastage by Reason Breakdown
          const Text(
            'Loss by Wastage Reason',
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: 10),
          if (summary.lossByReason.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppDimens.cardDecoration(),
              child: const Center(
                child: Text(
                  'No wastage recorded in this date range.',
                  style: AppTypography.bodySmall,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDimens.cardDecoration(),
              child: Column(
                children: summary.lossByReason.entries.map((e) {
                  final percent = summary.totalWastageLoss > 0
                      ? (e.value / summary.totalWastageLoss) * 100
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              e.key,
                              style: AppTypography.cardTitle.copyWith(
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${CurrencyFormatter.format(e.value)} (${percent.toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (percent / 100).clamp(0.0, 1.0),
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.error,
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

          // Detailed Wastage Log
          const Text(
            'Wastage History Records',
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: 10),
          if (summary.records.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppDimens.cardDecoration(),
              child: const Center(
                child: Text(
                  'No records found.',
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
                itemCount: summary.records.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, index) {
                  final r = summary.records[index];
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
                                r.productName,
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${r.quantity} ${r.unit} • Reason: ${r.reason}${r.notes != null ? ' (${r.notes})' : ''}',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                DateFormatter.formatDateTime(r.createdAt),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(r.totalLoss),
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
