import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/id_generator.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/business_profile.dart';
import '../../providers/billing_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/reports_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final businessProvider = context.watch<BusinessProvider>();
    final profile = businessProvider.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings & Profile',
          style: AppTypography.brandTitle,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: AppDimens.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            image:
                                profile.logoPath != null &&
                                    File(profile.logoPath!).existsSync()
                                ? DecorationImage(
                                    image: FileImage(File(profile.logoPath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              profile.logoPath != null &&
                                  File(profile.logoPath!).existsSync()
                              ? null
                              : const Icon(
                                  Icons.storefront,
                                  color: Colors.white,
                                  size: 28,
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.businessName,
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (profile.tagline.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  profile.tagline,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.primary,
                          ),
                          onPressed: () =>
                              _openEditProfileDialog(context, profile),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 14),
                    _buildInfoRow('Owner Name', profile.ownerName),
                    _buildInfoRow('Contact Phone', profile.phone),
                    if (profile.address.trim().isNotEmpty)
                      _buildInfoRow('Address', profile.address),
                    if (profile.gstin != null &&
                        profile.gstin!.trim().isNotEmpty)
                      _buildInfoRow('GSTIN', profile.gstin!),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Data & Backup Section
              const Text(
                'Data & Backup Management',
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: 10),
              Container(
                decoration: AppDimens.cardDecoration(),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.cloud_download_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Export Offline Backup (JSON)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Export complete business data, inventory & invoices',
                        style: TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textMuted,
                      ),
                      onTap: () => _exportBackup(context),
                    ),
                    const Divider(
                      color: AppColors.divider,
                      height: 1,
                      indent: 56,
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Restore from Backup',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Restore database from saved backup JSON',
                        style: TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textMuted,
                      ),
                      onTap: () => _restoreBackup(context),
                    ),
                    const Divider(
                      color: AppColors.divider,
                      height: 1,
                      indent: 56,
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_forever_outlined,
                          color: AppColors.error,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Erase All Business Data',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.error,
                        ),
                      ),
                      subtitle: const Text(
                        'Permanently deletes inventory, bills, wastage & expenses',
                        style: TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textMuted,
                      ),
                      onTap: () => _confirmEraseAllData(context, profile),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // App Information
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppDimens.r16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'VYAVHAR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Smart Business. Simple Hisaab.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditProfileDialog(BuildContext context, BusinessProfile current) {
    final nameCtrl = TextEditingController(text: current.businessName);
    final ownerCtrl = TextEditingController(text: current.ownerName);
    final phoneCtrl = TextEditingController(text: current.phone);
    final addrCtrl = TextEditingController(text: current.address);
    final gstinCtrl = TextEditingController(text: current.gstin ?? '');
    final taglineCtrl = TextEditingController(text: current.tagline);
    final businessProvider = context.read<BusinessProvider>();
    final messenger = ScaffoldMessenger.of(context);
    String? currentLogoPath = current.logoPath;
    bool logoRemoved = false;

    Future<String?> pickLogo(ImageSource source) async {
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (picked == null) return null;

        final appDir = await getApplicationDocumentsDirectory();
        final logosDir = Directory(p.join(appDir.path, 'business_logos'));
        if (!await logosDir.exists()) {
          await logosDir.create(recursive: true);
        }
        final ext = p.extension(picked.path).isNotEmpty
            ? p.extension(picked.path)
            : '.png';
        final savedFile = await File(picked.path).copy(
          p.join(
            logosDir.path,
            'logo_${DateTime.now().millisecondsSinceEpoch}_${IdGenerator.uuid().substring(0, 6)}$ext',
          ),
        );
        return savedFile.path;
      } catch (_) {
        return null;
      }
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final effectiveLogoPath = logoRemoved ? null : currentLogoPath;
          final hasLogo =
              effectiveLogoPath != null && File(effectiveLogoPath).existsSync();

          return AlertDialog(
            title: const Text('Edit Business Profile'),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Business Logo Picker
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                  image: hasLogo
                                      ? DecorationImage(
                                          image: FileImage(
                                            File(effectiveLogoPath),
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: hasLogo
                                    ? null
                                    : const Icon(
                                        Icons.storefront,
                                        size: 36,
                                        color: AppColors.primary,
                                      ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: InkWell(
                                  onTap: () async {
                                    final path = await pickLogo(
                                      ImageSource.gallery,
                                    );
                                    if (path != null) {
                                      setDialogState(() {
                                        currentLogoPath = path;
                                        logoRemoved = false;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final path = await pickLogo(
                                    ImageSource.gallery,
                                  );
                                  if (path != null) {
                                    setDialogState(() {
                                      currentLogoPath = path;
                                      logoRemoved = false;
                                    });
                                  }
                                },
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  hasLogo ? 'Change Image' : 'Business Image',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              if (hasLogo) ...[
                                const Text(
                                  ' • ',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      logoRemoved = true;
                                      currentLogoPath = null;
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text(
                                    'Remove',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: nameCtrl,
                      label: 'Business Name',
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(controller: ownerCtrl, label: 'Owner Name'),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: phoneCtrl,
                      label: 'Phone Number',
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: addrCtrl,
                      label: 'Business Address',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: taglineCtrl,
                      label: 'Tagline',
                      hintText: 'e.g. Smart Business. Simple Hisaab.',
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: gstinCtrl,
                      label: 'GSTIN (Optional)',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () async {
                  final updated = current.copyWith(
                    businessName: nameCtrl.text.trim(),
                    ownerName: ownerCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    address: addrCtrl.text.trim(),
                    gstin: gstinCtrl.text.trim(),
                    tagline: taglineCtrl.text.trim(),
                    logoPath: effectiveLogoPath,
                    clearLogo: logoRemoved,
                  );
                  Navigator.pop(dialogCtx);
                  await businessProvider.updateProfile(updated);
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Business profile updated!'),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Save Changes',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final businessProvider = context.read<BusinessProvider>();
    final jsonStr = await businessProvider.exportBackup();
    if (jsonStr != null && mounted) {
      await Clipboard.setData(ClipboardData(text: jsonStr));
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Offline Backup Exported'),
          content: const Text(
            'Your full business database (inventory, invoices, stock history, and expenses) has been serialized and copied to your clipboard. You can paste it into a file or message to preserve it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _restoreBackup(BuildContext context) {
    final controller = TextEditingController();
    final businessProvider = context.read<BusinessProvider>();
    final inventoryProvider = context.read<InventoryProvider>();
    final billingProvider = context.read<BillingProvider>();
    final reportsProvider = context.read<ReportsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Restore from Backup JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste your exported JSON data below:'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{"version": 1, ...}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(dialogCtx);
                final success = await businessProvider.restoreBackup(text);
                if (mounted) {
                  if (success) {
                    await Future.wait([
                      inventoryProvider.loadProducts(),
                      billingProvider.loadInvoices(),
                      reportsProvider.loadAllReports(),
                    ]);
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Database restored successfully!'),
                      ),
                    );
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Invalid backup JSON format.'),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmEraseAllData(BuildContext context, BusinessProfile profile) {
    final businessProvider = context.read<BusinessProvider>();
    final inventoryProvider = context.read<InventoryProvider>();
    final billingProvider = context.read<BillingProvider>();
    final reportsProvider = context.read<ReportsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    // Normalize user's phone to digits only (e.g. "+91 9324038600" -> "9324038600" or last 10 digits)
    final digitsOnly = profile.phone.replaceAll(RegExp(r'\D'), '');
    final String targetNumber = digitsOnly.length > 10
        ? digitsOnly.substring(digitsOnly.length - 10)
        : digitsOnly;

    final phoneInputCtrl = TextEditingController();
    String? inputError;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 28,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Erase All Data?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This action is permanent and cannot be undone. All invoices, stock inventory, movements, wastage records, and expenses will be completely deleted.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'To confirm, please enter your registered mobile number',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (targetNumber.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Registered number: $targetNumber',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneInputCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter your mobile number',
                    errorText: inputError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.phone_android, size: 20),
                  ),
                  onChanged: (_) {
                    if (inputError != null) {
                      setDialogState(() {
                        inputError = null;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final enteredRaw = phoneInputCtrl.text.replaceAll(
                  RegExp(r'\D'),
                  '',
                );
                final enteredNormalized = enteredRaw.length > 10
                    ? enteredRaw.substring(enteredRaw.length - 10)
                    : enteredRaw;

                if (enteredNormalized.isEmpty) {
                  setDialogState(() {
                    inputError = 'Please enter your mobile number';
                  });
                  return;
                }

                // If user has a registered phone, verify it matches
                if (targetNumber.isNotEmpty &&
                    enteredNormalized != targetNumber) {
                  setDialogState(() {
                    inputError = 'Number does not match';
                  });
                  return;
                }

                Navigator.pop(dialogCtx);
                final success = await businessProvider.eraseAllData();
                if (mounted && success) {
                  await Future.wait([
                    inventoryProvider.loadProducts(),
                    billingProvider.loadInvoices(),
                    reportsProvider.loadAllReports(),
                  ]);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.error,
                      content: Text(
                        'All business data has been permanently erased.',
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Erase Everything',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
