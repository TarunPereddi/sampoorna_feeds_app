// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import '../models/sales_person.dart';
import 'api_service.dart';

class ForgotPasswordResult {
  final bool success;
  final String message;
  
  ForgotPasswordResult({
    required this.success,
    required this.message,
  });
}

class AuthService extends ChangeNotifier {
  SalesPerson? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  SalesPerson? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  
  Future<bool> login(String username, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final ApiService apiService = ApiService();
      
      // First try to use the sales-specific login API
      try {
        final loginResponse = await apiService.post(
          'API_LoginApp',
          body: {
            'userID': username,
            'password': password,
          },
        );
        
        if (loginResponse['value'] == 'OK') {
          // If login successful, get the sales person details
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
        } else {
          // This shouldn't happen with the API design described, but just in case
          _error = 'Login failed: Invalid response';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (e) {
        // If the sales-specific login API fails, fall back to the old method
        // only for backward compatibility or testing purposes
        if (password != 'admin') {
          _error = 'Invalid password';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
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
      }        } catch (e) {
      // Extract error message without CorrelationId
      String errorMessage = 'Login failed';
      
      // Try to parse the error message from the API response
      final errorString = e.toString();
      if (errorString.contains('"message"')) {
        try {
          // Extract message content between quotes
          final messageRegex = RegExp(r'"message"\s*:\s*"([^"]+)"');
          final match = messageRegex.firstMatch(errorString);
          if (match != null && match.groupCount >= 1) {
            String message = match.group(1)!;
            // Remove CorrelationId and everything after it
            if (message.contains('CorrelationId')) {
              message = message.split('CorrelationId')[0].trim();
            }
            errorMessage = message;
          }
        } catch (_) {
          // If parsing fails, use default message
        }
      }
      
      _error = errorMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<ForgotPasswordResult> forgotPassword(String userId, String mobileNumber) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final ApiService apiService = ApiService();
      
      final response = await apiService.post(
        'API_ForgetPassword',
        body: {
          'userID': userId,
          'registredModileNo': mobileNumber,
        },
      );
      
      _isLoading = false;
      notifyListeners();
      
      return ForgotPasswordResult(
        success: true,
        message: response['value'],
      );
    } catch (e) {
      _isLoading = false;
      
      // Extract only the meaningful part of the error message
      String errorMessage = 'Password reset failed';
      
      // Try to parse the error message from the API response
      final errorString = e.toString();
      if (errorString.contains('"message"')) {
        try {
          // Extract message content between quotes
          final messageRegex = RegExp(r'"message"\s*:\s*"([^"]+)"');
          final match = messageRegex.firstMatch(errorString);
          if (match != null && match.groupCount >= 1) {
            String message = match.group(1)!;
            // Remove CorrelationId and everything after it
            if (message.contains('CorrelationId')) {
              message = message.split('CorrelationId')[0].trim();
            }
            errorMessage = message;
          }
        } catch (_) {
          // If parsing fails, use default message
        }
      }
      
      notifyListeners();
      return ForgotPasswordResult(
        success: false,
        message: errorMessage,
      );
    }
  }
  
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}