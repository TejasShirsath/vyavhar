import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/product.dart';
import '../../providers/inventory_provider.dart';
import '../inventory/product_detail_screen.dart';

enum StockFilterType { lowStock, outOfStock }

class FilteredStockListScreen extends StatelessWidget {
  final StockFilterType filterType;

  const FilteredStockListScreen({
    super.key,
    required this.filterType,
  });

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final bool isLowStockFilter = filterType == StockFilterType.lowStock;

    final List<Product> filteredProducts = isLowStockFilter
        ? inventory.products.where((p) => p.isLowStock).toList()
        : inventory.products.where((p) => p.isOutOfStock).toList();

    final title = isLowStockFilter ? 'Low Stock Items' : 'Out of Stock Items';
    final accentColor = isLowStockFilter ? AppColors.warning : AppColors.error;

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
          title,
          style: AppTypography.brandTitle.copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: filteredProducts.isEmpty
            ? EmptyStateWidget(
                icon: isLowStockFilter ? Icons.check_circle_outline : Icons.inventory_2_outlined,
                title: isLowStockFilter ? 'No Low Stock Items' : 'No Out of Stock Items',
                message: isLowStockFilter
                    ? 'All your products have sufficient stock levels.'
                    : 'None of your inventory items are out of stock.',
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => inventory.loadProducts(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: filteredProducts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = filteredProducts[index];
                    return _buildProductCard(context, p, accentColor);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product p, Color accentColor) {
    return Container(
      decoration: AppDimens.cardDecoration(),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: p.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppDimens.r16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Product Image thumbnail box
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.r12 - 1),
                  child: p.imagePath != null &&
                          p.imagePath!.isNotEmpty &&
                          File(p.imagePath!).existsSync()
                      ? Image.file(
                          File(p.imagePath!),
                          fit: BoxFit.cover,
                          width: 68,
                          height: 68,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              _getProductIcon(p.category),
                              size: 30,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            _getProductIcon(p.category),
                            size: 30,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Title, Stock, and Alert Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: AppTypography.cardTitle.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Stock: ${p.currentStock.toStringAsFixed(p.currentStock % 1 == 0 ? 0 : 1)} ${p.unit}',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (p.isOutOfStock)
                          StatusBadge.outOfStock()
                        else if (p.isLowStock)
                          StatusBadge.lowStock(),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Alert Threshold: ${p.minStockAlert.toStringAsFixed(0)} ${p.unit}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                size: 22,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getProductIcon(String category) {
    switch (category.toLowerCase()) {
      case 'beverages':
        return Icons.local_drink;
      case 'raw material':
        return Icons.inventory_2;
      case 'sweets':
      case 'snacks':
        return Icons.bakery_dining;
      case 'spices':
        return Icons.grain;
      default:
        return Icons.shopping_bag_outlined;
    }
  }
}
