import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../providers/reports_provider.dart';
import '../../../services/reports_service.dart';

class DateFilterBar extends StatelessWidget {
  const DateFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportsProvider>();
    final currentFilter = reports.currentFilter;

    final filters = [
      {'filter': DateRangeFilter.today, 'label': 'Today'},
      {'filter': DateRangeFilter.yesterday, 'label': 'Yesterday'},
      {'filter': DateRangeFilter.last7Days, 'label': 'Last 7 Days'},
      {'filter': DateRangeFilter.last30Days, 'label': 'Last 30 Days'},
      {'filter': DateRangeFilter.thisMonth, 'label': 'This Month'},
      {'filter': DateRangeFilter.previousMonth, 'label': 'Previous Month'},
      {'filter': DateRangeFilter.custom, 'label': 'Custom'},
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final f = item['filter'] as DateRangeFilter;
          final label = item['label'] as String;
          final isSelected = f == currentFilter;

          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) async {
              if (f == DateRangeFilter.custom) {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (range != null) {
                  reports.setCustomRange(range.start, range.end);
                }
              } else {
                reports.setFilter(f);
              }
            },
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.rFull),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          );
        },
      ),
    );
  }
}
