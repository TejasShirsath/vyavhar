import 'package:flutter/foundation.dart';
import '../models/invoice.dart';
import '../models/product.dart';
import '../services/billing_service.dart';

class BillingItemDraft {
  final Product product;
  double quantity;
  double unitPrice;

  BillingItemDraft({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalAmount => quantity * unitPrice;
}

class BillingProvider with ChangeNotifier {
  final BillingService _service = BillingService();

  List<Invoice> _invoices = [];
  List<Invoice> _allInvoices = [];
  String _selectedStatus = 'All';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  // --- Bill Creation Stepper State ---
  int _currentStep = 0; // 0: Customer, 1: Add Products, 2: Capture Photo, 3: Review

  // Step 1: Customer
  String _customerName = '';
  String _customerPhone = '';
  String _customerAddress = '';
  String? _customerId;
  String? _customerImagePath;

  // Step 2: Products Cart
  final List<BillingItemDraft> _cartItems = [];

  // Step 3: Delivery Photographs
  final List<String> _capturedPhotos = [];

  // Step 4: Review & Financials
  double _discount = 0.0;
  double _gstRate = 0.0; // e.g. 0, 5, 12, 18%
  double _additionalCharges = 0.0;
  double _paidAmount = 0.0;
  bool _isCustomPaidAmount = false;
  String _paymentMode = 'Cash'; // 'Cash', 'UPI', 'Bank Transfer', 'Credit'
  String _notes = '';

  // Getters
  List<Invoice> get invoices => _invoices;
  List<Invoice> get allInvoices => _allInvoices;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get currentStep => _currentStep;
  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  String get customerAddress => _customerAddress;
  String? get customerId => _customerId;
  String? get customerImagePath => _customerImagePath;
  List<BillingItemDraft> get cartItems => List.unmodifiable(_cartItems);
  List<String> get capturedPhotos => List.unmodifiable(_capturedPhotos);

  double get discount => _discount;
  double get gstRate => _gstRate;
  double get additionalCharges => _additionalCharges;
  double get paidAmount => _isCustomPaidAmount ? _paidAmount : grandTotal;
  String get paymentMode => _paymentMode;
  String get notes => _notes;

  double get subtotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.totalAmount);
  double get discountedAmount => (subtotal - _discount).clamp(0.0, double.infinity);
  double get gstAmount => (discountedAmount * _gstRate) / 100.0;
  double get grandTotal => discountedAmount + gstAmount + _additionalCharges;

  // --- Invoice History Actions ---

  Future<void> loadInvoices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _service.getInvoices(
          status: _selectedStatus,
          searchQuery: _searchQuery,
        ),
        _service.getInvoices(status: 'All'),
      ]);
      _invoices = futures[0];
      _allInvoices = futures[1];
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectStatus(String status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    loadInvoices();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadInvoices();
  }

  // --- Create Bill Stepper Actions ---

  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 3) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void setCustomerDetails({
    required String name,
    required String phone,
    String? address,
    String? customerId,
    String? imagePath,
  }) {
    _customerName = name;
    _customerPhone = phone;
    _customerAddress = address ?? '';
    _customerId = customerId;
    _customerImagePath = imagePath;
    notifyListeners();
  }

  void addProductToCart(Product product, {double quantity = 1.0, double? customPrice}) {
    final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _cartItems[existingIndex].quantity += quantity;
      if (customPrice != null) {
        _cartItems[existingIndex].unitPrice = customPrice;
      }
    } else {
      _cartItems.add(
        BillingItemDraft(
          product: product,
          quantity: quantity,
          unitPrice: customPrice ?? product.sellingPrice,
        ),
      );
    }
    notifyListeners();
  }

  void toggleProductSelection(Product product) {
    final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _cartItems.removeAt(existingIndex);
    } else {
      _cartItems.add(
        BillingItemDraft(
          product: product,
          quantity: 1.0,
          unitPrice: product.sellingPrice,
        ),
      );
    }
    notifyListeners();
  }

  void updateCartItemQuantity(int index, double newQty) {
    if (index >= 0 && index < _cartItems.length) {
      if (newQty <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = newQty;
      }
      notifyListeners();
    }
  }

  void updateCartItemPrice(int index, double newPrice) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index].unitPrice = newPrice;
      notifyListeners();
    }
  }

  void updateCartItem(int index, {required double quantity, required double unitPrice}) {
    if (index >= 0 && index < _cartItems.length) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = quantity;
        _cartItems[index].unitPrice = unitPrice;
      }
      notifyListeners();
    }
  }

  void removeCartItem(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  void addCapturedPhoto(String path) {
    _capturedPhotos.add(path);
    notifyListeners();
  }

  void removeCapturedPhoto(int index) {
    if (index >= 0 && index < _capturedPhotos.length) {
      _capturedPhotos.removeAt(index);
      notifyListeners();
    }
  }

  void setDiscount(double value) {
    _discount = value;
    notifyListeners();
  }

  void setGstRate(double value) {
    _gstRate = value;
    notifyListeners();
  }

  void setAdditionalCharges(double value) {
    _additionalCharges = value;
    notifyListeners();
  }

  void setPaidAmount(double value) {
    _paidAmount = value;
    _isCustomPaidAmount = true;
    notifyListeners();
  }

  void setPaymentMode(String mode) {
    _paymentMode = mode;
    notifyListeners();
  }

  void setNotes(String value) {
    _notes = value;
    notifyListeners();
  }

  void resetBillForm() {
    _currentStep = 0;
    _customerName = '';
    _customerPhone = '';
    _customerAddress = '';
    _customerId = null;
    _customerImagePath = null;
    _cartItems.clear();
    _capturedPhotos.clear();
    _discount = 0.0;
    _gstRate = 0.0;
    _additionalCharges = 0.0;
    _paidAmount = 0.0;
    _isCustomPaidAmount = false;
    _paymentMode = 'Cash';
    _notes = '';
    notifyListeners();
  }

  Future<Invoice?> submitInvoice() async {
    if (_customerName.trim().isEmpty) {
      _errorMessage = 'Customer Name is required';
      notifyListeners();
      return null;
    }
    if (_customerPhone.trim().isEmpty) {
      _errorMessage = 'Customer Phone is required';
      notifyListeners();
      return null;
    }
    if (_cartItems.isEmpty) {
      _errorMessage = 'Please add at least one item to the bill';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final itemsData = _cartItems.map((item) {
        return {
          'productId': item.product.id,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
        };
      }).toList();

      final invoice = await _service.createInvoice(
        customerId: _customerId,
        customerName: _customerName.trim(),
        customerPhone: _customerPhone.trim(),
        customerAddress: _customerAddress.trim().isNotEmpty ? _customerAddress.trim() : null,
        itemsData: itemsData,
        discount: _discount,
        gstRate: _gstRate,
        additionalCharges: _additionalCharges,
        paidAmount: _isCustomPaidAmount ? _paidAmount : grandTotal,
        paymentMode: _paymentMode,
        notes: _notes.trim().isNotEmpty ? _notes.trim() : null,
        photoPaths: List<String>.from(_capturedPhotos),
      );

      resetBillForm();
      await loadInvoices();
      return invoice;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelInvoice(String invoiceId) async {
    try {
      await _service.cancelInvoice(invoiceId);
      await loadInvoices();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordPayment(String invoiceId, double amount) async {
    try {
      await _service.recordPayment(invoiceId, amount);
      await loadInvoices();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
