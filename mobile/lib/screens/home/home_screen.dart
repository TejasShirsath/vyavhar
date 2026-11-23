import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/stat_card.dart';
import '../../models/activity_item.dart';
import '../../models/expense.dart';
import '../../models/invoice.dart';
import '../../models/stock_movement.dart';
import '../../models/wastage_record.dart';
import '../../providers/billing_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/reports_provider.dart';
import '../billing/invoice_detail_screen.dart';
import '../inventory/product_detail_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/due_status_card.dart';
import 'widgets/hero_sales_card.dart';
import 'widgets/recent_activity_list.dart';
import 'widgets/stock_status_card.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int> onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  double _dayExpenses = 0.0;
  double _dayWastage = 0.0;
  List<StockMovement> _stockMovements = [];
  List<WastageRecord> _wastageRecords = [];
  List<Expense> _allExpenses = [];

  void reloadHomeScreen() {
    _loadAllData();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
      _loadDayFinancials(_selectedDate);
    });
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    final invProvider = context.read<InventoryProvider>();
    await Future.wait([
      context.read<BusinessProvider>().loadProfile(),
      invProvider.loadProducts(),
      context.read<BillingProvider>().loadInvoices(),
      context.read<ReportsProvider>().loadAllReports(),
    ]);

    // Load recent movements, wastage, and expenses for comprehensive activity timeline
    try {
      final db = await AppDatabase.instance.database;

      final movements = await invProvider.getAllMovements(limit: 40);
      final wasteMaps = await db.query(
        'wastage_records',
        orderBy: 'created_at DESC',
        limit: 30,
      );
      final expMaps = await db.query(
        'expenses',
        orderBy: 'date DESC, created_at DESC',
        limit: 30,
      );

      if (mounted) {
        setState(() {
          _stockMovements = movements;
          _wastageRecords = wasteMaps.map((m) => WastageRecord.fromMap(m)).toList();
          _allExpenses = expMaps.map((m) => Expense.fromMap(m)).toList();
        });
        await _loadDayFinancials(_selectedDate);
      }
    } catch (_) {}
  }

  Future<void> _loadDayFinancials(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day).toIso8601String();
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
      final db = await AppDatabase.instance.database;

      final expMaps = await db.rawQuery(
        'SELECT SUM(amount) as total FROM expenses WHERE date BETWEEN ? AND ?',
        [start, end],
      );
      final wasteMaps = await db.rawQuery(
        'SELECT SUM(total_loss) as total FROM wastage_records WHERE created_at BETWEEN ? AND ?',
        [start, end],
      );

      if (mounted) {
        setState(() {
          _dayExpenses = (expMaps.first['total'] as num?)?.toDouble() ?? 0.0;
          _dayWastage = (wasteMaps.first['total'] as num?)?.toDouble() ?? 0.0;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>().profile;
    final inventory = context.watch<InventoryProvider>();
    final billing = context.watch<BillingProvider>();
    final reports = context.watch<ReportsProvider>();

    // Calculate selected day's expenses and wastage directly from reports/db in-memory
    double dayExpenses = 0.0;
    if (reports.expensesList.isNotEmpty) {
      dayExpenses = reports.expensesList.where((e) {
        return e.date.year == _selectedDate.year &&
            e.date.month == _selectedDate.month &&
            e.date.day == _selectedDate.day;
      }).fold(0.0, (sum, e) => sum + e.amount);
    } else {
      dayExpenses = _dayExpenses;
    }

    double dayWastage = 0.0;
    if (reports.wastage != null && reports.wastage!.records.isNotEmpty) {
      dayWastage = reports.wastage!.records.where((w) {
        return w.createdAt.year == _selectedDate.year &&
            w.createdAt.month == _selectedDate.month &&
            w.createdAt.day == _selectedDate.day;
      }).fold(0.0, (sum, w) => sum + w.totalLoss);
    } else {
      dayWastage = _dayWastage;
    }

    // Calculate selected day's sales and profit from actual invoices based on actual received payments
    final todayInvoices = billing.allInvoices.where((inv) {
      final d = inv.createdAt;
      return d.year == _selectedDate.year &&
          d.month == _selectedDate.month &&
          d.day == _selectedDate.day &&
          !inv.isCancelled;
    }).toList();

    // Actual sales collected (cash/received on day)
    final todaySales = todayInvoices.fold(0.0, (sum, inv) => sum + inv.paidAmount);

    // Realized gross profit proportional to what the customer actually paid
    final todayGrossProfit = todayInvoices.fold(0.0, (sum, inv) {
      if (inv.grandTotal <= 0) return sum;
      final paidRatio = (inv.paidAmount / inv.grandTotal).clamp(0.0, 1.0);
      return sum + (inv.grossProfit * paidRatio);
    });

    // Net profit for the selected date = Realized Gross Profit - Operating Expenses - Wastage Loss for that day
    final dayNetProfit = todayGrossProfit - dayExpenses - dayWastage;

    final totalStockValue = inventory.summary['totalStockValue'] as double? ?? 0.0;
    final totalProducts = inventory.summary['totalProducts'] as int? ?? 0;
    final lowStockCount = inventory.summary['lowStockCount'] as int? ?? 0;
    final outOfStockCount = inventory.summary['outOfStockCount'] as int? ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadAllData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Brand Header matching Reference Image
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Vyavhar',
                          style: AppTypography.brandTitle,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        ).then((_) => _loadAllData());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Greeting
                Text(
                  'Namaste, ${business.ownerName.split(' ').first}!',
                  style: AppTypography.greeting,
                ),
                const SizedBox(height: 16),

                // Hero Card with Deep Forest Green, Embedded Calendar Picker & Sparkline
                HeroSalesCard(
                  salesAmount: todaySales,
                  selectedDate: _selectedDate,
                  onSelectDate: () => _pickDate(context),
                ),
                const SizedBox(height: 16),

                // Metric Cards Row: [Profit / Loss] [Stock Valuation]
                Builder(
                  builder: (context) {
                    final bool isProfit = dayNetProfit >= 0;
                    final Color profitColor = isProfit ? AppColors.success : AppColors.error;
                    final Color profitBg = isProfit ? AppColors.successLight : AppColors.errorLight;
                    final Color profitBorder = isProfit
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.error.withOpacity(0.2);

                    return Row(
                      children: [
                        StatCard(
                          label: isProfit ? 'Profit' : 'Loss',
                          value: CurrencyFormatter.format(dayNetProfit.abs()),
                          subtitle: isProfit ? 'Profit for day' : 'Loss for day',
                          icon: isProfit ? Icons.trending_up : Icons.trending_down,
                          iconColor: profitColor,
                          valueColor: profitColor,
                          backgroundColor: profitBg,
                          borderColor: profitBorder,
                          onTap: () => widget.onNavigateTab(3), // Reports -> Profit & Loss
                        ),
                        const SizedBox(width: 12),
                        StatCard(
                          label: 'Stock Valuation',
                          value: CurrencyFormatter.format(totalStockValue),
                          subtitle: '$totalProducts items in stock',
                          icon: Icons.inventory_2_outlined,
                          iconColor: AppColors.primary,
                          valueColor: AppColors.primaryDark,
                          backgroundColor: AppColors.primaryContainer.withOpacity(0.4),
                          borderColor: AppColors.primary.withOpacity(0.18),
                          onTap: () => widget.onNavigateTab(1), // Inventory
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Stock Status Section (only shown when there are warnings)
                if (lowStockCount > 0 || outOfStockCount > 0) ...[
                  StockStatusCard(
                    lowStockCount: lowStockCount,
                    outOfStockCount: outOfStockCount,
                    onViewAll: () => widget.onNavigateTab(1), // Go to Inventory tab
                  ),
                  const SizedBox(height: 20),
                ],

                // Pending Due Status Section (only shown when there are pending bills)
                Builder(
                  builder: (context) {
                    final pendingBills = billing.allInvoices
                        .where((inv) => !inv.isCancelled && inv.pendingAmount > 0)
                        .toList();
                    final pendingBillsCount = pendingBills.length;
                    final totalPendingAmount = pendingBills.fold(
                      0.0,
                      (sum, inv) => sum + inv.pendingAmount,
                    );

                    if (pendingBillsCount == 0) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: DueStatusCard(
                        pendingBillsCount: pendingBillsCount,
                        totalPendingAmount: totalPendingAmount,
                        onViewAll: () {
                          context.read<BillingProvider>().selectStatus('Pending');
                          widget.onNavigateTab(2); // Go to Bills tab with Pending filter
                        },
                      ),
                    );
                  },
                ),

                // Recent Unified Activity List (Invoices, Expenses, Wastage, Stock In / Adjustments)
                Builder(
                  builder: (context) {
                    final activities = _compileActivities(billing.allInvoices);
                    return RecentActivityList(
                      activities: activities,
                      onViewAll: () => widget.onNavigateTab(2), // Go to Bills tab
                      onActivityTap: (item) => _handleActivityTap(item),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<BusinessActivityItem> _compileActivities(List<Invoice> invoices) {
    final List<BusinessActivityItem> list = [];

    // 1. Invoices / Sales transactions
    for (final inv in invoices) {
      final isCancelled = inv.isCancelled;
      list.add(BusinessActivityItem(
        id: 'inv_${inv.id}',
        type: ActivityType.sale,
        title: '${inv.customerName} (Bill #${inv.invoiceNumber})',
        subtitle: isCancelled ? 'Invoice Cancelled' : 'Payment: ${inv.paymentMode}',
        timestamp: inv.createdAt,
        amount: isCancelled ? inv.grandTotal : inv.paidAmount,
        amountPrefix: isCancelled ? '' : '+',
        amountColor: isCancelled
            ? AppColors.textMuted
            : (inv.paidAmount > 0 ? AppColors.success : AppColors.textSecondary),
        badgeText: isCancelled ? 'Cancelled' : (inv.pendingAmount > 0 ? 'Due: -${CurrencyFormatter.format(inv.pendingAmount)}' : inv.paymentStatus),
        badgeColor: isCancelled ? AppColors.textMuted : (inv.pendingAmount > 0 ? AppColors.error : AppColors.success),
        originalObject: inv,
      ));
    }

    // 2. Expenses
    for (final exp in _allExpenses) {
      list.add(BusinessActivityItem(
        id: 'exp_${exp.id}',
        type: ActivityType.expense,
        title: '${exp.title} (${exp.category})',
        subtitle: exp.notes != null && exp.notes!.trim().isNotEmpty
            ? exp.notes!
            : 'Expense paid',
        timestamp: exp.createdAt,
        amount: exp.amount,
        amountPrefix: '-',
        amountColor: const Color(0xFFD97706),
        badgeText: 'Expense',
        badgeColor: const Color(0xFFD97706),
        originalObject: exp,
      ));
    }

    // 3. Wastage records
    for (final w in _wastageRecords) {
      list.add(BusinessActivityItem(
        id: 'w_${w.id}',
        type: ActivityType.wastage,
        title: 'Wastage: ${w.productName}',
        subtitle: '${w.quantity.toStringAsFixed(w.quantity % 1 == 0 ? 0 : 1)} ${w.unit} • ${w.reason}',
        timestamp: w.createdAt,
        amount: w.totalLoss,
        amountPrefix: '-',
        amountColor: AppColors.error,
        badgeText: 'Loss',
        badgeColor: AppColors.error,
        originalObject: w,
      ));
    }

    // 4. Stock In / Stock Additions / Initial opening stock (excluding sales & wastage already tracked above)
    for (final m in _stockMovements) {
      final typeUpper = m.movementType.toUpperCase();
      if (typeUpper == 'SALE' || typeUpper == 'WASTAGE') {
        continue;
      }

      final isPurchase = typeUpper == 'PURCHASE';
      final isInitial = typeUpper == 'INITIAL';

      final String title;
      final ActivityType actType;
      if (isPurchase) {
        title = 'Stock Added: ${m.productName.isNotEmpty ? m.productName : "Inventory Batch"}';
        actType = ActivityType.purchase;
      } else if (isInitial) {
        title = 'New Product Added: ${m.productName.isNotEmpty ? m.productName : "Product"}';
        actType = ActivityType.initialStock;
      } else {
        title = 'Stock Adjusted: ${m.productName.isNotEmpty ? m.productName : "Inventory"}';
        actType = ActivityType.purchase;
      }

      list.add(BusinessActivityItem(
        id: 'sm_${m.id}',
        type: actType,
        title: title,
        subtitle: m.reason ?? (isPurchase ? 'Inventory purchase' : (isInitial ? 'Opening stock' : 'Stock adjustment')),
        timestamp: m.createdAt,
        amount: m.totalValue > 0 ? m.totalValue : null,
        amountPrefix: isPurchase ? '-' : '',
        amountColor: isPurchase ? AppColors.textPrimary : AppColors.success,
        badgeText: '+${m.quantity.toStringAsFixed(m.quantity % 1 == 0 ? 0 : 1)} qty',
        badgeColor: AppColors.success,
        originalObject: m,
      ));
    }

    // Sort descending by timestamp
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  void _handleActivityTap(BusinessActivityItem item) {
    if (item.originalObject is Invoice) {
      _openInvoiceDetail(item.originalObject as Invoice);
    } else if (item.originalObject is StockMovement) {
      final sm = item.originalObject as StockMovement;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(productId: sm.productId),
        ),
      ).then((_) => _loadAllData());
    } else if (item.originalObject is WastageRecord) {
      final w = item.originalObject as WastageRecord;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(productId: w.productId),
        ),
      ).then((_) => _loadAllData());
    } else if (item.originalObject is Expense) {
      widget.onNavigateTab(3); // Go to Reports/Expenses
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDayFinancials(picked);
    }
  }

  void _openInvoiceDetail(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailScreen(invoiceId: invoice.id),
      ),
    ).then((_) => _loadAllData());
  }
}
