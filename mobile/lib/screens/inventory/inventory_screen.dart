import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/product.dart';
import '../../providers/inventory_provider.dart';
import 'add_edit_product_screen.dart';
import 'product_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final products = inventory.products;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: "Inventory" title & Item Count
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Inventory',
                    style: AppTypography.brandTitle,
                  ),
                  Text(
                    '${products.length} items',
                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CustomTextField(
                controller: _searchController,
                isSearch: true,
                hintText: 'Search products...',
                onChanged: (val) {
                  inventory.setSearchQuery(val);
                },
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          inventory.setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),

            // Products List or Loading / Empty States
            Expanded(
              child: inventory.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : products.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.inventory_2_outlined,
                          title: 'No Products Found',
                          message: 'Add products to track inventory, purchases, and sales.',
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () => inventory.loadProducts(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                            itemCount: products.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final p = products[index];
                              return _buildProductCard(context, p);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),

      // Pinned Bottom Action Button: "Add Product"
      bottomSheet: Container(
        color: AppColors.background,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: CustomButton(
          text: 'Add Product',
          icon: Icons.add,
          onPressed: () => _openAddProduct(context),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product p) {
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
              // Product Image thumbnail box (increased size)
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
                        if (p.isOutOfStock) ...[
                          const SizedBox(width: 8),
                          StatusBadge.outOfStock(),
                        ] else if (p.isLowStock) ...[
                          const SizedBox(width: 8),
                          StatusBadge.lowStock(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron Arrow
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

  void _openAddProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditProductScreen(),
      ),
    );
  }
}
