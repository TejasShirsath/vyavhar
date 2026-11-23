import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/reports_provider.dart';
import 'widgets/date_range_selector_bar.dart';
import 'widgets/expenses_tab.dart';
import 'widgets/profit_loss_tab.dart';
import 'widgets/sales_tab.dart';
import 'widgets/stock_valuation_tab.dart';
import 'widgets/wastage_tab.dart';

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().loadAllReports();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                'Business Reports',
                style: AppTypography.brandTitle,
              ),
            ),

            // Two Date Selectors: Start Date (From) and End Date (To)
            const DateRangeSelectorBar(),
            const SizedBox(height: 8),

            // Sub Tab Selector
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.r12),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppDimens.r8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Profit & Loss'),
                  Tab(text: 'Sales'),
                  Tab(text: 'Expenses'),
                  Tab(text: 'Wastage'),
                  Tab(text: 'Stock Value'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Content Views
            Expanded(
              child: reports.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        reports.profitLoss != null
                            ? ProfitLossTab(summary: reports.profitLoss!)
                            : const Center(
                                child: Text('Loading profit & loss...'),
                              ),
                        reports.salesReport != null
                            ? SalesTab(summary: reports.salesReport!)
                            : const Center(
                                child: Text('Loading sales report...'),
                              ),
                        const ExpensesTab(),
                        reports.wastage != null
                            ? WastageTab(summary: reports.wastage!)
                            : const Center(
                                child: Text('Loading wastage report...'),
                              ),
                        reports.stockValuation != null
                            ? StockValuationTab(
                                summary: reports.stockValuation!,
                              )
                            : const Center(
                                child: Text('Loading stock valuation...'),
                              ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
