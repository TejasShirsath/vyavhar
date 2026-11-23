import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/invoice.dart';
import '../../providers/billing_provider.dart';
import 'create_bill_screen.dart';
import 'invoice_detail_screen.dart';

class BillsListScreen extends StatefulWidget {
  const BillsListScreen({super.key});

  @override
  State<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends State<BillsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _statusFilters = ['All', 'Pending', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillingProvider>().loadInvoices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final invoices = billing.invoices;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bills & Invoices', style: AppTypography.brandTitle),
                  Text(
                    '${invoices.length} bills',
                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: CustomTextField(
                controller: _searchController,
                isSearch: true,
                hintText: 'Search by Invoice # or Customer...',
                onChanged: (val) => billing.setSearchQuery(val),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          billing.setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),

            // Status Filter Chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _statusFilters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final st = _statusFilters[index];
                  final isSelected = st == billing.selectedStatus;
                  return ChoiceChip(
                    label: Text(st),
                    selected: isSelected,
                    onSelected: (_) => billing.selectStatus(st),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
            ),
            const SizedBox(height: 8),

            // Invoices List
            Expanded(
              child: billing.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : invoices.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.receipt_long_outlined,
                          title: 'No Bills Found',
                          message: 'Create a customer bill with attached delivery photos.',
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () => billing.loadInvoices(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                            itemCount: invoices.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final inv = invoices[index];
                              return _buildInvoiceCard(context, inv);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),

      // Pinned Bottom Button: "Create New Bill"
      bottomSheet: Container(
        color: AppColors.background,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: CustomButton(
          text: 'Create New Bill',
          icon: Icons.add,
          onPressed: () => _openCreateBill(context),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice inv) {
    return Container(
      decoration: AppDimens.cardDecoration(),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceDetailScreen(invoiceId: inv.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppDimens.r16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        inv.invoiceNumber,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      if (inv.photoPaths.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.camera_alt, size: 10, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text(
                                '${inv.photoPaths.length}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (inv.isCancelled)
                    const StatusBadge(
                      label: 'CANCELLED',
                      backgroundColor: AppColors.errorLight,
                      textColor: AppColors.error,
                    )
                  else if (inv.paymentStatus == 'Pending' || inv.paymentStatus == 'Partial')
                    StatusBadge.pending(),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.customerName,
                          style: AppTypography.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${inv.items.length} items • ${DateFormatter.format(inv.createdAt)} at ${DateFormatter.formatTime(inv.createdAt)}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        inv.isCancelled
                            ? CurrencyFormatter.format(inv.grandTotal)
                            : '+${CurrencyFormatter.format(inv.paidAmount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: inv.isCancelled
                              ? AppColors.textMuted
                              : (inv.paidAmount > 0 ? AppColors.success : AppColors.textSecondary),
                        ),
                      ),
                      if (inv.pendingAmount > 0 && !inv.isCancelled)
                        Text(
                          'Due: -${CurrencyFormatter.format(inv.pendingAmount)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCreateBill(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateBillScreen(),
      ),
    );
  }
}
