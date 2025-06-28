// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
  String? _error;  static const String _userKey = 'current_user';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _rememberMeKey = 'remember_me';
  
  SalesPerson? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Check for existing session on app startup
  Future<void> checkExistingSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        final userMap = json.decode(userJson);
        _currentUser = SalesPerson.fromJson(userMap);
        notifyListeners();
      }
    } catch (e) {
      // If there's an error loading the session, clear it
      await clearSession();
    }
  }
  // Save user session to local storage
  Future<void> _saveSession(SalesPerson user, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(user.toJson()));
      await prefs.setString(_usernameKey, username);
    } catch (e) {
      // Handle error saving session
      print('Error saving session: $e');
    }
  }

  // Save login credentials when "Remember Me" is checked
  Future<void> saveLoginCredentials(String username, String password, bool rememberMe) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, rememberMe);
      
      if (rememberMe) {
        await prefs.setString(_usernameKey, username);
        await prefs.setString(_passwordKey, password);
      } else {
        await prefs.remove(_passwordKey);
      }
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }

  // Get saved login credentials
  Future<Map<String, dynamic>> getSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      final username = prefs.getString(_usernameKey) ?? '';
      final password = rememberMe ? (prefs.getString(_passwordKey) ?? '') : '';
      
      return {
        'username': username,
        'password': password,
        'rememberMe': rememberMe,
      };
    } catch (e) {
      print('Error loading credentials: $e');
      return {
        'username': '',
        'password': '',
        'rememberMe': false,
      };
    }
  }
  // Clear user session from local storage
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      // Don't clear username and password if remember me is enabled
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      if (!rememberMe) {
        await prefs.remove(_usernameKey);
        await prefs.remove(_passwordKey);
        await prefs.remove(_rememberMeKey);
      }
    } catch (e) {
      // Handle error clearing session
      print('Error clearing session: $e');
    }
  }
  
  Future<dynamic> login(String username, String password) async {
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
          // Check if it's a first-time login
        if (loginResponse['value'] == 'First Login') {
          _isLoading = false;
          notifyListeners();
          // Return a special result for first-time login
          return 'first_login';        } else if (loginResponse['value'] == 'OK') {
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
          await _saveSession(_currentUser!, username);
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
  
  Future<ForgotPasswordResult> resetPassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final ApiService apiService = ApiService();
      
      final result = await apiService.resetPassword(
        userId: userId,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      
      _isLoading = false;
      notifyListeners();
      
      return ForgotPasswordResult(
        success: result['success'],
        message: result['message'],
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      
      return ForgotPasswordResult(
        success: false,
        message: e.toString().replaceAll("Exception: ", ""),
      );    }
  }
  
  Future<bool> completeFirstTimeLogin(String username, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final ApiService apiService = ApiService();
      
      // Try the login again after password change
      final loginResponse = await apiService.post(
        'API_LoginApp',
        body: {
          'userID': username,
          'password': password,
        },
      );
      
      if (loginResponse['value'] == 'OK') {
        // Get the sales person details
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
        await _saveSession(_currentUser!, username);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Login failed after password change';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
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
  Future<void> logout() async {
    _currentUser = null;
    await clearSession();
    notifyListeners();
  }
}