import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../models/location.dart';
import '../../../utils/app_colors.dart';
import 'edit_order_screen.dart';

class ViewOrderScreen extends StatefulWidget {
  final String orderNo;
  
  const ViewOrderScreen({Key? key, required this.orderNo}) : super(key: key);
  
  @override
  State<ViewOrderScreen> createState() => _ViewOrderScreenState();
}

class _ViewOrderScreenState extends State<ViewOrderScreen> {
  bool _isLoading = true;
  final ApiService _apiService = ApiService();
    // Order data
  Map<String, dynamic>? _orderData;
  List<Map<String, dynamic>> _orderItems = [];
  List<Location> _locations = [];
  String? _errorMessage;
  String _loadingStatus = 'Loading order details...';
  
  // Cached total to avoid recalculation
  double? _cachedTotal;
    // Static cache for locations to avoid repeated API calls
  static final Map<String, Location> _locationCache = {};

  // Helper method to format currency values
  String _formatCurrency(double value) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return currencyFormat.format(value);
  }
  
  // Controllers for form fields (read-only)
  final TextEditingController _orderDateController = TextEditingController();
  final TextEditingController _saleCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }
  @override
  void dispose() {
    _orderDateController.dispose();
    _saleCodeController.dispose();
    super.dispose();
  }  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadingStatus = 'Loading order details...';
    });

    try {
      // Step 1: Fetch order details and order lines in parallel for better performance
      setState(() {
        _loadingStatus = 'Fetching order data...';
      });
      
      final results = await Future.wait([
        _apiService.getSalesOrders(
          searchFilter: "No eq '${widget.orderNo}'",
          limit: 1,
        ),
        _apiService.getSalesOrderLines(widget.orderNo),
      ]);

      final orderResponse = results[0];
      final orderLinesResponse = results[1];

      // Process order data
      if (orderResponse is List && orderResponse.isNotEmpty) {
        _orderData = orderResponse[0];
      } else if (orderResponse is Map<String, dynamic> &&
          orderResponse.containsKey('value') &&
          orderResponse['value'] is List &&
          orderResponse['value'].isNotEmpty) {
        _orderData = orderResponse['value'][0];
      } else {
        throw Exception('Order not found');
      }

      // Step 2: Optimized order lines processing - direct casting without heavy type checking
      setState(() {
        _loadingStatus = 'Processing order items...';
      });
      
      _orderItems = orderLinesResponse.map<Map<String, dynamic>>((line) {
        return {
          'itemNo': line['No'] ?? '',
          'itemDescription': line['Description'] ?? '',
          'quantity': (line['Quantity'] ?? 0).toDouble(),
          'price': (line['Unit_Price'] ?? 0).toDouble(),
          'unitOfMeasure': line['Unit_of_Measure_Code'] ?? '',
          'totalAmount': (line['Line_Amount'] ?? 0).toDouble(),
        };
      }).toList();      // Step 3: Load location with caching for better performance
      final locationCode = _orderData!['Location_Code'] as String?;
      if (locationCode != null && locationCode.isNotEmpty) {
        setState(() {
          _loadingStatus = 'Loading location details...';
        });
        
        // Check cache first
        if (_locationCache.containsKey(locationCode)) {
          _locations = [_locationCache[locationCode]!];
        } else {
          try {
            // Use the optimized getSingleLocation method for faster lookup
            final locationData = await _apiService.getSingleLocation(locationCode);
            if (locationData != null) {
              final location = Location(
                code: locationData['Code'] ?? locationCode,
                name: locationData['Name'] ?? locationCode,
              );
              _locations = [location];
              // Cache the location for future use
              _locationCache[locationCode] = location;
            } else {
              // Fallback if location not found
              final fallbackLocation = Location(code: locationCode, name: locationCode);
              _locations = [fallbackLocation];
              _locationCache[locationCode] = fallbackLocation;
            }
          } catch (e) {
            // Fallback if location fetch fails
            final fallbackLocation = Location(code: locationCode, name: locationCode);
            _locations = [fallbackLocation];
            _locationCache[locationCode] = fallbackLocation;
          }
        }
      }

      // Step 4: Populate form controllers
      setState(() {
        _loadingStatus = 'Finalizing...';
      });
      
      _populateFormFields();

      // Clear cached total since items changed
      _cachedTotal = null;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }void _populateFormFields() {
    if (_orderData != null) {
      // Format dates
      if (_orderData!['Order_Date'] != null) {
        final orderDate = DateTime.parse(_orderData!['Order_Date']);
        _orderDateController.text = DateFormat('dd/MM/yyyy').format(orderDate);
      }

      // Sale Code - derived from customer number like in edit screen
      if (_orderData!['Sell_to_Customer_No'] != null) {
        _saleCodeController.text = 'SC-${_orderData!['Sell_to_Customer_No']}';
      }
    }
  }
  String _getLocationName(String? locationCode) {
    if (locationCode == null || locationCode.isEmpty) return 'N/A';
    final location = _locations.firstWhere(
      (loc) => loc.code == locationCode,
      orElse: () => Location(code: locationCode, name: locationCode),
    );
    return '${location.code} - ${location.name}';
  }

  String _getFormattedShipToAddress() {
    final shipToCode = _orderData?['Ship_to_Code'] as String? ?? '';
    final shipToName = _orderData?['Ship_to_Name'] as String? ?? '';
    final shipToAddress = _orderData?['Ship_to_Address'] as String? ?? '';
    
    if (shipToName.isNotEmpty && shipToAddress.isNotEmpty) {
      return '$shipToName, $shipToAddress';
    } else if (shipToName.isNotEmpty) {
      return shipToName;
    } else if (shipToCode.isNotEmpty) {
      return shipToCode;
    }
    return 'N/A';
  }
  Widget _buildStatusChip(String status) {
    Color chipColor;
    
    switch (status.toLowerCase()) {
      case 'open':
        chipColor = AppColors.statusOpen;
        break;
      case 'released':
        chipColor = AppColors.statusReleased;
        break;
      case 'pending approval':
        chipColor = AppColors.statusPending;
        break;
      case 'pending prepayment':
        chipColor = AppColors.statusPending;
        break;
      case 'completed':
        chipColor = AppColors.statusCompleted;
        break;
      default:
        chipColor = AppColors.statusDefault;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }  Widget _buildOrderForm() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order number header
          Text(
            'Order: ${widget.orderNo}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Order Information
          _buildOrderInformationCard(),
          
          const SizedBox(height: 24),

          // Order Items
          _buildOrderItemsCard(isSmallScreen),
        ],
      ),
    );
  }Widget _buildOrderInformationCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Order status chip
            Center(
              child: _buildStatusChip(_orderData?['Status'] ?? 'Unknown'),
            ),
            const SizedBox(height: 16),
              Table(
              columnWidths: const {
                0: FlexColumnWidth(0.4),
                1: FlexColumnWidth(0.6),
              },
              children: [
                _buildInfoRow('Order Date:', _orderDateController.text),
                _buildInfoRow('Customer:', _orderData?['Sell_to_Customer_Name'] ?? 'Unknown Customer'),
                _buildInfoRow('Ship-to Address:', _getFormattedShipToAddress()),
                _buildInfoRow('Location:', _getLocationName(_orderData?['Location_Code'])),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildOrderItemsCard(bool isSmallScreen) {
    final totalAmount = _calculateOrderTotal();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),                  child: Text(
                    'Total: ${_formatCurrency(totalAmount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_orderItems.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No items in this order',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              // Use Column with manual items instead of ListView for better performance with small lists
              Column(
                children: [
                  for (int index = 0; index < _orderItems.length; index++) ...[
                    _buildOrderItemTile(_orderItems[index], isSmallScreen),
                    if (index < _orderItems.length - 1) const Divider(),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemTile(Map<String, dynamic> item, bool isSmallScreen) {
    final itemNo = item['itemNo'] ?? 'N/A';
    final description = item['itemDescription'] ?? 'N/A';
    final quantity = item['quantity'] ?? 0;
    final unitPrice = item['price'] ?? 0;
    final lineAmount = item['totalAmount'] ?? 0;
    final unitOfMeasure = item['unitOfMeasure'] ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemNo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSmallScreen) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${quantity.toString()} $unitOfMeasure',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),                      Text(
                        _formatCurrency(unitPrice),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(                  child: Text(
                    _formatCurrency(lineAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ],
          ),
          if (isSmallScreen) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Qty: ${quantity.toString()} $unitOfMeasure',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),                Text(
                  '${_formatCurrency(unitPrice)} each',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),                Text(
                  _formatCurrency(lineAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  TableRow _buildInfoRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
  double _calculateOrderTotal() {
    // Use cached value if available
    if (_cachedTotal != null) {
      return _cachedTotal!;
    }
    
    // Calculate and cache the total
    double total = 0;
    for (var item in _orderItems) {
      total += item['totalAmount'] as double;
    }
    _cachedTotal = total;
    return total;
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading order details',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrderDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Edit Order'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to edit? Editing will reopen the order.',
            ),
            const SizedBox(height: 12),
            Text(
              'Order ID: ${widget.orderNo}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Navigate to edit screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditOrderScreen(orderNo: widget.orderNo),
                ),
              ).then((_) {
                // Reload order details when returning from edit screen
                _loadOrderDetails();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'View Order - ${widget.orderNo}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2C5F2D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              _showEditOrderDialog(context);
            },
            tooltip: 'Edit Order',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadOrderDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _loadingStatus,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _buildOrderForm(),
    );
  }
}
