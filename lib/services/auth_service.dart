// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import '../models/sales_person.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  SalesPerson? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  SalesPerson? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  
  Future<bool> login(String username, String password) async {
    if (password != 'admin') {
      _error = 'Invalid password';
      notifyListeners();
      return false;
    }
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final ApiService apiService = ApiService();
      
      // Get the sales person by code
      final response = await apiService.get('SalesPerson', 
        queryParams: {'\$filter': "Code eq '$username'"});
      
      final salesPersons = response['value'] as List;
      
      if (salesPersons.isEmpty) {
        _error = 'User not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      if (salesPersons[0]['Block'] == true) {
        _error = 'User is blocked';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      _currentUser = SalesPerson.fromJson(salesPersons[0]);
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _error = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}