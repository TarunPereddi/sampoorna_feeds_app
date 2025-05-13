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
  

  /// Creates a sales order header and returns the order details
  Future<Map<String, dynamic>> createSalesOrder({
    required String customerNo,
    required String shipToCode,
    required String locationCode,
    required String salesPersonCode,
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
  }

  /// Adds a line item to an existing sales order
  Future<Map<String, dynamic>> addSalesOrderLine({
    required String documentNo,
    required String itemNo,
    required String locationCode,
    required int quantity,
  }) async {
    // Create request body
    Map<String, dynamic> body = {
      "Document_No": documentNo,
      "Type": "Item",
      "No": itemNo,
      "Location_Code": locationCode,
      "Quantity": quantity
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
    
    // Combine filters with 'and'
    queryParams['\$filter'] = filters.join(' and ');
    
    // Log the query to debug
    debugPrint('Customer search query: ${Uri.parse('$baseUrl/CustomerList').replace(queryParameters: queryParams)}');
    
    final response = await get('CustomerList', queryParams: queryParams);
    
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
}