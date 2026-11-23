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

class RecordPurchaseDialog extends StatefulWidget {
  final Product? preselectedProduct;

  const RecordPurchaseDialog({super.key, this.preselectedProduct});

  @override
  State<RecordPurchaseDialog> createState() => _RecordPurchaseDialogState();
}

class _RecordPurchaseDialogState extends State<RecordPurchaseDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedProductId;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.preselectedProduct?.id;
    if (widget.preselectedProduct != null) {
      _priceController.text = widget.preselectedProduct!.purchasePrice
          .toStringAsFixed(0);
      _supplierController.text = widget.preselectedProduct!.supplierName ?? '';
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final products = List<Product>.from(inventory.products);

    if (widget.preselectedProduct != null &&
        !products.any((p) => p.id == widget.preselectedProduct!.id)) {
      products.insert(0, widget.preselectedProduct!);
    }

    if ((_selectedProductId == null ||
            !products.any((p) => p.id == _selectedProductId)) &&
        products.isNotEmpty) {
      _selectedProductId = products.first.id;
      if (_priceController.text.isEmpty) {
        _priceController.text = products.first.purchasePrice.toStringAsFixed(0);
        _supplierController.text = products.first.supplierName ?? '';
      }
    }

    final selectedProduct =
        products.where((p) => p.id == _selectedProductId).firstOrNull ??
        (products.isNotEmpty ? products.first : widget.preselectedProduct);

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
                        'Add Stock (Purchase)',
                        style: AppTypography.cardTitle,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Select Product Dropdown
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
                            setState(() {
                              _selectedProductId = id;
                              final p = products
                                  .where((item) => item.id == id)
                                  .firstOrNull;
                              if (p != null) {
                                _priceController.text = p.purchasePrice
                                    .toStringAsFixed(0);
                                _supplierController.text = p.supplierName ?? '';
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quantity & Purchase Rate
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _quantityController,
                          label:
                              'Quantity (${selectedProduct?.unit ?? 'qty'}) *',
                          hintText: '0',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (val) {
                            if (val == null ||
                                double.tryParse(val) == null ||
                                double.parse(val) <= 0) {
                              return 'Enter valid qty';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _priceController,
                          label: 'Purchase Rate (₹) *',
                          hintText: '0',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (val) {
                            if (val == null ||
                                double.tryParse(val) == null ||
                                double.parse(val) <= 0) {
                              return 'Enter valid rate';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Supplier / Vendor
                  CustomTextField(
                    controller: _supplierController,
                    label: 'Supplier (Optional)',
                    hintText: 'e.g. Royal Sweets Wholesaler',
                  ),
                  const SizedBox(height: 16),

                  // Cost Averaging Formula Info Box
                  if (selectedProduct != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(AppDimens.r12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Current Stock: ${selectedProduct.currentStock.toStringAsFixed(selectedProduct.currentStock % 1 == 0 ? 0 : 1)} ${selectedProduct.unit} @ ${CurrencyFormatter.format(selectedProduct.purchasePrice)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Vyavhar will automatically re-calculate the accurate average cost price.',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Action Buttons
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
                          text: 'Add Stock',
                          isLoading: _isLoading,
                          onPressed: _submitPurchase,
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

  Future<void> _submitPurchase() async {
    if (!_formKey.currentState!.validate() || _selectedProductId == null)
      return;

    setState(() => _isLoading = true);

    final qty = double.parse(_quantityController.text.trim());
    final price = double.parse(_priceController.text.trim());
    final supplier = _supplierController.text.trim().isNotEmpty
        ? _supplierController.text.trim()
        : null;

    final inventory = context.read<InventoryProvider>();
    final targetProduct =
        inventory.products
            .where((p) => p.id == _selectedProductId)
            .firstOrNull ??
        widget.preselectedProduct;

    final success = await inventory.recordPurchase(
      productId: _selectedProductId!,
      quantity: qty,
      purchasePrice: price,
      supplierName: supplier,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added $qty ${targetProduct?.unit ?? ''} to ${targetProduct?.name ?? 'product'} successfully!',
            ),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              inventory.errorMessage ?? 'Failed to record purchase',
            ),
          ),
        );
      }
    }
  }
}
