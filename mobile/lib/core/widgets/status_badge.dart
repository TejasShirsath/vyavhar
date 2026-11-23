import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isWarning;
  final bool isError;
  final bool isSuccess;

  const StatusBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.isWarning = false,
    this.isError = false,
    this.isSuccess = false,
  });

  factory StatusBadge.lowStock() {
    return const StatusBadge(
      label: 'Low Stock',
      backgroundColor: AppColors.warningLight,
      textColor: AppColors.warning,
    );
  }

  factory StatusBadge.outOfStock() {
    return const StatusBadge(
      label: 'Out of Stock',
      backgroundColor: AppColors.errorLight,
      textColor: AppColors.error,
    );
  }

  factory StatusBadge.paid() {
    return const StatusBadge(
      label: 'Paid',
      backgroundColor: AppColors.successLight,
      textColor: AppColors.success,
    );
  }

  factory StatusBadge.pending() {
    return const StatusBadge(
      label: 'Pending',
      backgroundColor: AppColors.errorLight,
      textColor: AppColors.error,
    );
  }

  factory StatusBadge.partial() {
    return const StatusBadge(
      label: 'Partial',
      backgroundColor: AppColors.warningLight,
      textColor: AppColors.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bg = backgroundColor ?? AppColors.primaryContainer;
    Color fg = textColor ?? AppColors.primary;

    if (isWarning) {
      bg = AppColors.warningLight;
      fg = AppColors.warning;
    } else if (isError) {
      bg = AppColors.errorLight;
      fg = AppColors.error;
    } else if (isSuccess) {
      bg = AppColors.successLight;
      fg = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.rFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
