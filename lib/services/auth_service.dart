// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/sales_person.dart';
import '../models/customer.dart';
import 'api_service.dart';

class ForgotPasswordResult {
  final bool success;
  final String message;
  final int? statusCode;

  ForgotPasswordResult({
    required this.success,
    required this.message,
    this.statusCode,
  });
}

class AuthService extends ChangeNotifier {
  /// Returns the user ID for API calls: code for sales/team, no for customer
  String? get currentUserId {
    if (_currentUser is SalesPerson) {
      return (_currentUser as SalesPerson).code;
    } else if (_currentUser is Customer) {
      return (_currentUser as Customer).no;
    }
    return null;
  }
  dynamic _currentUser; // SalesPerson for sales/team, Customer for customer
  bool _isLoading = false;
  String? _error;
  static const String _userKey = 'current_user';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _rememberMeKey = 'remember_me';

  dynamic get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Get the original username (user ID) for API calls that need the login username
  Future<String?> get originalUsername async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_usernameKey);
    } catch (e) {
      print('Error getting original username: $e');
      return null;
    }
  }

  // Helper to convert Customer to JSON (since Customer may not have toJson)
  Map<String, dynamic> _customerToJson(Customer customer) {
    return {
      'no': customer.no,
      'name': customer.name,
      'phone': customer.phone,
      'address': customer.address,
      'emailId': customer.emailId,
      'city': customer.city,
      'stateCode': customer.stateCode,
      'gstNo': customer.gstNo,
      'panNo': customer.panNo,
      'customerPriceGroup': customer.customerPriceGroup,
      'balanceLcy': customer.balanceLcy,
      'blocked': customer.blocked,
    };
  }

  // Save user session to local storage
  Future<void> _saveSession(dynamic user, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user is SalesPerson) {
        await prefs.setString(_userKey, json.encode(user.toJson()));
      } else if (user is Customer) {
        await prefs.setString(_userKey, json.encode(_customerToJson(user)));
      } else if (user is String) {
        await prefs.setString(_userKey, user);
      }
      await prefs.setString(_usernameKey, username);
    } catch (e) {
      print('Error saving session: $e');
    }
  }
  // Check for existing session on app startup
  Future<void> checkExistingSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        try {
          final userMap = json.decode(userJson);
          if (userMap is Map<String, dynamic>) {
            // Try SalesPerson first, fallback to Customer
            if (userMap.containsKey('code') || userMap.containsKey('Code')) {
              _currentUser = SalesPerson.fromJson(userMap);
            } else if (userMap.containsKey('no') || userMap.containsKey('No')) {
              // Defensive: ensure all required fields are present for Customer
              _currentUser = Customer.fromJson({
                'No': userMap['no'] ?? userMap['No'],
                'Name': userMap['name'] ?? userMap['Name'],
                'Phone_No': userMap['phone'] ?? userMap['Phone_No'],
                'Address': userMap['address'] ?? userMap['Address'],
                'E_Mail': userMap['emailId'] ?? userMap['E_Mail'],
                'City': userMap['city'] ?? userMap['City'],
                'State_Code': userMap['stateCode'] ?? userMap['State_Code'],
                'GST_Registration_No': userMap['gstNo'] ?? userMap['GST_Registration_No'],
                'P_A_N_No': userMap['panNo'] ?? userMap['P_A_N_No'],
                'Customer_Price_Group': userMap['customerPriceGroup'] ?? userMap['Customer_Price_Group'],
                'Balance_LCY': userMap['balanceLcy'] ?? userMap['Balance_LCY'] ?? 0,
                'Blocked': userMap['blocked'] ?? userMap['Blocked'],
              });
            } else {
              _currentUser = null;
            }
          } else if (userMap is String) {
            _currentUser = userMap;
          } else {
            _currentUser = null;
          }
        } catch (_) {
          // If not JSON, treat as string (legacy customerNo)
          _currentUser = userJson;
        }
        notifyListeners();
      }
    } catch (e) {
      // If there's an error loading the session, clear it
      await clearSession();
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
  
  Future<dynamic> login(String username, String password, {String persona = 'sales'}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final ApiService apiService = ApiService();

      // Select endpoint based on persona
      String endpoint;
      if (persona == 'sales') {
        endpoint = 'API_SalesPersonLoginAppWebuser';
      } else if (persona == 'team') {
        endpoint = 'API_SalesTeamLoginAppWebuser';
      } else if (persona == 'customer') {
        endpoint = 'API_LoginAppCustomer';
      } else {
        endpoint = 'API_SalesPersonLoginAppWebuser'; // fallback
      }

      try {
        final loginResponse = await apiService.post(
          endpoint,
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
          return 'first_login';
        } else if (loginResponse['value'] == 'OK') {
          if (persona == 'customer') {
            // Fetch customer details
            final customerRes = await apiService.get(
              "CustomerCard",
              queryParams: {"\$filter": "No eq '$username'"},
            );
            final customers = customerRes['value'] as List?;
            if (customers == null || customers.isEmpty) {
              _error = 'Customer not found';
              _isLoading = false;
              notifyListeners();
              return false;
            }
            // Use Customer model
            final customerObj = Customer.fromJson(customers[0]);
            _currentUser = customerObj;
            await _saveSession(customerObj, username);
            _isLoading = false;
            notifyListeners();
            return true;
          } else {
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
            
            // Create initial SalesPerson object
            var salesPerson = SalesPerson.fromJson(salesPersons[0]);
            
            // Now fetch Webuser details to override code and location
            final webuserResponse = await apiService.get('Webuser', 
              queryParams: {'\$filter': "User_Name eq '$username'"});
            
            final webusers = webuserResponse['value'] as List;
            
            if (webusers.isNotEmpty) {
              final webuser = webusers[0];
              // Override code and location with data from Webuser
              salesPerson = SalesPerson(
                code: webuser['Sales_Person_Code'] ?? salesPerson.code,
                name: salesPerson.name,
                responsibilityCenter: salesPerson.responsibilityCenter,
                blocked: salesPerson.blocked,
                email: salesPerson.email,
                location: webuser['Location_Code'] ?? salesPerson.location,
                phoneNo: salesPerson.phoneNo,
              );
            }
            
            _currentUser = salesPerson;
            await _saveSession(_currentUser!, username);
            _isLoading = false;
            notifyListeners();
            return true;
          }
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
  
  Future<ForgotPasswordResult> forgotPassword(String userId, String mobileNumber, {String persona = 'sales'}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final ApiService apiService = ApiService();
      String endpoint;
      Map<String, dynamic> body;
      if (persona == 'customer') {
        endpoint = 'API_ForgetPasswordCustomer';
        body = {
          'userID': userId,
          'registredModileNo': mobileNumber,
        };
      } else {
        endpoint = 'API_ForgetPasswordForWebUser';
        body = {
          'userID': userId,
          'registredModileNo': mobileNumber,
        };
      }

      final response = await apiService.post(
        endpoint,
        body: body,
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
    String persona = 'sales',
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final ApiService apiService = ApiService();
      Map<String, dynamic> result;
      
      if (persona == 'customer') {
        // Customer-specific reset password API
        result = await apiService.resetPasswordCustomer(
          userId: userId,
          oldPassword: oldPassword,
          newPassword: newPassword,
        );
      } else {
        // Default (sales/team)
        result = await apiService.resetPassword(
          userId: userId,
          oldPassword: oldPassword,
          newPassword: newPassword,
        );
      }
      
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
      );
    }
  }
  
  Future<bool> completeFirstTimeLogin(String username, String password, {String persona = 'sales'}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final ApiService apiService = ApiService();
      
      // Use persona-specific login API
      String endpoint;
      if (persona == 'team') {
        endpoint = 'API_SalesTeamLoginAppWebuser';
      } else if (persona == 'customer') {
        endpoint = 'API_LoginAppCustomer';
      } else {
        endpoint = 'API_SalesPersonLoginAppWebuser'; 
      }
      
      // Try the login again after password change
      final loginResponse = await apiService.post(
        endpoint,
        body: {
          'userID': username,
          'password': password,
        },
      );
      
      if (loginResponse['value'] == 'OK') {
        if (persona == 'customer') {
          // Fetch customer details
          final customerRes = await apiService.get(
            "CustomerCard",
            queryParams: {"\$filter": "No eq '$username'"},
          );
          final customers = customerRes['value'] as List?;
          if (customers == null || customers.isEmpty) {
            _error = 'Customer not found';
            _isLoading = false;
            notifyListeners();
            return false;
          }
          // Use Customer model
          final customerObj = Customer.fromJson(customers[0]);
          _currentUser = customerObj;
          await _saveSession(customerObj, username);
        } else {
          // Get the sales person details for sales/team personas
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
          
          // Create initial SalesPerson object
          var salesPerson = SalesPerson.fromJson(salesPersons[0]);
          
          // Now fetch Webuser details to override code and location
          final webuserResponse = await apiService.get('Webuser', 
            queryParams: {'\$filter': "User_Name eq '$username'"});
          
          final webusers = webuserResponse['value'] as List;
          
          if (webusers.isNotEmpty) {
            final webuser = webusers[0];
            // Override code and location with data from Webuser
            salesPerson = SalesPerson(
              code: webuser['Sales_Person_Code'] ?? salesPerson.code,
              name: salesPerson.name,
              responsibilityCenter: salesPerson.responsibilityCenter,
              blocked: salesPerson.blocked,
              email: salesPerson.email,
              location: webuser['Location_Code'] ?? salesPerson.location,
              phoneNo: salesPerson.phoneNo,
            );
          }
          
          _currentUser = salesPerson;
          await _saveSession(_currentUser!, username);
        }
        
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