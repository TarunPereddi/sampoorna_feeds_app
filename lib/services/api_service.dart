import 'dart:convert';
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

  // Get customers list with pagination and search
  Future<List<dynamic>> getCustomers({String? searchQuery, int limit = 20, int offset = 0}) async {
    Map<String, String> queryParams = {};

    // Add top and skip for pagination
    queryParams['\$top'] = limit.toString();
    queryParams['\$skip'] = offset.toString();

    // Add filter if search query is provided and has at least 3 characters
    if (searchQuery != null && searchQuery.length >= 3) {
      queryParams['\$filter'] = "contains(Name,'$searchQuery') or contains(No,'$searchQuery')";
    }

    final response = await get('CustomerList', queryParams: queryParams);
    return response['value'];
  }

  // Get ship-to addresses for a customer
  Future<List<dynamic>> getShipToAddresses({String? customerNo}) async {
    Map<String, String>? queryParams;

    if (customerNo != null && customerNo.isNotEmpty) {
      queryParams = {'\$filter': "Customer_No eq '$customerNo'"};
    }

    final response = await get('ShiptoList', queryParams: queryParams);
    return response['value'];
  }

  // Get locations
  Future<List<dynamic>> getLocations() async {
    final response = await get('LocationList');
    return response['value'];
  }

  // Get items based on location
  Future<List<dynamic>> getItems({String? locationCode}) async {
    Map<String, String>? queryParams;

    if (locationCode != null && locationCode.isNotEmpty) {
      queryParams = {'\$filter': "Item_Location eq '$locationCode'"};
    }

    final response = await get('ItemList', queryParams: queryParams);
    return response['value'];
  }

  // Get sales orders
  Future<List<dynamic>> getSalesOrders() async {
    final response = await get('SalesOrder');
    return response['value'];
  }

  // Get sales order lines for a specific order
  Future<List<dynamic>> getSalesOrderLines(String documentNo) async {
    final queryParams = {'\$filter': "Document_No eq '$documentNo'"};
    final response = await get('SalesLine', queryParams: queryParams);
    return response['value'];
  }
}