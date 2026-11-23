import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/customer.dart';
import '../../../services/photo_service.dart';

class AddCustomerDialog extends StatefulWidget {
  final Function(Customer) onCustomerAdded;

  const AddCustomerDialog({super.key, required this.onCustomerAdded});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final PhotoService _photoService = PhotoService();

  String? _imagePath;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.r20)),
      ),
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Customer Photo', style: AppTypography.cardTitle.copyWith(fontSize: 16)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Take Photo from Camera'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await _photoService.captureFromCamera();
                  if (path != null) setState(() => _imagePath = path);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final path = await _photoService.pickFromGallery();
                  if (path != null) setState(() => _imagePath = path);
                },
              ),
              if (_imagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Remove Photo', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _imagePath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.r20)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
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
                    const Text('Add New Customer', style: AppTypography.sectionTitle),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Customer Photo Picker Avatar
                Center(
                  child: GestureDetector(
                    onTap: _showImagePickerOptions,
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: ClipOval(
                            child: _imagePath != null && File(_imagePath!).existsSync()
                                ? Image.file(
                                    File(_imagePath!),
                                    fit: BoxFit.cover,
                                    width: 80,
                                    height: 80,
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.person_add_alt_1_outlined,
                                      size: 36,
                                      color: AppColors.primary,
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Photo (Optional)',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),

                // Customer Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Customer Name *',
                  hintText: 'e.g. Ramesh Kumar, Om Traders',
                  prefixIcon: Icons.person_outline,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter customer name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Mobile Number
                CustomTextField(
                  controller: _phoneController,
                  label: 'Mobile Number *',
                  hintText: '+91 98231 12345',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Address (Optional)
                CustomTextField(
                  controller: _addressController,
                  label: 'Address (Optional)',
                  hintText: 'e.g. Shop 5, Market Yard, Pune',
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: 'Save Customer',
                  isLoading: _isLoading,
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _isLoading = true);

                    final newCustomer = Customer(
                      id: '',
                      name: _nameController.text.trim(),
                      phone: _phoneController.text.trim(),
                      address: _addressController.text.trim().isNotEmpty
                          ? _addressController.text.trim()
                          : null,
                      imagePath: _imagePath,
                      createdAt: DateTime.now(),
                    );

                    widget.onCustomerAdded(newCustomer);
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
