import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../services/inventory_service.dart';

class InventoryProvider with ChangeNotifier {
  final InventoryService _service = InventoryService();

  List<Product> _products = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> _summary = {
    'totalProducts': 0,
    'totalQuantity': 0.0,
    'totalStockValue': 0.0,
    'lowStockCount': 0,
    'outOfStockCount': 0,
    'availableCount': 0,
  };

  List<Product> get products => _products;
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get summary => _summary;

  List<Product> get lowStockProducts => _products.where((p) => p.isLowStock).toList();
  List<Product> get outOfStockProducts => _products.where((p) => p.isOutOfStock).toList();

  Future<void> initialize() async {
    await loadCategories();
    await loadProducts();
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _service.getCategories();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _service.getProducts(
        category: _selectedCategory,
        query: _searchQuery,
      );
      _summary = await _service.getInventorySummary();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    loadProducts();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadProducts();
  }

  Future<Product?> addProduct({
    required String name,
    required String category,
    required double purchasePrice,
    required double sellingPrice,
    required double initialStock,
    String unit = 'piece',
    double minStockAlert = 5.0,
    String? supplierName,
    String? imagePath,
  }) async {
    try {
      final product = await _service.addProduct(
        name: name,
        category: category,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        initialStock: initialStock,
        unit: unit,
        minStockAlert: minStockAlert,
        supplierName: supplierName,
        imagePath: imagePath,
      );
      await loadCategories();
      await loadProducts();
      return product;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await _service.updateProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _service.deleteProduct(id);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordPurchase({
    required String productId,
    required double quantity,
    required double purchasePrice,
    String? supplierName,
  }) async {
    try {
      await _service.recordPurchaseStock(
        productId: productId,
        quantity: quantity,
        purchasePrice: purchasePrice,
        supplierName: supplierName,
      );
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordWastage({
    required String productId,
    required double quantity,
    required String reason,
    String? notes,
  }) async {
    try {
      await _service.recordWastage(
        productId: productId,
        quantity: quantity,
        reason: reason,
        notes: notes,
      );
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<StockMovement>> getProductHistory(String productId) async {
    return await _service.getProductMovements(productId);
  }

  Future<List<StockMovement>> getAllMovements({int limit = 50}) async {
    return await _service.getAllStockMovements(limit: limit);
  }

  Future<Product?> getProductById(String productId) async {
    return await _service.getProductById(productId);
  }
}
