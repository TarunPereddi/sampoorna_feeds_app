import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/customer.dart';

// Define a class to hold pagination results
class PaginationResult<T> {
  final List<T> items;
  final int totalCount;
  
  PaginationResult({
    required this.items,
    required this.totalCount,
  });
}

class ApiService {
  static const String baseUrl = 'http://api.sampoornafeeds.in:7048/BC230/ODataV4';
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
      // Ensure proper content-type header for JSON
      Map<String, String> headers = _headers;
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(body),
      );
      
      debugPrint('POST Response Status: ${response.statusCode}');
      debugPrint('POST Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to post data: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to the API: $e');
    }
  }

  // Reset password with old and new password
  Future<Map<String, dynamic>> resetPassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await post(
        'API_ResetPassword',
        body: {
          'userID': userId,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );
      
      return {
        'success': true,
        'message': response['value'] ?? 'Password reset successfully',
      };
    } catch (e) {
      debugPrint('Error resetting password: $e');
      
      // Extract only the meaningful part of the error message
      String errorMessage = 'Password reset failed';
      
      final errorString = e.toString();
      if (errorString.contains('"message"')) {
        try {
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
      
      return {
        'success': false,
        'message': errorMessage,
      };
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
      '\$orderby': 'No desc' // Order by Order ID in descending order to show latest orders on top
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

  // Create pincode entry (fire and forget - no response handling needed)
  Future<void> createPinCode({
    required String code,
    required String city,
  }) async {
    final body = {
      "Code": code,
      "City": city,
      "Country_Region_Code": "IN", // Hard-coded as requested
    };
    
    debugPrint('Creating pincode entry: $body');
    
    try {
      // Make the POST request but don't handle the response
      await post('PinCode', body: body);
      debugPrint('Pincode entry created successfully (response ignored as requested)');
    } catch (e) {
      debugPrint('Error creating pincode entry: $e');
      // Don't rethrow - we don't care about the response as requested
    }
  }

  // Get states for dropdown
  Future<List<dynamic>> getStates() async {
    try {
      final response = await get('State');
      return response['value'];
    } catch (e) {
      debugPrint('Error fetching states: $e');
      return [];
    }
  }
  
  // Get units of measurement for a specific item
  Future<List<dynamic>> getItemUnitsOfMeasure(String itemNo) async {
    if (itemNo.isEmpty) {
      return [];
    }

    Map<String, String> queryParams = {'\$filter': "Item_No eq '$itemNo'"};
    
    try {
      final response = await get('ItemUnitofMeasure', queryParams: queryParams);
      return response['value'];
    } catch (e) {
      print('Error fetching units of measure: $e');
      return [];
    }
  }

  // Get sales price for an item based on customer price group, location, and UOM
  Future<Map<String, dynamic>?> getSalesPrice({
    required String itemNo,
    required String customerPriceGroup,
    required String locationCode,
    required String unitOfMeasure,
  }) async {
    if (itemNo.isEmpty || customerPriceGroup.isEmpty || 
        locationCode.isEmpty || unitOfMeasure.isEmpty) {
      debugPrint('Missing required parameters for getSalesPrice');
      return null;
    }

    try {
      // Create the request body - all values as strings
      Map<String, String> body = {
        "salesType": "1", // Fixed value, as a string
        "salesCode": customerPriceGroup,
        "itemNo": itemNo,
        "location": locationCode,
        "unitofmeasure": unitOfMeasure,
        "orderDate": DateFormat('yyyy-MM-dd').format(DateTime.now()), // Today's date
      };
      
      debugPrint('Sales Price API Request: ${body.toString()}');
      
      // Make the POST request
      final response = await post('Barcode_Web_Services_SalesPriceAPI', body: body);
      
      // Check if we have valid data
      if (response['value'] == null) {
        debugPrint('No value returned from sales price API');
        return null;
      }
      
      String jsonString = response['value'] as String;
      
      // Try to parse the JSON using a more robust approach
      try {
        Map<String, dynamic> parsedData = jsonDecode(jsonString);
        
        if (parsedData.containsKey('Response')) {
          debugPrint('Parsed sales price data successfully: ${parsedData['Response']}');
          return parsedData['Response'];
        } else {
          debugPrint('No Response key in data: $parsedData');
        }
      } catch (e) {
        debugPrint('JSON parse error: $e');
        debugPrint('Raw JSON: $jsonString');
      }
      
      return null;
    } catch (e) {
      debugPrint('Exception in getSalesPrice: $e');
      return null;
    }
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

  // Get a single location by code - optimized for faster lookups
  Future<Map<String, dynamic>?> getSingleLocation(String locationCode) async {
    if (locationCode.isEmpty) return null;
    
    try {
      final queryParams = {'\$filter': "Code eq '$locationCode'"};
      final response = await get('LocationList', queryParams: queryParams);
      
      final locations = response['value'] as List;
      return locations.isNotEmpty ? locations.first : null;
    } catch (e) {
      debugPrint('Error fetching single location: $e');
      return null;
    }
  }

  // Get items based on location with optional search
  Future<List<dynamic>> getItems({
    required String locationCode,
    String? searchQuery,
  }) async {
    List<String> filters = ["Item_Location eq '$locationCode'"];
    
    // Add search filter if provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Use wildcard search based on API requirements
      final wildcardSearch = "*$searchQuery*";
      filters.add("(Description eq '$wildcardSearch')");
    }
    
    final queryParams = {'\$filter': filters.join(' and ')};
    final response = await get('ItemList', queryParams: queryParams);
    return response['value'];
  }  // Get sales orders with filtering and pagination
  Future<dynamic> getSalesOrders({
    String? searchQuery,
    String? searchFilter, // New parameter for direct filter string
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? salesPersonName,
    int limit = 10,
    int offset = 0,
    bool includeCount = false,
  }) async {
    Map<String, String> queryParams = {};
    List<String> filters = [];    // Add pagination
    queryParams['\$top'] = limit.toString();
    queryParams['\$skip'] = offset.toString();
    queryParams['\$orderby'] = 'No desc'; // Order by Order ID in descending order to show latest orders on top
    
    // Add count parameter if requested
    if (includeCount) {
      queryParams['\$count'] = 'true';
    }

    // Add sales person filter
    if (salesPersonName != null && salesPersonName.isNotEmpty) {
      filters.add("Saels_Person_Name eq '$salesPersonName'");
    }

    // Use direct search filter if provided, otherwise use searchQuery
    if (searchFilter != null && searchFilter.isNotEmpty) {
      filters.add(searchFilter);
    } else if (searchQuery != null && searchQuery.isNotEmpty) {
      if (searchQuery.toUpperCase().startsWith('SO/') || searchQuery.contains('/')) {
        // If it looks like an order number
        filters.add("No eq '$searchQuery'");
      } else {
        // Otherwise, assume customer name search with improved contains
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
    
    // If count was requested, return the full response with @odata.count
    if (includeCount) {
      return response;
    }
    
    // Otherwise just return the value array as before
    return response['value'];
  }

  // Get sales order lines for a specific order
  Future<List<dynamic>> getSalesOrderLines(String documentNo) async {
    final queryParams = {'\$filter': "Document_No eq '$documentNo'"};
    final response = await get('SalesLine', queryParams: queryParams);
    return response['value'];
  }
  
  /// Creates a sales order header and returns the order details
  Future<Map<String, dynamic>> createSalesOrder({
  required String customerNo,
  required String shipToCode,
  required String locationCode,
  required String salesPersonCode,
  DateTime? requestedDeliveryDate, // Optional parameter
}) async {
  // Create request body
  Map<String, dynamic> body = {
    "Sell_to_Customer_No": customerNo,
    "Ship_to_Code": shipToCode,
    "Salesperson_Code": salesPersonCode,
    "Location_Code": locationCode,
    "Invoice_Type": "Bill of Supply",
    "created_from_web": true
  };
    // Format date as expected by API (yyyy-MM-dd)
  // Use provided date or default to tomorrow
  DateTime deliveryDate = requestedDeliveryDate ?? DateTime.now().add(const Duration(days: 1));
  String formattedDate = DateFormat('yyyy-MM-dd').format(deliveryDate);
  body["Requested_Delivery_Date"] = formattedDate;
  
  debugPrint('Creating sales order: $body');
  
  try {
    final response = await post('SalesOrder', body: body);
    
    // Log the response for debugging
    debugPrint('Sales Order Creation Response: $response');
    
    if (response != null) {
      return response;
    } else {
      throw Exception('Empty response received when creating sales order');
    }
  } catch (e) {
    debugPrint('Error creating sales order: $e');
    throw Exception('Failed to create sales order: $e');
  }
}  /// Adds a line item to an existing sales order
  Future<Map<String, dynamic>> addSalesOrderLine({
    required String documentNo,
    required String itemNo,
    required String locationCode,
    required int quantity,
    required String unitOfMeasureCode,
  }) async {
    // Create request body
    Map<String, dynamic> body = {
      "Document_No": documentNo,
      "Type": "Item",
      "No": itemNo,
      "Location_Code": locationCode,
      "Quantity": quantity,
      "Unit_of_Measure_Code": unitOfMeasureCode
    };
    
    debugPrint('Adding sales order line: $body');
    
    try {
      final response = await post('SalesLine', body: body);
      
      // Log the response for debugging
      debugPrint('Sales Line Creation Response: $response');
      
      if (response != null) {
        return response;
      } else {
        throw Exception('Empty response received when adding sales order line');
      }
    } catch (e) {
      debugPrint('Error adding sales order line: $e');
      throw Exception('Failed to add sales order line: $e');
    }
  }

  // Get customers with pagination and count support
  Future<PaginationResult<Customer>> getCustomersWithPagination({
    required String salesPersonCode,
    String? searchQuery,
    String? blockFilter,
    required int page,
    required int pageSize,
  }) async {
    Map<String, String> queryParams = {
      '\$count': 'true',
      '\$top': pageSize.toString(),
      '\$skip': ((page - 1) * pageSize).toString(),
    };

    // Build filter string
    List<String> filters = [];
    
    // Add sales person filter
    filters.add("Salesperson_Code eq '$salesPersonCode'");
    
    // Add search filter if provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Use wildcards with eq operator instead of contains
      final wildcardSearch = "*$searchQuery*";
      
      // Add filters separately for better readability
      filters.add("Name eq '$wildcardSearch'");
      // filters.add("No eq '$wildcardSearch'");
    }
    
    // Add block filter if provided
    if (blockFilter != null && blockFilter.isNotEmpty) {
      filters.add(blockFilter);
    }
    
    // Combine filters with 'and'
    queryParams['\$filter'] = filters.join(' and ');
      // Log the query to debug
    debugPrint('Customer search query: ${Uri.parse('$baseUrl/CustomerCard').replace(queryParameters: queryParams)}');
    
    final response = await get('CustomerCard', queryParams: queryParams);
    
    // Extract total count from response
    final totalCount = response['@odata.count'] as int? ?? 0;
    
    // Map response items to Customer objects
    final items = (response['value'] as List)
        .map((item) => Customer.fromJson(item))
        .toList();
    
    return PaginationResult<Customer>(
      items: items,
      totalCount: totalCount,
    );
  }

  // Send order for approval
  Future<Map<String, dynamic>> sendOrderForApproval(String orderNo) async {
    // Create request body
    Map<String, dynamic> body = {
      "salesOrderNo": orderNo
    };
    
    debugPrint('Sending order for approval: $body');
    
    try {
      final response = await post('API_SendApprovalRequest', body: body);
      
      // Log the response for debugging
      debugPrint('Send for Approval Response: $response');
      
      // Create a standardized response structure
      Map<String, dynamic> result = {
        'success': true,
        'message': 'Order sent for approval successfully'
      };
      
      // If there's a specific message in the response, use it
      if (response != null && response is Map<String, dynamic>) {
        if (response.containsKey('message')) {
          result['message'] = response['message'];
        } else if (response.containsKey('value') && 
                  response['value'] != null && 
                  response['value'] is String) {
          result['message'] = response['value'];
        }
      }
      
      return result;    } catch (e) {
      debugPrint('Error sending order for approval: $e');
      
      String errorMessage = e.toString();
      
      // Extract message from JSON error and remove CorrelationId
      if (errorMessage.contains('"message"')) {
        try {
          final messageRegex = RegExp(r'"message"\s*:\s*"([^"]+)"');
          final match = messageRegex.firstMatch(errorMessage);
          if (match != null && match.groupCount >= 1) {
            errorMessage = match.group(1)!;
          }
        } catch (parseError) {
          // If parsing fails, use original message
        }
      }
      
      // Remove CorrelationId and everything after it
      if (errorMessage.contains('CorrelationId')) {
        errorMessage = errorMessage.split('CorrelationId')[0].trim();
        // Remove trailing period if present
        if (errorMessage.endsWith('.')) {
          errorMessage = errorMessage.substring(0, errorMessage.length - 1);
        }
      }
      
      // Create an error response
      return {
        'success': false,
        'message': errorMessage.isEmpty ? 'Failed to send order for approval' : errorMessage
      };
    }
  }


  /// Re-opens a sales order to make it editable
Future<Map<String, dynamic>> reopenSalesOrder(String orderNo) async {
  if (orderNo.isEmpty) {
    throw Exception('Order number cannot be empty');
  }
  
  final body = {
    "salesOrderNo": orderNo
  };
  
  try {
    final response = await post('API_ReOpenSalesOrder', body: body);
    return response;
  } catch (e) {
    debugPrint('Error reopening sales order: $e');
    throw Exception('Failed to reopen sales order: $e');
  }
}

/// Deletes a sales order line
Future<Map<String, dynamic>> deleteSalesOrderLine(String orderNo, int lineNo) async {
  if (orderNo.isEmpty) {
    throw Exception('Order number cannot be empty');
  }
  
  final body = {
    "orderNo": orderNo,
    "lineNo": lineNo
  };
  
  try {
    final response = await post('API_SalesOrderLine', body: body);
    return response;
  } catch (e) {
    debugPrint('Error deleting sales order line: $e');
    throw Exception('Failed to delete sales order line: $e');
  }
}

// Add this to your ApiService class
  Future<Map<String, dynamic>> getCustomerDetails(String customerNo) async {
    try {
      // First try to get from CustomerCard endpoint which has more details
      final response = await get('CustomerCard', queryParams: {'\$filter': "No eq '$customerNo'"});

      if (response.containsKey('value') &&
          response['value'] is List &&
          response['value'].isNotEmpty) {
        debugPrint('Customer details from CustomerCard: ${response['value'][0]}');
        return response['value'][0];
      }
      
      // Fallback to CustomerList endpoint
      final listResponse = await get('CustomerList', queryParams: {'\$filter': "No eq '$customerNo'"});

      if (listResponse.containsKey('value') &&
          listResponse['value'] is List &&
          listResponse['value'].isNotEmpty) {
        debugPrint('Customer details from CustomerList: ${listResponse['value'][0]}');
        return listResponse['value'][0];
      }

      throw Exception('Customer not found');
    } catch (e) {
      debugPrint('Error fetching customer details: $e');
      rethrow;
    }
  }
  // Get multiple customer details in a single request for efficiency
  Future<List<Map<String, dynamic>>> getMultipleCustomerDetails(List<String> customerNos) async {
    if (customerNos.isEmpty) {
      return [];
    }
    
    try {
      // Build a filter with OR conditions for each customer number
      final customerNoFilters = customerNos.map((no) => "No eq '$no'").join(' or ');
      final response = await get('CustomerList', queryParams: {'\$filter': customerNoFilters});

      if (response.containsKey('value') && response['value'] is List) {
        return List<Map<String, dynamic>>.from(response['value']);
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching multiple customer details: $e');
      rethrow;
    }
  }
    // Get just customer emails in a single request for efficiency
  Future<List<Map<String, dynamic>>> getCustomerEmails(List<String> customerNos) async {
    if (customerNos.isEmpty) {
      return [];
    }
    
    try {
      // Build a filter with OR conditions for each customer number
      final customerNoFilters = customerNos.map((no) => "No eq '$no'").join(' or ');      final response = await get('CustomerCard', queryParams: {
        '\$filter': customerNoFilters,
        '\$select': 'No,E_Mail,Blocked', // Select No, E_Mail and Blocked fields
      });

      if (response.containsKey('value') && response['value'] is List) {
        return List<Map<String, dynamic>>.from(response['value']);
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching customer emails: $e');
      rethrow;
    }
  }

  // Get sales person details by code
  Future<Map<String, dynamic>> getSalesPersonDetails(String code) async {
    try {
      final response = await get(
        'SalesPerson',
        queryParams: {
          '\$filter': "Code eq '$code'",
        },
      );
      
      final salesPeople = response['value'] as List;
      
      if (salesPeople.isEmpty) {
        throw Exception('Sales person not found');
      }
      
      return salesPeople.first;
    } catch (e) {
      debugPrint('Error fetching sales person details: $e');
      rethrow;
    }
  }
  // Get vendor details method removed as not needed

  // Generic POST method for API calls

  // Get invoice report for a customer
  Future<String?> getInvoiceReport({
    required String customerNo,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final body = {
        "custNo": customerNo,
        "fromDate": DateFormat('yyyy-MM-dd').format(fromDate),
        "toDate": DateFormat('yyyy-MM-dd').format(toDate),
      };
      
      final response = await post('API_GetInvoiceReport', body: body);
      
      if (response != null && response['value'] != null) {
        final value = response['value'] as String;
        return value.isNotEmpty ? value : null;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get invoice report: $e');
    }
  }

  Future<String?> getCustomerStatementReport({
    required String customerNo,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final body = {
        "custNo": customerNo,
        "fromDate": DateFormat('yyyy-MM-dd').format(fromDate),
        "toDate": DateFormat('yyyy-MM-dd').format(toDate),
      };
      
      final response = await post('API_GetCustStatementReport', body: body);
      
      if (response != null && response['value'] != null) {
        final value = response['value'] as String;
        return value.isNotEmpty ? value : null;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get customer statement report: $e');
    }
  }
    // Get customer transactions history (ledger entries)
  Future<List<Map<String, dynamic>>> getCustomerTransactions(String customerNo, {String? salesPersonCode}) async {
    try {
      String filter = "Customer_No eq '$customerNo'";
      
      // Add salesperson filter if provided
      if (salesPersonCode != null && salesPersonCode.isNotEmpty) {
        filter += " and Salesperson_Code eq '$salesPersonCode'";
      }
      
      final queryParams = {
        '\$filter': filter,
        '\$orderby': 'Posting_Date desc',
        '\$top': '10' // Limit to most recent 10 transactions
      };
      
      final response = await get('CLE', queryParams: queryParams);
      
      if (response.containsKey('value') && response['value'] is List) {
        return List<Map<String, dynamic>>.from(response['value']);
      }
      
      return [];
    } catch (e) {
      debugPrint('Error fetching customer transactions: $e');
      return [];
    }
  }

  // Get items with pagination support
  Future<PaginationResult<Map<String, dynamic>>> getItemsWithPagination({
    required String locationCode,
    String? searchQuery,
    required int page,
    required int pageSize,
  }) async {
    Map<String, String> queryParams = {
      '\$count': 'true',
      '\$top': pageSize.toString(),
      '\$skip': ((page - 1) * pageSize).toString(),
    };
    
    // Build filter string
    List<String> filters = [];
    
    // Add location filter
    filters.add("Item_Location eq '$locationCode'");
    
    // Add search filter if provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Use wildcard search based on API requirements
      final wildcardSearch = "*$searchQuery*";
      filters.add("(Description eq '$wildcardSearch')");
    }
    
    // Combine filters with 'and'
    queryParams['\$filter'] = filters.join(' and ');
    
    // Log the query for debugging
    debugPrint('Item search query: ${Uri.parse('$baseUrl/ItemList').replace(queryParameters: queryParams)}');
    
    final response = await get('ItemList', queryParams: queryParams);
    
    // Extract total count from response
    final totalCount = response['@odata.count'] as int? ?? 0;
    
    // Get items from response
    final items = (response['value'] as List<dynamic>).cast<Map<String, dynamic>>();
    
    return PaginationResult<Map<String, dynamic>>(
      items: items,
      totalCount: totalCount,
    );
  }
}
