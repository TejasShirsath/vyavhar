import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/product.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/reports_provider.dart';

class RecordWastageDialog extends StatefulWidget {
  final Product? preselectedProduct;

  const RecordWastageDialog({super.key, this.preselectedProduct});

  @override
  State<RecordWastageDialog> createState() => _RecordWastageDialogState();
}

class _RecordWastageDialogState extends State<RecordWastageDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedProductId;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedReason = 'Damaged';
  bool _isLoading = false;

  final List<String> _reasons = [
    'Damaged',
    'Expired',
    'Spoiled',
    'Broken',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.preselectedProduct?.id;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final products = inventory.products
        .where((p) => p.currentStock > 0)
        .toList();

    // If preselectedProduct is specified, ensure it is in the list
    if (widget.preselectedProduct != null &&
        !products.any((p) => p.id == widget.preselectedProduct!.id)) {
      products.insert(0, widget.preselectedProduct!);
    }

    if ((_selectedProductId == null ||
            !products.any((p) => p.id == _selectedProductId)) &&
        products.isNotEmpty) {
      _selectedProductId = products.first.id;
    }

    final selectedProduct =
        products.where((p) => p.id == _selectedProductId).firstOrNull ??
        (products.isNotEmpty ? products.first : widget.preselectedProduct);

    final double qty = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final double loss = (selectedProduct != null)
        ? qty * selectedProduct.purchasePrice
        : 0.0;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.r20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Record Wastage / Damage',
                        style: AppTypography.cardTitle,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Select Product
                  const Text(
                    'Select Product *',
                    style: AppTypography.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppDimens.r12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: products.any((p) => p.id == _selectedProductId)
                            ? _selectedProductId
                            : null,
                        items: products.map((p) {
                          return DropdownMenuItem<String>(
                            value: p.id,
                            child: Text(
                              '${p.name} (Stock: ${p.currentStock.toStringAsFixed(p.currentStock % 1 == 0 ? 0 : 1)} ${p.unit})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) {
                            setState(() => _selectedProductId = id);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quantity & Reason
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _quantityController,
                          label:
                              'Wasted Qty (${selectedProduct?.unit ?? 'qty'}) *',
                          hintText: '0',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (val) {
                            if (val == null ||
                                double.tryParse(val) == null ||
                                double.parse(val) <= 0) {
                              return 'Enter valid qty';
                            }
                            if (selectedProduct != null &&
                                double.parse(val) >
                                    selectedProduct.currentStock) {
                              return 'Exceeds stock';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reason *',
                              style: AppTypography.labelMedium,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(
                                  AppDimens.r12,
                                ),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedReason,
                                  items: _reasons.map((r) {
                                    return DropdownMenuItem(
                                      value: r,
                                      child: Text(r),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null)
                                      setState(() => _selectedReason = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Notes / Remarks
                  CustomTextField(
                    controller: _notesController,
                    label: 'Note (Optional)',
                    hintText: 'e.g. Broken in packaging transit',
                  ),
                  const SizedBox(height: 16),

                  // Loss calculation banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(AppDimens.r12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Estimated Loss (at purchase cost):',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.format(loss),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Stock will be immediately reduced from inventory.',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          isSecondary: true,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Deduct Stock',
                          backgroundColor: AppColors.error,
                          isLoading: _isLoading,
                          onPressed: _submitWastage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitWastage() async {
    if (!_formKey.currentState!.validate() || _selectedProductId == null)
      return;

    setState(() => _isLoading = true);

    final qty = double.parse(_quantityController.text.trim());
    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    final inventory = context.read<InventoryProvider>();
    final targetProduct =
        inventory.products
            .where((p) => p.id == _selectedProductId)
            .firstOrNull ??
        widget.preselectedProduct;

    final success = await inventory.recordWastage(
      productId: _selectedProductId!,
      quantity: qty,
      reason: _selectedReason,
      notes: notes,
    );

    if (mounted) {
      if (success) {
        context.read<ReportsProvider>().loadAllReports();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recorded wastage of $qty ${targetProduct?.unit ?? ''} for ${targetProduct?.name ?? 'product'}.',
            ),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(inventory.errorMessage ?? 'Failed to record wastage'),
          ),
        );
      }
    }
  }
}
