import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../services/reports_service.dart';

class ReportsProvider with ChangeNotifier {
  final ReportsService _service = ReportsService();

  DateRangeFilter _currentFilter = DateRangeFilter.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;

  bool _isLoading = false;
  String? _errorMessage;

  StockValuationSummary? _stockValuation;
  ProfitLossSummary? _profitLoss;
  WastageSummary? _wastage;
  SalesReportSummary? _salesReport;
  Map<String, dynamic>? _expensesReport;

  DateRangeFilter get currentFilter => _currentFilter;
  DateRange get dateRange => DateRange.fromFilter(
        _currentFilter,
        customStart: _customStart,
        customEnd: _customEnd,
      );

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StockValuationSummary? get stockValuation => _stockValuation;
  ProfitLossSummary? get profitLoss => _profitLoss;
  WastageSummary? get wastage => _wastage;
  SalesReportSummary? get salesReport => _salesReport;
  Map<String, dynamic>? get expensesReport => _expensesReport;

  List<Expense> get expensesList =>
      (_expensesReport?['expenses'] as List<Expense>?) ?? [];
  double get totalExpenses =>
      (_expensesReport?['total'] as double?) ?? 0.0;
  Map<String, double> get expensesByCategory =>
      (_expensesReport?['byCategory'] as Map<String, double>?) ?? {};

  void setFilter(DateRangeFilter filter) {
    _currentFilter = filter;
    loadAllReports();
  }

  void setCustomRange(DateTime start, DateTime end) {
    _currentFilter = DateRangeFilter.custom;
    _customStart = start;
    _customEnd = end;
    loadAllReports();
  }

  Future<void> loadAllReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final range = dateRange;

    try {
      final results = await Future.wait([
        _service.getStockValuationReport(),
        _service.getProfitLossReport(range),
        _service.getWastageReport(range),
        _service.getSalesReport(range),
        _service.getExpensesReport(range),
      ]);

      _stockValuation = results[0] as StockValuationSummary;
      _profitLoss = results[1] as ProfitLossSummary;
      _wastage = results[2] as WastageSummary;
      _salesReport = results[3] as SalesReportSummary;
      _expensesReport = results[4] as Map<String, dynamic>;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense({
    required String title,
    required double amount,
    required String category,
    DateTime? date,
    String? notes,
  }) async {
    try {
      await _service.addExpense(
        title: title,
        amount: amount,
        category: category,
        date: date,
        notes: notes,
      );
      await loadAllReports();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
