import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/product.dart';
import '../../providers/billing_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/reports_provider.dart';
import '../../services/photo_service.dart';
import 'invoice_pdf_preview_screen.dart';
import 'widgets/add_customer_dialog.dart';
import 'widgets/edit_quantity_dialog.dart';
import 'widgets/select_items_dialog.dart';

class CreateBillScreen extends StatefulWidget {
  const CreateBillScreen({super.key});

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  final PhotoService _photoService = PhotoService();

  // Step 1: Customer search controller
  final TextEditingController _customerSearchController =
      TextEditingController();
  String _customerSearchQuery = '';

  // Step 4: Financial Controllers
  final TextEditingController _discountController = TextEditingController(
    text: '',
  );
  final TextEditingController _paidAmountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _hasInitializedPaidAmount = false;
  bool _isUserEditedPaidAmount = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
      context.read<InventoryProvider>().loadProducts();
      final billing = context.read<BillingProvider>();
      billing.resetBillForm();
      _hasInitializedPaidAmount = false;
      _isUserEditedPaidAmount = false;
    });
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _discountController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final currentStep = billing.currentStep;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (currentStep > 0) {
              billing.previousStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Create Bill',
          style: AppTypography.brandTitle.copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 4-Step Stepper Indicator
            _buildStepperHeader(currentStep),

            // Step Content
            Expanded(child: _buildCurrentStepView(currentStep, billing)),
          ],
        ),
      ),

      // Pinned Bottom Button
      bottomNavigationBar: Container(
        color: AppColors.background,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: _buildBottomActionButton(currentStep, billing),
      ),
    );
  }

  // --- 1. 4-Step Stepper Header ---
  Widget _buildStepperHeader(int currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepItem(
            stepIndex: 0,
            title: 'Customer',
            currentStep: currentStep,
          ),
          _buildStepConnector(isPassed: currentStep >= 1),
          _buildStepItem(
            stepIndex: 1,
            title: 'Add Items',
            currentStep: currentStep,
          ),
          _buildStepConnector(isPassed: currentStep >= 2),
          _buildStepItem(
            stepIndex: 2,
            title: 'Photo',
            currentStep: currentStep,
          ),
          _buildStepConnector(isPassed: currentStep >= 3),
          _buildStepItem(
            stepIndex: 3,
            title: 'Review',
            currentStep: currentStep,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int stepIndex,
    required String title,
    required int currentStep,
  }) {
    final bool isDone = currentStep > stepIndex;
    final bool isActive = currentStep == stepIndex;

    Color circleColor = AppColors.border;
    Color textColor = AppColors.textMuted;
    Widget innerWidget = Text(
      '${stepIndex + 1}',
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );

    if (isDone) {
      circleColor = AppColors.primary;
      textColor = AppColors.textPrimary;
      innerWidget = const Icon(Icons.check, size: 13, color: Colors.white);
    } else if (isActive) {
      circleColor = AppColors.primary;
      textColor = AppColors.primary;
      innerWidget = Text(
        '${stepIndex + 1}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: (isDone || isActive)
                ? AppColors.primary
                : AppColors.surfaceVariant,
            shape: BoxShape.circle,
            border: Border.all(color: circleColor, width: 1.5),
          ),
          alignment: Alignment.center,
          child: innerWidget,
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({required bool isPassed}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: isPassed ? AppColors.primary : AppColors.border,
      ),
    );
  }

  // --- 2. Switch Views based on Step ---
  Widget _buildCurrentStepView(int step, BillingProvider billing) {
    switch (step) {
      case 0:
        return _buildStep1Customer(billing);
      case 1:
        return _buildStep2Products(billing);
      case 2:
        return _buildStep3CapturePhoto(billing);
      case 3:
      default:
        return _buildStep4Review(billing);
    }
  }

  // ==========================================
  // STEP 1: SELECT OR ADD CUSTOMER
  // ==========================================
  Widget _buildStep1Customer(BillingProvider billing) {
    final customerProvider = context.watch<CustomerProvider>();
    final allCustomers = customerProvider.customers;

    final filteredCustomers = allCustomers.where((c) {
      if (_customerSearchQuery.isEmpty) return true;
      final q = _customerSearchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Search Bar and "Add New Customer" button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Customer', style: AppTypography.cardTitle),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.primaryContainer,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.rFull),
                      ),
                    ),
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text(
                      'New Customer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () => _openAddCustomerDialog(billing),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: _customerSearchController,
                isSearch: true,
                hintText: 'Search customer by name or phone...',
                onChanged: (val) =>
                    setState(() => _customerSearchQuery = val.trim()),
                suffixIcon: _customerSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _customerSearchController.clear();
                          setState(() => _customerSearchQuery = '');
                        },
                      )
                    : null,
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'All Customers',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        // Scrollable Customers List
        Expanded(
          child: customerProvider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : filteredCustomers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_off_outlined,
                            size: 36,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Customers Found',
                          style: AppTypography.cardTitle,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap "+ New Customer" above to create and select one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  itemCount: filteredCustomers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final c = filteredCustomers[index];
                    final isSelected =
                        billing.customerId == c.id ||
                        (billing.customerPhone == c.phone &&
                            billing.customerName == c.name);

                    return Container(
                      decoration: AppDimens.cardDecoration().copyWith(
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppDimens.r16),
                        onTap: () {
                          if (isSelected) {
                            // Tap again to unselect
                            billing.setCustomerDetails(
                              name: '',
                              phone: '',
                              address: '',
                              customerId: null,
                              imagePath: null,
                            );
                          } else {
                            // Select customer
                            billing.setCustomerDetails(
                              name: c.name,
                              phone: c.phone,
                              address: c.address,
                              customerId: c.id,
                              imagePath: c.imagePath,
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              _buildCustomerAvatar(
                                name: c.name,
                                imagePath: c.imagePath,
                                size: 46,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: AppTypography.cardTitle.copyWith(
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      c.phone,
                                      style: AppTypography.bodySmall,
                                    ),
                                    if (c.address != null &&
                                        c.address!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        c.address!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: AppColors.textMuted,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCustomerAvatar({
    required String name,
    required String? imagePath,
    required double size,
  }) {
    final hasImage =
        imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.file(
                File(imagePath),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildInitials(name, size),
              )
            : _buildInitials(name, size),
      ),
    );
  }

  Widget _buildInitials(String name, double size) {
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  void _openAddCustomerDialog(BillingProvider billing) {
    showDialog(
      context: context,
      builder: (ctx) => AddCustomerDialog(
        onCustomerAdded: (newCustomer) async {
          final customerProvider = context.read<CustomerProvider>();
          final messenger = ScaffoldMessenger.of(context);
          final created = await customerProvider.addCustomer(
            name: newCustomer.name,
            phone: newCustomer.phone,
            address: newCustomer.address,
            imagePath: newCustomer.imagePath,
          );
          if (mounted && created != null) {
            billing.setCustomerDetails(
              name: created.name,
              phone: created.phone,
              address: created.address,
              customerId: created.id,
              imagePath: created.imagePath,
            );
            Navigator.pop(ctx);
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  'Customer "${created.name}" created and selected!',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // ==========================================
  // STEP 2: ITEMS IN BILL (WITH "+ Add Items" POPUP & EDIT QTY)
  // ==========================================
  Widget _buildStep2Products(BillingProvider billing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer Header Banner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.r12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _buildCustomerAvatar(
                  name: billing.customerName,
                  imagePath: billing.customerImagePath,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Billing for: ${billing.customerName} (${billing.customerPhone})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action Row: "+ Add Items" Button & Count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Items Added', style: AppTypography.cardTitle),
                  Text(
                    '${billing.cartItems.length} items in current bill',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.rFull),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Add Items',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                onPressed: () => _openSelectItemsDialog(),
              ),
            ],
          ),
        ),

        // Items List or Empty State
        Expanded(
          child: billing.cartItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart,
                            size: 42,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Items Added Yet',
                          style: AppTypography.cardTitle,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap the "+ Add Items" button above to browse and select products.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        CustomButton(
                          text: '+ Add Items',
                          width: 150,
                          height: 42,
                          onPressed: () => _openSelectItemsDialog(),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: billing.cartItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = billing.cartItems[index];

                    return Container(
                      decoration: AppDimens.cardDecoration(),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Product Image
                          _buildProductImageThumbnail(item.product, size: 60),
                          const SizedBox(width: 12),

                          // Product details & rate
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: AppTypography.cardTitle.copyWith(
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Qty: ${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)} ${item.product.unit}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '@ ${CurrencyFormatter.format(item.unitPrice)}',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(item.totalAmount),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Edit Quantity Icon Button
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            tooltip: 'Change Quantity',
                            onPressed: () =>
                                _openEditQuantityDialog(billing, index, item),
                          ),

                          // Delete Item Button
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.error,
                            ),
                            tooltip: 'Remove',
                            onPressed: () => billing.removeCartItem(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Total Amount Summary Bar at the bottom of the items list
        if (billing.cartItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total Items Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${billing.cartItems.length} products added',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(billing.subtotal),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _openSelectItemsDialog() {
    showDialog(context: context, builder: (ctx) => const SelectItemsDialog());
  }

  Future<void> _openEditQuantityDialog(
    BillingProvider billing,
    int index,
    BillingItemDraft item,
  ) async {
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (ctx) => EditQuantityDialog(itemIndex: index, item: item),
    );

    if (result != null) {
      final newQty = result['quantity'] ?? item.quantity;
      final newPrice = result['price'] ?? item.unitPrice;
      billing.updateCartItem(index, quantity: newQty, unitPrice: newPrice);
    }
  }

  Widget _buildProductImageThumbnail(Product p, {required double size}) {
    final hasImage =
        p.imagePath != null &&
        p.imagePath!.isNotEmpty &&
        File(p.imagePath!).existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimens.r12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.r12 - 1),
        child: hasImage
            ? Image.file(
                File(p.imagePath!),
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: size * 0.45,
                    color: AppColors.primary,
                  ),
                ),
              )
            : Center(
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: size * 0.45,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }

  // ==========================================
  // STEP 3: CAPTURE PHOTO (DELIVERY PROOF)
  // ==========================================
  Widget _buildStep3CapturePhoto(BillingProvider billing) {
    final photos = billing.capturedPhotos;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Take Product Photo Big Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: AppDimens.cardDecoration(),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppDimens.r16),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Take Delivery Photo (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Take Photo',
                  icon: Icons.camera_alt_outlined,
                  onPressed: () async {
                    final path = await _photoService.captureFromCamera();
                    if (path != null) {
                      billing.addCapturedPhoto(path);
                    }
                  },
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Choose from Gallery',
                  icon: Icons.image_outlined,
                  isSecondary: true,
                  onPressed: () async {
                    final path = await _photoService.pickFromGallery();
                    if (path != null) {
                      billing.addCapturedPhoto(path);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Photo Preview Section
          const Text('Photo Preview', style: AppTypography.cardTitle),
          const SizedBox(height: 12),

          if (photos.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.r16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  'No photos captured yet.\n(You can also skip or proceed directly to review)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final photoPath = photos[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.r12),
                        child: Container(
                          width: 140,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Image.file(
                            File(photoPath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: AppColors.surfaceVariant,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => billing.removeCapturedPhoto(index),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xCC000000),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 4: REVIEW & SETTLEMENT (2 CLEAN BOXES)
  // ==========================================
  Widget _buildStep4Review(BillingProvider billing) {
    if (!_hasInitializedPaidAmount) {
      _hasInitializedPaidAmount = true;
      _paidAmountController.text = billing.grandTotal.toStringAsFixed(0);
      billing.setPaidAmount(billing.grandTotal);
    }

    final double balanceDue = billing.grandTotal - billing.paidAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BOX 1: BILL SUMMARY (Customer, Item List with Qty & Price, Totals)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDimens.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Customer details
                Row(
                  children: [
                    _buildCustomerAvatar(
                      name: billing.customerName,
                      imagePath: billing.customerImagePath,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            billing.customerName.isEmpty
                                ? 'Guest Customer'
                                : billing.customerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            billing.customerPhone.isNotEmpty
                                ? billing.customerPhone
                                : 'No contact provided',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (billing.capturedPhotos.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(AppDimens.rFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.camera_alt_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${billing.capturedPhotos.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (billing.customerAddress.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    billing.customerAddress,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 12),

                // Table Header
                Row(
                  children: const [
                    Expanded(
                      flex: 5,
                      child: Text(
                        'ITEM',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'QTY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'TOTAL',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Items list
                ...billing.cartItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            item.product.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)} ${item.product.unit}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            CurrencyFormatter.format(item.totalAmount),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 10),

                // Bill Totals (Subtotal, Discount, Grand Total)
                _buildPriceRow(
                  'Subtotal',
                  CurrencyFormatter.format(billing.subtotal),
                ),
                if (billing.discount > 0)
                  _buildPriceRow(
                    'Discount',
                    '- ${CurrencyFormatter.format(billing.discount)}',
                    isGreen: true,
                  ),
                const SizedBox(height: 4),
                const Divider(color: AppColors.border, height: 8),
                _buildPriceRow(
                  'Grand Total',
                  CurrencyFormatter.format(billing.grandTotal),
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // BOX 2: PAYMENT SETTLEMENT (Discount input, Paid Amount, Payment Mode, Notes, Balance)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDimens.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Settlement',
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(height: 14),

                // Amount Paid & Payment Mode
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _paidAmountController,
                        label: 'Amount Paid (₹) *',
                        hintText: '0',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (val) {
                          _isUserEditedPaidAmount = true;
                          billing.setPaidAmount(double.tryParse(val) ?? 0.0);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Mode',
                            style: AppTypography.labelMedium,
                          ),
                          const SizedBox(height: 6),
                          Container(
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
                                value: billing.paymentMode,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Cash',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.payments_outlined,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Cash'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'UPI',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.qr_code_scanner,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                        SizedBox(width: 8),
                                        Text('UPI'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Bank Transfer',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance_outlined,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Bank Transfer'),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) billing.setPaymentMode(val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Discount field
                CustomTextField(
                  controller: _discountController,
                  label: 'Discount (₹)',
                  hintText: '0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (val) {
                    final discount = double.tryParse(val) ?? 0.0;
                    billing.setDiscount(discount);
                    if (!_isUserEditedPaidAmount) {
                      _paidAmountController.text =
                          billing.grandTotal.toStringAsFixed(0);
                      billing.setPaidAmount(billing.grandTotal);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Notes
                CustomTextField(
                  controller: _notesController,
                  label: 'Note (Optional)',
                  hintText: 'Delivered at shop entrance',
                  onChanged: (val) => billing.setNotes(val),
                ),

                const SizedBox(height: 12),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 8),

                // Quick Summary inside settlement
                _buildPriceRow(
                  'Paid Amount',
                  CurrencyFormatter.format(billing.paidAmount),
                ),
                if (balanceDue > 0)
                  _buildPriceRow(
                    'Balance Pending (Due)',
                    CurrencyFormatter.format(balanceDue),
                    isRed: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    bool isGreen = false,
    bool isRed = false,
  }) {
    Color col = AppColors.textPrimary;
    if (isGreen) col = AppColors.success;
    if (isRed) col = AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: col,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 17 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold ? AppColors.primary : col,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Bottom Action Button ---
  Widget _buildBottomActionButton(int step, BillingProvider billing) {
    if (step == 0) {
      // Step 1: Select Customer
      final bool isCustomerSelected =
          billing.customerName.trim().isNotEmpty &&
          billing.customerPhone.trim().isNotEmpty;

      return CustomButton(
        text: isCustomerSelected ? 'Next →' : 'Select Customer',
        onPressed: () {
          if (!isCustomerSelected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select or add a customer to proceed'),
              ),
            );
            return;
          }
          billing.nextStep();
        },
      );
    } else if (step == 1) {
      // Step 2: Add Products
      return CustomButton(
        text: 'Continue to Photo (${billing.cartItems.length} items) →',
        onPressed: () {
          if (billing.cartItems.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please add at least one product to the bill'),
              ),
            );
            return;
          }
          billing.nextStep();
        },
      );
    } else if (step == 2) {
      // Step 3: Capture Photo
      return CustomButton(
        text: 'Continue to Review →',
        onPressed: () {
          billing.nextStep();
        },
      );
    } else {
      // Step 4: Review & Generate
      return CustomButton(
        text: 'Generate Bill & Invoice PDF',
        icon: Icons.receipt_long,
        isLoading: billing.isLoading,
        onPressed: () async {
          final invoice = await billing.submitInvoice();
          if (invoice != null && mounted) {
            context.read<InventoryProvider>().loadProducts();
            context.read<ReportsProvider>().loadAllReports();
            final business = context.read<BusinessProvider>().profile;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => InvoicePdfPreviewScreen(
                  invoice: invoice,
                  business: business,
                ),
              ),
            );
          } else if (billing.errorMessage != null && mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(billing.errorMessage!)));
          }
        },
      );
    }
  }
}
