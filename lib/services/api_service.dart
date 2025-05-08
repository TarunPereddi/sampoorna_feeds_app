import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://api.sampoornafeeds.in:4052/BCtest/ODataV4';
  static const String username = 'JobQueue';
  static const String password = 'India@12good';
  static const String company = 'Sampoorna Feeds Pvt. Ltd';

  // Create basic auth header
  Map<String, String> get _headers {
    String basicAuth = 'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    return {
      'Authorization': basicAuth,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  // Generic GET method for API calls
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    Map<String, String> params = {
      'Company': company,
    };

    if (queryParams != null) {
      params.addAll(queryParams);
    }

    Uri uri = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: params);
    debugPrint('GET Request: $uri');

    try {
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to the API: $e');
    }
  }

  // For POST requests
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, Map<String, String>? queryParams}) async {
    Map<String, String> params = {
      'Company': company,
    };

    if (queryParams != null) {
      params.addAll(queryParams);
    }

    Uri uri = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: params);
    debugPrint('POST Request: $uri');
    debugPrint('POST Body: $body');

    try {
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to post data: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to the API: $e');
    }
  }

  // Get sales person information
  Future<List<dynamic>> getSalesPersons({String? code}) async {
    Map<String, String>? queryParams;
    
    if (code != null && code.isNotEmpty) {
      queryParams = {'\$filter': "Code eq '$code'"};
    }
    
    final response = await get('SalesPerson', queryParams: queryParams);
    return response['value'];
  }

  // Get customers list filtered by sales person code
  Future<List<dynamic>> getCustomers({
    String? searchQuery, 
    int limit = 20, 
    int offset = 0,
    String? salesPersonCode,
  }) async {
    Map<String, String> queryParams = {};

    // Add top and skip for pagination
    queryParams['\$top'] = limit.toString();
    queryParams['\$skip'] = offset.toString();

    // Build filter string
    List<String> filters = [];
    
    // Add sales person filter if provided
    if (salesPersonCode != null && salesPersonCode.isNotEmpty) {
      filters.add("Salesperson_Code eq '$salesPersonCode'");
    }

    // Add search filter if provided
    if (searchQuery != null && searchQuery.length >= 3) {
      filters.add("(contains(Name,'$searchQuery') or contains(No,'$searchQuery'))");
    }

    // Combine filters with 'and' if multiple
    if (filters.isNotEmpty) {
      queryParams['\$filter'] = filters.join(' and ');
    }

    final response = await get('CustomerList', queryParams: queryParams);
    return response['value'];
  }

  // Get recent orders for sales person
  Future<List<dynamic>> getRecentSalesOrders({required String salesPersonName, int limit = 20}) async {
    final now = DateTime.now();
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    final formattedDate = "${twoDaysAgo.year}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}";
    
    final queryParams = {
      '\$filter': "Saels_Person_Name eq '$salesPersonName' and Order_Date ge $formattedDate",
      '\$top': limit.toString(),
      '\$orderby': 'Order_Date desc'
    };
    
    final response = await get('SalesOrder', queryParams: queryParams);
    return response['value'];
  }

  // Get ship-to addresses for a customer
  Future<List<dynamic>> getShipToAddresses({required String customerNo}) async {
    final queryParams = {'\$filter': "Customer_No eq '$customerNo'"};
    final response = await get('ShiptoAddress', queryParams: queryParams);
    return response['value'];
  }
  
  // Create a new ship-to address
  Future<dynamic> createShipToAddress(Map<String, dynamic> shipToData) async {
    return await post('ShiptoAddress', body: shipToData);
  }

  // Get locations filtered by location codes
  Future<List<dynamic>> getLocations({List<String>? locationCodes}) async {
    Map<String, String>? queryParams;

    if (locationCodes != null && locationCodes.isNotEmpty) {
      // Create a filter with OR conditions for each location code
      final locationFilters = locationCodes.map((code) => "Code eq '$code'").join(' or ');
      queryParams = {'\$filter': locationFilters};
    }

    final response = await get('LocationList', queryParams: queryParams);
    return response['value'];
  }

  // Get items based on location
  Future<List<dynamic>> getItems({required String locationCode}) async {
    final queryParams = {'\$filter': "Item_Location eq '$locationCode'"};
    final response = await get('ItemList', queryParams: queryParams);
    return response['value'];
  }

  // Get sales orders with filtering and pagination
  Future<List<dynamic>> getSalesOrders({
    String? searchQuery,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? salesPersonName,
    int limit = 10,
    int offset = 0,
  }) async {
    Map<String, String> queryParams = {};
    List<String> filters = [];

    // Add pagination
    queryParams['\$top'] = limit.toString();
    queryParams['\$skip'] = offset.toString();
    queryParams['\$orderby'] = 'Order_Date desc';

    // Add sales person filter
    if (salesPersonName != null && salesPersonName.isNotEmpty) {
      filters.add("Saels_Person_Name eq '$salesPersonName'");
    }

    // Add search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (searchQuery.startsWith('SO/') || searchQuery.contains('/')) {
        // If it looks like an order number
        filters.add("No eq '$searchQuery'");
      } else {
        // Otherwise, assume customer name search
        filters.add("contains(Sell_to_Customer_Name,'$searchQuery')");
      }
    }

    // Add status filter
    if (status != null && status != 'All') {
      filters.add("Status eq '$status'");
    }

    // Add date filters
    if (fromDate != null) {
      final formattedFromDate = "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}";
      filters.add("Order_Date ge $formattedFromDate");
    }

    if (toDate != null) {
      // Add one day to toDate for inclusive filtering
      final nextDay = toDate.add(const Duration(days: 1));
      final formattedToDate = "${nextDay.year}-${nextDay.month.toString().padLeft(2, '0')}-${nextDay.day.toString().padLeft(2, '0')}";
      filters.add("Order_Date lt $formattedToDate");
    }

    // Combine filters with 'and' if multiple
    if (filters.isNotEmpty) {
      queryParams['\$filter'] = filters.join(' and ');
    }

    final response = await get('SalesOrder', queryParams: queryParams);
    return response['value'];
  }

  // Get sales order lines for a specific order
  Future<List<dynamic>> getSalesOrderLines(String documentNo) async {
    final queryParams = {'\$filter': "Document_No eq '$documentNo'"};
    final response = await get('SalesLine', queryParams: queryParams);
    return response['value'];
  }
  
  // Create a sales order
  Future<dynamic> createSalesOrder(Map<String, dynamic> orderData) async {
    return await post('SalesOrder', body: orderData);
  }
}