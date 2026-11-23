import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../providers/billing_provider.dart';

class EditQuantityDialog extends StatefulWidget {
  final int itemIndex;
  final BillingItemDraft item;

  const EditQuantityDialog({
    super.key,
    required this.itemIndex,
    required this.item,
  });

  @override
  State<EditQuantityDialog> createState() => _EditQuantityDialogState();
}

class _EditQuantityDialogState extends State<EditQuantityDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _qtyController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.item.quantity.toStringAsFixed(widget.item.quantity % 1 == 0 ? 0 : 2),
    );
    _priceController = TextEditingController(
      text: widget.item.unitPrice.toStringAsFixed(widget.item.unitPrice % 1 == 0 ? 0 : 2),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.item.product;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.r20)),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Edit ${p.name}',
                        style: AppTypography.cardTitle.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  'Available in Stock: ${p.currentStock.toStringAsFixed(p.currentStock % 1 == 0 ? 0 : 1)} ${p.unit}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),

                // Quantity Input
                CustomTextField(
                  controller: _qtyController,
                  label: 'Quantity (${p.unit}) *',
                  hintText: '1',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.format_list_numbered,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter quantity';
                    final num = double.tryParse(val.trim());
                    if (num == null || num <= 0) return 'Must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Price Input
                CustomTextField(
                  controller: _priceController,
                  label: 'Unit Rate (₹ per ${p.unit}) *',
                  hintText: '0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.currency_rupee,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter price';
                    final num = double.tryParse(val.trim());
                    if (num == null || num < 0) return 'Enter valid rate';
                    return null;
                  },
                ),
                const SizedBox(height: 22),

                CustomButton(
                  text: 'Update Quantity',
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    final newQty = double.parse(_qtyController.text.trim());
                    final newPrice = double.parse(_priceController.text.trim());

                    Navigator.pop(context, {
                      'quantity': newQty,
                      'price': newPrice,
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
