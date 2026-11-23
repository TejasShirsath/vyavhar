import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/supplier.dart';
import '../services/customer_service.dart';

class CustomerProvider with ChangeNotifier {
  final CustomerService _service = CustomerService();

  List<Customer> _customers = [];
  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Customer> get customers => _customers;
  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCustomers({String? searchQuery}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _customers = await _service.getCustomers(searchQuery: searchQuery);
      _suppliers = await _service.getSuppliers();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Customer?> addCustomer({
    required String name,
    required String phone,
    String? address,
    String? imagePath,
  }) async {
    try {
      final c = await _service.addCustomer(name: name, phone: phone, address: address, imagePath: imagePath);
      await loadCustomers();
      return c;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Supplier?> addSupplier({
    required String name,
    required String phone,
    String? address,
  }) async {
    try {
      final s = await _service.addSupplier(name: name, phone: phone, address: address);
      await loadCustomers();
      return s;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<List<Invoice>> getCustomerInvoices(String phone) async {
    return await _service.getCustomerInvoices(phone);
  }
}
