import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/business_profile.dart';
import '../../models/invoice.dart';
import '../../services/pdf_service.dart';

class InvoicePdfPreviewScreen extends StatelessWidget {
  final Invoice invoice;
  final BusinessProfile business;

  const InvoicePdfPreviewScreen({
    super.key,
    required this.invoice,
    required this.business,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice ${invoice.invoiceNumber}',
              style: AppTypography.brandTitle.copyWith(fontSize: 16),
            ),
            const Text(
              '2-Page Verified Document (Page 2: Delivery Photos)',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: PdfPreview(
        maxPageWidth: 700,
        build: (PdfPageFormat format) => PdfService.generateInvoicePdf(
          invoice: invoice,
          business: business,
        ),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: PdfService.getInvoicePdfFileName(invoice, business),
      ),
    );
  }
}
