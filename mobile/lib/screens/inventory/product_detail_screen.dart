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
import '../../models/product.dart';
import '../../models/stock_movement.dart';
import '../../providers/inventory_provider.dart';
import 'add_edit_product_screen.dart';
import 'record_purchase_dialog.dart';
import 'record_wastage_dialog.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<StockMovement> _movements = [];
  bool _isLoadingHistory = true;
  Product? _cachedProduct;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    final p = await context.read<InventoryProvider>().getProductById(widget.productId);
    if (mounted && p != null) {
      setState(() {
        _cachedProduct = p;
      });
    }
  }

  Future<void> _loadHistory() async {
    final inventory = context.read<InventoryProvider>();
    final history = await inventory.getProductHistory(widget.productId);
    if (mounted) {
      setState(() {
        _movements = history;
        _isLoadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final matching = inventory.products.where((p) => p.id == widget.productId);
    if (matching.isNotEmpty) {
      _cachedProduct = matching.first;
    }
    final product = _cachedProduct;

    if (product == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Product Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(product.name, style: AppTypography.brandTitle.copyWith(fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditProductScreen(productToEdit: product),
                ),
              ).then((_) => _loadHistory());
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _confirmDeleteProduct(product),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Product Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: AppDimens.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.imagePath != null &&
                        product.imagePath!.isNotEmpty &&
                        File(product.imagePath!).existsSync()) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.r12),
                        child: Image.file(
                          File(product.imagePath!),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name, style: AppTypography.greeting),
                            ],
                          ),
                        ),
                        if (product.isOutOfStock)
                          StatusBadge.outOfStock()
                        else if (product.isLowStock)
                          StatusBadge.lowStock()
                        else
                          const StatusBadge(
                            label: 'In Stock',
                            backgroundColor: AppColors.successLight,
                            textColor: AppColors.success,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Grid of 4 Key Numbers
                    Row(
                      children: [
                        _buildStatBox(
                          'Current Stock',
                          '${product.currentStock.toStringAsFixed(product.currentStock % 1 == 0 ? 0 : 1)} ${product.unit}',
                          highlight: true,
                          subtitle: 'Alert below: ${product.minStockAlert.toStringAsFixed(product.minStockAlert % 1 == 0 ? 0 : 1)} ${product.unit}',
                        ),
                        const SizedBox(width: 12),
                        _buildStatBox(
                          'Stock Valuation',
                          CurrencyFormatter.format(product.stockValue),
                          subtitle: 'at purchase cost',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatBox(
                          'Cost (Weighted Avg)',
                          CurrencyFormatter.format(product.purchasePrice),
                          subtitle: 'Margin: ${product.profitMargin.toStringAsFixed(1)}%',
                        ),
                        const SizedBox(width: 12),
                        _buildStatBox(
                          'Selling Price',
                          CurrencyFormatter.format(product.sellingPrice),
                          subtitle: 'per ${product.unit}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons Row: Add Stock & Record Wastage
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: '+ Add Stock',
                      icon: Icons.add_shopping_cart,
                      fontSize: 13,
                      height: 48,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => RecordPurchaseDialog(preselectedProduct: product),
                        ).then((_) {
                          _loadHistory();
                          _fetchProduct();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      text: 'Record Wastage',
                      icon: Icons.delete_outline,
                      fontSize: 13,
                      height: 48,
                      isSecondary: true,
                      backgroundColor: AppColors.errorLight,
                      textColor: AppColors.error,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => RecordWastageDialog(preselectedProduct: product),
                        ).then((_) {
                          _loadHistory();
                          _fetchProduct();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stock Movement History
              const Text('Stock Movement History', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),

              if (_isLoadingHistory)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_movements.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: AppDimens.cardDecoration(),
                  child: const Center(
                    child: Text('No movements recorded yet.', style: AppTypography.bodySmall),
                  ),
                )
              else
                Container(
                  decoration: AppDimens.cardDecoration(),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _movements.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: AppColors.divider,
                      indent: 56,
                    ),
                    itemBuilder: (context, index) {
                      final m = _movements[index];
                      final isAddition = m.isAddition;
                      final isWastage = m.movementType.toUpperCase() == 'WASTAGE' ||
                          (m.reason != null && m.reason!.toLowerCase().contains('damage'));

                      final Color badgeBg;
                      final Color iconColor;
                      final Color qtyColor;

                      if (isAddition) {
                        badgeBg = AppColors.successLight;
                        iconColor = AppColors.success;
                        qtyColor = AppColors.success;
                      } else if (isWastage) {
                        badgeBg = AppColors.errorLight;
                        iconColor = AppColors.error;
                        qtyColor = AppColors.error;
                      } else {
                        // Sold via / regular sales: black/gray color
                        badgeBg = AppColors.surfaceVariant;
                        iconColor = AppColors.textSecondary;
                        qtyColor = AppColors.textPrimary;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: badgeBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAddition ? Icons.arrow_downward : Icons.arrow_upward,
                                size: 16,
                                color: iconColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.reason ?? m.movementType,
                                    style: AppTypography.cardTitle.copyWith(fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormatter.formatDateTime(m.createdAt),
                                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isAddition ? '+' : '-'}${m.quantity.toStringAsFixed(m.quantity % 1 == 0 ? 0 : 1)} ${product.unit}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: qtyColor,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(m.totalValue),
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, {bool highlight = false, String? subtitle}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlight ? AppColors.primaryContainer : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimens.r12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: highlight ? AppColors.primary : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final inventory = context.read<InventoryProvider>();
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              final success = await inventory.deleteProduct(product.id);
              if (mounted && success) {
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('"${product.name}" deleted.')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
