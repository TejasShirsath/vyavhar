import 'package:flutter/foundation.dart';
import '../core/database/app_database.dart';
import '../models/business_profile.dart';
import '../services/business_service.dart';

class BusinessProvider with ChangeNotifier {
  final BusinessService _service = BusinessService();

  BusinessProfile _profile = const BusinessProfile();
  bool _isLoading = false;
  String? _errorMessage;

  BusinessProfile get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      _profile = await _service.getProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(BusinessProfile updated) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.updateProfile(updated);
      _profile = updated;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> exportBackup() async {
    try {
      return await _service.exportBackupJson();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> restoreBackup(String jsonString) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.restoreBackupJson(jsonString);
      await loadProfile();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> eraseAllData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await AppDatabase.instance.clearAllData(preserveProfile: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetToSampleData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await AppDatabase.instance.resetToSampleData();
      await loadProfile();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
