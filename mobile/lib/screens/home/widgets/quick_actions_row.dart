import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';

class QuickActionsRow extends StatelessWidget {
  final VoidCallback onNewSale;
  final VoidCallback onAddStock;
  final VoidCallback onAddProduct;
  final VoidCallback onRecordWastage;

  const QuickActionsRow({
    super.key,
    required this.onNewSale,
    required this.onAddStock,
    required this.onAddProduct,
    required this.onRecordWastage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildAction(
          icon: Icons.point_of_sale,
          label: 'New Sale',
          onTap: onNewSale,
        ),
        _buildAction(
          icon: Icons.add_shopping_cart,
          label: 'Add Stock',
          onTap: onAddStock,
        ),
        _buildAction(
          icon: Icons.add_box_outlined,
          label: 'Add Product',
          onTap: onAddProduct,
        ),
        _buildAction(
          icon: Icons.delete_sweep_outlined,
          label: 'Wastage',
          onTap: onRecordWastage,
        ),
      ],
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.r12),
      child: Container(
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.r12),
          border: Border.all(color: AppColors.border),
          boxShadow: AppDimens.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
