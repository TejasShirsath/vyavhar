import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/product.dart';
import '../../providers/inventory_provider.dart';
import '../../services/photo_service.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? productToEdit;

  const AddEditProductScreen({super.key, this.productToEdit});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;
  late TextEditingController _minAlertController;
  late TextEditingController _supplierController;

  String? _imagePath;
  final PhotoService _photoService = PhotoService();
  String _selectedCategory = 'Snacks';
  String _selectedUnit = 'kg';
  bool _isLoading = false;

  final List<String> _categories = [
    'Snacks',
    'Beverages',
    'Raw Material',
    'Sweets',
    'Spices',
    'Groceries',
    'Other',
  ];

  final List<String> _units = [
    'kg',
    'gram',
    'box',
    'packet',
    'piece',
    'liter',
    'bottle',
    'carton',
  ];

  bool get isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _purchasePriceController = TextEditingController(
      text: p != null ? p.purchasePrice.toStringAsFixed(0) : '',
    );
    _sellingPriceController = TextEditingController(
      text: p != null ? p.sellingPrice.toStringAsFixed(0) : '',
    );
    _stockController = TextEditingController(
      text: p != null ? p.currentStock.toStringAsFixed(0) : '0',
    );
    _minAlertController = TextEditingController(
      text: p != null ? p.minStockAlert.toStringAsFixed(0) : '5',
    );
    _supplierController = TextEditingController(text: p?.supplierName ?? '');
    _imagePath = p?.imagePath;

    if (p != null) {
      if (_categories.contains(p.category)) {
        _selectedCategory = p.category;
      } else {
        _categories.insert(0, p.category);
        _selectedCategory = p.category;
      }
      if (_units.contains(p.unit)) {
        _selectedUnit = p.unit;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _minAlertController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

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
        title: Text(
          isEditing ? 'Edit Product' : 'Add New Product',
          style: AppTypography.brandTitle.copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Selector Card
                Center(
                  child: GestureDetector(
                    onTap: _showImagePickerOptions,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimens.r16),
                        border: Border.all(
                          color: _imagePath != null
                              ? AppColors.primary
                              : AppColors.border,
                          width: _imagePath != null ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.r16 - 1),
                        child:
                            _imagePath != null && File(_imagePath!).existsSync()
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(_imagePath!),
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    right: 4,
                                    bottom: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _imagePath = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withOpacity(
                                            0.85,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 26,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Add Photo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Product Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Product Name *',
                  hintText: 'e.g. Kaju Katli, Besan Laddu',
                  prefixIcon: Icons.shopping_bag_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Product name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Quantity & Unit Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quantity (Current / Initial Stock)
                    Expanded(
                      flex: 3,
                      child: CustomTextField(
                        controller: _stockController,
                        label: 'Quantity *',
                        hintText: '0',
                        prefixIcon: Icons.inventory_2_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (val) {
                          if (val == null || double.tryParse(val) == null) {
                            return 'Enter quantity';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Unit Dropdown
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Unit *',
                            style: AppTypography.labelMedium,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppDimens.r12,
                              ),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedUnit,
                                items: _units.map((u) {
                                  return DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedUnit = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pricing Row: Purchase Price & Selling Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _purchasePriceController,
                        label: 'Purchase Cost (₹) *',
                        hintText: '0',
                        prefixIcon: Icons.currency_rupee,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (val) {
                          if (val == null || double.tryParse(val) == null) {
                            return 'Enter valid cost';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _sellingPriceController,
                        label: 'Selling Price (₹) *',
                        hintText: '0',
                        prefixIcon: Icons.currency_rupee,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (val) {
                          if (val == null || double.tryParse(val) == null) {
                            return 'Enter valid price';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Low Stock Alert Threshold
                CustomTextField(
                  controller: _minAlertController,
                  label: 'Low Stock Alert At *',
                  hintText: '5',
                  prefixIcon: Icons.warning_amber_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (val) {
                    if (val == null || double.tryParse(val) == null) {
                      return 'Enter alert qty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Supplier Name (Optional)
                CustomTextField(
                  controller: _supplierController,
                  label: 'Supplier (Optional)',
                  hintText: 'e.g. Royal Cashew Processors',
                  prefixIcon: Icons.storefront_outlined,
                ),
                const SizedBox(height: 32),

                // Submit Button
                CustomButton(
                  text: isEditing ? 'Update Product' : 'Save Product',
                  isLoading: _isLoading,
                  onPressed: _saveProduct,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final purchasePrice = double.parse(_purchasePriceController.text.trim());
    final sellingPrice = double.parse(_sellingPriceController.text.trim());
    final stock = double.parse(_stockController.text.trim());
    final minAlert = double.parse(_minAlertController.text.trim());
    final supplier = _supplierController.text.trim().isNotEmpty
        ? _supplierController.text.trim()
        : null;

    final inventory = context.read<InventoryProvider>();

    if (isEditing) {
      final updated = widget.productToEdit!.copyWith(
        name: name,
        category: _selectedCategory,
        unit: _selectedUnit,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        currentStock: stock,
        minStockAlert: minAlert,
        supplierName: supplier,
        imagePath: _imagePath,
      );
      final success = await inventory.updateProduct(updated);
      setState(() => _isLoading = false);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(inventory.errorMessage ?? 'Update failed')),
          );
        }
      }
    } else {
      final product = await inventory.addProduct(
        name: name,
        category: _selectedCategory,
        unit: _selectedUnit,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        initialStock: stock,
        minStockAlert: minAlert,
        supplierName: supplier,
        imagePath: _imagePath,
      );
      setState(() => _isLoading = false);
      if (mounted) {
        if (product != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${product.name} added successfully!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(inventory.errorMessage ?? 'Failed to add product'),
            ),
          );
        }
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.r20),
        ),
      ),
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Product Image', style: AppTypography.cardTitle),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Take Photo', style: AppTypography.body),
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await _photoService.captureFromCamera();
                  if (path != null && mounted) {
                    setState(() => _imagePath = path);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: AppTypography.body,
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await _photoService.pickFromGallery();
                  if (path != null && mounted) {
                    setState(() => _imagePath = path);
                  }
                },
              ),
              if (_imagePath != null) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _imagePath = null);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
