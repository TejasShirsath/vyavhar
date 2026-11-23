import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/utils/date_formatter.dart';
import '../models/business_profile.dart';
import '../models/invoice.dart';

class PdfService {
  static const PdfColor primaryGreen = PdfColor.fromInt(0xFF176B45);
  static const PdfColor darkGreen = PdfColor.fromInt(0xFF0F4A2F);
  static const PdfColor lightGreen = PdfColor.fromInt(0xFFEBF4EE);
  static const PdfColor charcoal = PdfColor.fromInt(0xFF202820);
  static const PdfColor mutedGrey = PdfColor.fromInt(0xFF777F78);
  static const PdfColor lightGrey = PdfColor.fromInt(0xFFF8F9F5);
  static const PdfColor borderGrey = PdfColor.fromInt(0xFFE4E9E2);

  /// Generates the complete 2-page invoice document
  static Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required BusinessProfile business,
  }) async {
    // Load Devanagari and regional Unicode font fallbacks for multilingual text (Hindi, Marathi, etc.)
    pw.Font? regularFont;
    pw.Font? boldFont;
    try {
      regularFont = await PdfGoogleFonts.notoSansDevanagariRegular();
      boldFont = await PdfGoogleFonts.notoSansDevanagariBold();
    } catch (_) {
      try {
        regularFont = await PdfGoogleFonts.anekDevanagariRegular();
        boldFont = await PdfGoogleFonts.anekDevanagariBold();
      } catch (_) {}
    }

    final pdfTheme = regularFont != null && boldFont != null
        ? pw.ThemeData.withFont(base: regularFont, bold: boldFont)
        : pw.ThemeData.base();

    // Check if business has custom logo
    pw.MemoryImage? businessLogoImage;
    if (business.logoPath != null && business.logoPath!.isNotEmpty) {
      try {
        final logoFile = File(business.logoPath!);
        if (await logoFile.exists()) {
          final logoBytes = await logoFile.readAsBytes();
          businessLogoImage = pw.MemoryImage(logoBytes);
        }
      } catch (_) {}
    }

    final pdf = pw.Document(theme: pdfTheme);

    // ==========================================
    // PAGE 1: TAX INVOICE DETAILS
    // ==========================================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildInvoiceHeader(invoice, business, businessLogoImage),
              pw.SizedBox(height: 20),

              // Customer & Invoice Details
              _buildDetailsSection(invoice, business),
              pw.SizedBox(height: 20),

              // Items Table
              _buildItemsTable(invoice),
              pw.SizedBox(height: 16),

              // Calculations & Payment Summary
              _buildTotalsSection(invoice),
              pw.Spacer(),

              // Footer / Terms
              _buildPageFooter(
                business,
                1,
                invoice.photoPaths.isNotEmpty ? 2 : 1,
              ),
            ],
          );
        },
      ),
    );

    // ==========================================
    // PAGE 2: DELIVERY PHOTOGRAPHS (MANDATORY REQUIREMENT)
    // ==========================================
    final List<Uint8List> validPhotoBytes = [];
    for (final path in invoice.photoPaths) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          validPhotoBytes.add(file.readAsBytesSync());
        }
      } catch (_) {}
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header banner for Delivery verification
              _buildDeliveryVerificationHeader(invoice, business),
              pw.SizedBox(height: 16),

              // Photos Grid or Verification Container
              if (validPhotoBytes.isNotEmpty)
                _buildPhotosGrid(validPhotoBytes, invoice)
              else
                _buildEmptyPhotoVerificationBox(invoice),

              pw.Spacer(),

              // Page 2 Footer
              _buildPageFooter(business, 2, 2),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // --- Page 1 Helpers ---

  static pw.Widget _buildInvoiceHeader(
    Invoice invoice,
    BusinessProfile business, [
    pw.MemoryImage? logoImage,
  ]) {
    final hasLogo = logoImage != null;
    final hasTagline = business.tagline.trim().isNotEmpty;
    final hasAddress = business.address.trim().isNotEmpty;

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: primaryGreen, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  if (hasLogo)
                    pw.Container(
                      width: 32,
                      height: 32,
                      margin: const pw.EdgeInsets.only(right: 8),
                      child: pw.ClipRRect(
                        horizontalRadius: 6,
                        verticalRadius: 6,
                        child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                      ),
                    )
                  else
                    pw.Container(
                      width: 28,
                      height: 28,
                      margin: const pw.EdgeInsets.only(right: 8),
                      decoration: pw.BoxDecoration(
                        color: primaryGreen,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        business.businessName.isNotEmpty
                            ? business.businessName[0].toUpperCase()
                            : 'V',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  pw.Text(
                    business.businessName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                ],
              ),
              if (hasTagline) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  business.tagline,
                  style: const pw.TextStyle(fontSize: 9, color: mutedGrey),
                ),
              ],
              if (hasAddress) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  business.address,
                  style: const pw.TextStyle(fontSize: 9, color: charcoal),
                ),
              ],
              pw.Text(
                'Phone: ${business.phone}',
                style: const pw.TextStyle(fontSize: 9, color: charcoal),
              ),
              if (business.gstin != null && business.gstin!.isNotEmpty)
                pw.Text(
                  'GSTIN: ${business.gstin}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: charcoal,
                  ),
                ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: lightGreen,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'TAX INVOICE',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Invoice No: ${invoice.invoiceNumber}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: charcoal,
                ),
              ),
              pw.Text(
                'Date: ${DateFormatter.format(invoice.createdAt)}',
                style: const pw.TextStyle(fontSize: 10, color: mutedGrey),
              ),
              pw.Text(
                'Time: ${DateFormatter.formatTime(invoice.createdAt)}',
                style: const pw.TextStyle(fontSize: 9, color: mutedGrey),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: invoice.paymentStatus == 'Paid'
                      ? PdfColors.green100
                      : (invoice.paymentStatus == 'Partial'
                            ? PdfColors.amber100
                            : PdfColors.red100),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'STATUS: ${invoice.paymentStatus.toUpperCase()}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: invoice.paymentStatus == 'Paid'
                        ? PdfColors.green800
                        : (invoice.paymentStatus == 'Partial'
                              ? PdfColors.amber800
                              : PdfColors.red800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailsSection(
    Invoice invoice,
    BusinessProfile business,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: lightGrey,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: borderGrey),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BILLED TO:',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: mutedGrey,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                invoice.customerName,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: charcoal,
                ),
              ),
              pw.Text(
                'Contact: ${invoice.customerPhone}',
                style: const pw.TextStyle(fontSize: 10, color: charcoal),
              ),
              if (invoice.customerAddress != null &&
                  invoice.customerAddress!.isNotEmpty)
                pw.Text(
                  'Address: ${invoice.customerAddress}',
                  style: const pw.TextStyle(fontSize: 9, color: mutedGrey),
                ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'PAYMENT DETAILS:',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: mutedGrey,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Mode: ${invoice.paymentMode}',
                style: const pw.TextStyle(fontSize: 10, color: charcoal),
              ),
              pw.Text(
                'Paid: Rs. ${invoice.paidAmount.truncate()}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              if (invoice.pendingAmount > 0)
                pw.Text(
                  'Balance Due: Rs. ${invoice.pendingAmount.truncate()}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(Invoice invoice) {
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(color: borderGrey, width: 0.5),
        bottom: const pw.BorderSide(color: borderGrey, width: 1),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(3.8),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.4),
        4: const pw.FlexColumnWidth(1.6),
      },
      children: [
        // Table Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: lightGreen),
          children: [
            _tableHeaderCell('#'),
            _tableHeaderCell('Item Description'),
            _tableHeaderCell('Qty', align: pw.TextAlign.center),
            _tableHeaderCell('Rate (Rs.)', align: pw.TextAlign.right),
            _tableHeaderCell('Amount (Rs.)', align: pw.TextAlign.right),
          ],
        ),
        // Table Rows
        ...invoice.items.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _tableCell('$idx', align: pw.TextAlign.left),
              _tableCell(item.productName, isBold: true),
              _tableCell(
                '${item.quantity} ${item.unit}',
                align: pw.TextAlign.center,
              ),
              _tableCell(
                '${item.unitPrice.truncate()}',
                align: pw.TextAlign.right,
              ),
              _tableCell(
                '${item.totalAmount.truncate()}',
                align: pw.TextAlign.right,
                isBold: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: darkGreen,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
    PdfColor color = charcoal,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _buildTotalsSection(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                pw.Text(
                  'Notes:',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: charcoal,
                  ),
                ),
                pw.Text(
                  invoice.notes!,
                  style: const pw.TextStyle(fontSize: 8, color: mutedGrey),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 24),
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            children: [
              _buildSummaryRow(
                'Subtotal',
                'Rs. ${invoice.subtotal.truncate()}',
              ),
              if (invoice.discount > 0)
                _buildSummaryRow(
                  'Discount',
                  '- Rs. ${invoice.discount.truncate()}',
                  isDiscount: true,
                ),
              if (invoice.gstRate > 0)
                _buildSummaryRow(
                  'GST (${invoice.gstRate.toStringAsFixed(0)}%)',
                  'Rs. ${invoice.gstAmount.truncate()}',
                ),
              if (invoice.additionalCharges > 0)
                _buildSummaryRow(
                  'Additional Charges',
                  'Rs. ${invoice.additionalCharges.truncate()}',
                ),
              pw.Divider(color: borderGrey, thickness: 1),
              _buildSummaryRow(
                'Grand Total',
                'Rs. ${invoice.grandTotal.truncate()}',
                isGrandTotal: true,
              ),
              _buildSummaryRow(
                'Amount Paid',
                'Rs. ${invoice.paidAmount.truncate()}',
              ),
              if (invoice.pendingAmount > 0)
                _buildSummaryRow(
                  'Balance Due',
                  'Rs. ${invoice.pendingAmount.truncate()}',
                  isDue: true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool isGrandTotal = false,
    bool isDiscount = false,
    bool isDue = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isGrandTotal ? 11 : 9,
              fontWeight: isGrandTotal
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              color: isDue ? PdfColors.red700 : charcoal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isGrandTotal ? 13 : 9,
              fontWeight: isGrandTotal
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              color: isGrandTotal
                  ? primaryGreen
                  : (isDiscount
                        ? PdfColors.green700
                        : (isDue ? PdfColors.red700 : charcoal)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Page 2 Helpers: Delivery Photographs ---

  static pw.Widget _buildDeliveryVerificationHeader(
    Invoice invoice,
    BusinessProfile business,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: lightGreen,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: primaryGreen, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PAGE 2: PROOF OF DELIVERY & GOODS DISPATCH PHOTOGRAPHS',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Photographic evidence of products prepared and delivered to customer.',
                style: const pw.TextStyle(fontSize: 8, color: mutedGrey),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Invoice: ${invoice.invoiceNumber}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: charcoal,
                ),
              ),
              pw.Text(
                'Customer: ${invoice.customerName}',
                style: const pw.TextStyle(fontSize: 9, color: charcoal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPhotosGrid(
    List<Uint8List> photoBytesList,
    Invoice invoice,
  ) {
    final List<pw.Widget> photoCards = [];

    for (int i = 0; i < photoBytesList.length; i++) {
      final bytes = photoBytesList[i];
      final image = pw.MemoryImage(bytes);

      photoCards.add(
        pw.Container(
          width: 250,
          height: 190,
          margin: const pw.EdgeInsets.all(6),
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: borderGrey, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.ClipRRect(
                  horizontalRadius: 4,
                  verticalRadius: 4,
                  child: pw.Center(
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Photo #${i + 1} - Goods Dispatch',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  pw.Text(
                    DateFormatter.format(invoice.createdAt),
                    style: const pw.TextStyle(fontSize: 7, color: mutedGrey),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return pw.Wrap(spacing: 8, runSpacing: 8, children: photoCards);
  }

  static pw.Widget _buildEmptyPhotoVerificationBox(Invoice invoice) {
    return pw.Container(
      width: double.infinity,
      height: 220,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: lightGrey,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: borderGrey, style: pw.BorderStyle.dashed),
      ),
      child: pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'No Physical Camera Photos Attached for this Order',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: charcoal,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Goods were handed over directly to ${invoice.customerName} on ${DateFormatter.format(invoice.createdAt)}.',
              style: const pw.TextStyle(fontSize: 9, color: mutedGrey),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildPageFooter(
    BusinessProfile business,
    int currentPage,
    int totalPages,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Generated by Vyavhar - Smart Business. Simple Hisaab.',
          style: const pw.TextStyle(fontSize: 7, color: mutedGrey),
        ),
        pw.Text(
          'Page $currentPage of $totalPages',
          style: const pw.TextStyle(fontSize: 7, color: mutedGrey),
        ),
      ],
    );
  }

  /// Generate a clean file name for invoice: "BusinessName_dd-MM-yyyy_INV-1001.pdf"
  static String getInvoicePdfFileName(Invoice invoice, BusinessProfile business) {
    final businessName = business.businessName.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final dateStr = DateFormat('dd-MM-yyyy').format(invoice.createdAt);
    final invNum = invoice.invoiceNumber.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return '${businessName}_${dateStr}_$invNum.pdf';
  }

  /// Print invoice directly
  static Future<void> printInvoice(
    Invoice invoice,
    BusinessProfile business,
  ) async {
    final pdfBytes = await generateInvoicePdf(
      invoice: invoice,
      business: business,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: getInvoicePdfFileName(invoice, business),
    );
  }

  /// Share PDF via WhatsApp or other apps
  static Future<void> shareInvoicePdf(
    Invoice invoice,
    BusinessProfile business,
  ) async {
    final pdfBytes = await generateInvoicePdf(
      invoice: invoice,
      business: business,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: getInvoicePdfFileName(invoice, business),
    );
  }
}
