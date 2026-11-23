import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/invoice.dart';
import '../../providers/billing_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/reports_provider.dart';
import '../../services/pdf_service.dart';
import 'invoice_pdf_preview_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  Invoice? _invoice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    final billing = context.read<BillingProvider>();
    final inv = billing.invoices.firstWhere(
      (i) => i.id == widget.invoiceId,
      orElse: () => Invoice(
        id: '',
        invoiceNumber: '',
        customerName: '',
        customerPhone: '',
        subtotal: 0,
        grandTotal: 0,
        paidAmount: 0,
        createdAt: DateTime.now(),
      ),
    );

    if (mounted) {
      setState(() {
        _invoice = inv.id.isNotEmpty ? inv : null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: const Center(child: Text('Invoice not found.')),
      );
    }

    final invoice = _invoice!;
    final business = context.watch<BusinessProvider>().profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: AppTypography.brandTitle.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primary),
            onPressed: () => PdfService.shareInvoicePdf(invoice, business),
          ),
          IconButton(
            icon: const Icon(Icons.print, color: AppColors.primary),
            onPressed: () => PdfService.printInvoice(invoice, business),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BOX 1: BILL SUMMARY (Invoice #, Date, Status, Customer, Items Table, Subtotal, Grand Total)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AppDimens.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice Number and Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (invoice.isCancelled)
                          const StatusBadge(
                            label: 'CANCELLED',
                            backgroundColor: AppColors.errorLight,
                            textColor: AppColors.error,
                          )
                        else if (invoice.paymentStatus == 'Paid')
                          StatusBadge.paid()
                        else if (invoice.paymentStatus == 'Partial')
                          StatusBadge.partial()
                        else
                          StatusBadge.pending(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Billed on ${DateFormatter.formatDateTime(invoice.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 12),

                    // Customer Row
                    Row(
                      children: [
                        _buildCustomerAvatar(invoice.customerName, size: 38),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice.customerName.isEmpty
                                    ? 'Guest Customer'
                                    : invoice.customerName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                invoice.customerPhone.isNotEmpty
                                    ? invoice.customerPhone
                                    : 'No phone number',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (invoice.customerAddress != null &&
                                  invoice.customerAddress!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  invoice.customerAddress!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 10),

                    // Table Header
                    Row(
                      children: const [
                        Expanded(
                          flex: 5,
                          child: Text(
                            'ITEM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'QTY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'TOTAL',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Items List
                    ...invoice.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                item.productName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)} ${item.unit}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                CurrencyFormatter.format(item.totalAmount),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 12),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 10),

                    // Bill Totals
                    _buildRow(
                      'Subtotal',
                      CurrencyFormatter.format(invoice.subtotal),
                    ),
                    if (invoice.discount > 0)
                      _buildRow(
                        'Discount',
                        '- ${CurrencyFormatter.format(invoice.discount)}',
                        isGreen: true,
                      ),
                    if (invoice.gstRate > 0)
                      _buildRow(
                        'GST (${invoice.gstRate.toStringAsFixed(0)}%)',
                        CurrencyFormatter.format(invoice.gstAmount),
                      ),
                    if (invoice.additionalCharges > 0)
                      _buildRow(
                        'Additional Charges',
                        CurrencyFormatter.format(invoice.additionalCharges),
                      ),
                    const SizedBox(height: 4),
                    const Divider(color: AppColors.border, height: 8),
                    _buildRow(
                      'Grand Total',
                      CurrencyFormatter.format(invoice.grandTotal),
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // BOX 2: PAYMENT SETTLEMENT (Payment Mode, Paid Amount, Balance Pending, Notes)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AppDimens.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Settlement',
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(height: 14),

                    // Payment Mode with Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Mode',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            _getPaymentModeIcon(invoice.paymentMode),
                            const SizedBox(width: 6),
                            Text(
                              invoice.paymentMode,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Note',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              invoice.notes!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 8),

                    _buildRow(
                      'Paid Amount',
                      CurrencyFormatter.format(invoice.paidAmount),
                    ),
                    if (invoice.pendingAmount > 0)
                      _buildRow(
                        'Balance Pending (Due)',
                        CurrencyFormatter.format(invoice.pendingAmount),
                        isRed: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Delivery Photographs Section (Page 2 Photos) - only show if photos exist
              if (invoice.photoPaths.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: AppDimens.cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Delivery Photographs',
                            style: AppTypography.cardTitle,
                          ),
                          Text(
                            'Page 2 of PDF (${invoice.photoPaths.length})',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: invoice.photoPaths.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final path = invoice.photoPaths[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppDimens.r12,
                              ),
                              child: Container(
                                width: 140,
                                height: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Image.file(
                                  File(path),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: AppColors.surfaceVariant,
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 4),

              // Action Buttons
              CustomButton(
                text: 'View Invoice',
                icon: Icons.picture_as_pdf,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InvoicePdfPreviewScreen(
                        invoice: invoice,
                        business: business,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              if (!invoice.isCancelled && invoice.pendingAmount > 0) ...[
                CustomButton(
                  text: 'Update Payment Collection',
                  icon: Icons.payments_outlined,
                  isSecondary: true,
                  onPressed: () => _showRecordPaymentDialog(invoice),
                ),
                const SizedBox(height: 10),
              ],

              if (!invoice.isCancelled)
                CustomButton(
                  text: 'Cancel Bill & Restore Stock',
                  isSecondary: true,
                  backgroundColor: AppColors.errorLight,
                  textColor: AppColors.error,
                  onPressed: () => _confirmCancelInvoice(invoice),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    bool isGreen = false,
    bool isRed = false,
  }) {
    Color col = AppColors.textPrimary;
    if (isGreen) col = AppColors.success;
    if (isRed) col = AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: col,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 17 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold ? AppColors.primary : col,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerAvatar(String name, {double size = 36}) {
    final initials = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : 'C';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _getPaymentModeIcon(String mode) {
    IconData icon;
    Color color = AppColors.primary;

    switch (mode) {
      case 'UPI':
        icon = Icons.qr_code_scanner_outlined;
        break;
      case 'Bank Transfer':
        icon = Icons.account_balance_outlined;
        break;
      case 'Cash':
      default:
        icon = Icons.payments_outlined;
        break;
    }

    return Icon(icon, size: 18, color: color);
  }

  void _showRecordPaymentDialog(Invoice invoice) {
    final controller = TextEditingController(
      text: invoice.pendingAmount.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Due: ${CurrencyFormatter.format(invoice.pendingAmount)}',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount Received (₹)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final amt = double.tryParse(controller.text.trim()) ?? 0.0;
              if (amt > 0) {
                final billing = context.read<BillingProvider>();
                final reports = context.read<ReportsProvider>();
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                final success = await billing.recordPayment(invoice.id, amt);
                if (mounted && success) {
                  reports.loadAllReports();
                  await _loadInvoice();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Payment of ${CurrencyFormatter.format(amt)} recorded!',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Save Payment',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancelInvoice(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Bill?'),
        content: const Text(
          'Cancelling this invoice will VOID the bill and AUTOMATICALLY RESTORE all product quantities back into inventory stock. Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final billing = context.read<BillingProvider>();
              final inventory = context.read<InventoryProvider>();
              final reports = context.read<ReportsProvider>();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final success = await billing.cancelInvoice(invoice.id);
              if (mounted && success) {
                await inventory.loadProducts();
                reports.loadAllReports();
                await _loadInvoice();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Invoice cancelled and stock restored to inventory!',
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Cancel & Restore Stock',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
