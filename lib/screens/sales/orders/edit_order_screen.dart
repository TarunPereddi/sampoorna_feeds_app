// Updated EditOrderScreen implementation with improved item management
// This approach uses a local items list and only submits changes when saving

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/location.dart';
import '../../../models/item.dart';
import '../../../models/item_unit_of_measure.dart';
import 'order_item_form_widget.dart';
import 'order_items_list_widget.dart';

class EditOrderScreen extends StatefulWidget {
  final String orderNo;
  
  const EditOrderScreen({Key? key, required this.orderNo}) : super(key: key);
  
  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  final ApiService _apiService = ApiService();
  
  // Order data
  Map<String, dynamic>? _orderData;
  List<Map<String, dynamic>> _orderItems = [];
  List<Location> _locations = [];
  
  // Controllers for editable fields
  final TextEditingController _orderDateController = TextEditingController();
  final TextEditingController _deliveryDateController = TextEditingController();
  final TextEditingController _saleCodeController = TextEditingController();
  
  // Error state
  String? _errorMessage;
  String _submissionStatus = '';
  
  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  @override
  void dispose() {
    _orderDateController.dispose();
    _deliveryDateController.dispose();
    _saleCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch order details
      final orderResponse = await _apiService.getSalesOrders(
        searchFilter: "No eq '${widget.orderNo}'",
        limit: 1,
      );
      
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

      debugPrint('Order loaded: $_orderData');
      
      // Fetch order lines
      final orderLines = await _apiService.getSalesOrderLines(widget.orderNo);
      
      // Convert order lines to the format used by OrderItemsListWidget
      _orderItems = orderLines.map((line) {
        final itemNo = line['No'] as String? ?? '';
        final description = line['Description'] as String? ?? 'Unknown Item';
        
        // Get quantity
        final quantity = line['Quantity'] != null 
            ? (line['Quantity'] is double ? line['Quantity'] : (line['Quantity'] as num).toDouble()) 
            : 0.0;
            
        // Get price
        final unitPrice = line['Unit_Price'] != null 
            ? (line['Unit_Price'] is double ? line['Unit_Price'] : (line['Unit_Price'] as num).toDouble()) 
            : 0.0;
            
        // Get total amount
        final lineAmount = line['Line_Amount'] != null 
            ? (line['Line_Amount'] is double ? line['Line_Amount'] : (line['Line_Amount'] as num).toDouble()) 
            : 0.0;
            
        // Get unit of measure
        final unitOfMeasure = line['Unit_of_Measure_Code'] as String? ?? '';
        
        // Store the original line number for reference
        final lineNo = line['Line_No'] as int? ?? 0;
        
        return {
          'itemNo': itemNo,
          'itemDescription': description,
          'quantity': quantity,
          'price': unitPrice,
          'mrp': unitPrice, // Use unit price as MRP if not available
          'unitOfMeasure': unitOfMeasure,
          'totalAmount': lineAmount,
          'lineNo': lineNo, // Store the original line number
        };
      }).toList();
      
      debugPrint('Order items loaded: ${_orderItems.length}');
      
      // Fetch locations
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        final locationCodes = authService.currentUser!.locationCodes;
        if (locationCodes.isNotEmpty) {
          final locationsData = await _apiService.getLocations(locationCodes: locationCodes);
          _locations = locationsData.map((json) => Location.fromJson(json)).toList();
        }
      }
      
      // Initialize the form with order data
      _initializeFormData();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load order details: $e';
      });
      debugPrint('Error loading order details: $e');
    }
  }

  void _initializeFormData() {
    if (_orderData != null) {
      // Format dates for display
      final orderDate = _orderData!['Order_Date'] != null 
          ? DateTime.parse(_orderData!['Order_Date'])
          : null;
          
      final deliveryDate = _orderData!['Requested_Delivery_Date'] != null && 
                          _orderData!['Requested_Delivery_Date'] != '0001-01-01'
          ? DateTime.parse(_orderData!['Requested_Delivery_Date'])
          : null;
      
      if (orderDate != null) {
        _orderDateController.text = DateFormat('dd/MM/yyyy').format(orderDate);
      }
      
      if (deliveryDate != null) {
        _deliveryDateController.text = DateFormat('dd/MM/yyyy').format(deliveryDate);
      } else {
        _deliveryDateController.text = 'Not specified';
      }
      
      // Initialize sale code
      if (_orderData!['Sell_to_Customer_No'] != null) {
        _saleCodeController.text = 'SC-${_orderData!['Sell_to_Customer_No']}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Edit Order',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF2C5F2D),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            // Save button
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _isSubmitting ? null : _saveOrderChanges,
            ),
          ],
        ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isSubmitting
            ? _buildSubmittingView()
            : _errorMessage != null
              ? _buildErrorView()
              : _buildOrderEditForm(),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFFE8F5E9),
          selectedItemColor: const Color(0xFF2C5F2D),
          unselectedItemColor: Colors.grey,
          currentIndex: 1, // Orders tab is active
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index != 1) {
              Navigator.of(context).pop();
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.question_answer),
              label: 'Queries',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubmittingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF008000)),
          const SizedBox(height: 24),
          Text(
            _submissionStatus,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrderDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrderEditForm() {
    if (_orderData == null) {
      return const Center(child: Text('No order data available'));
    }
    
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
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
          
          // Order status chip
          Center(
            child: _buildStatusChip(_orderData!['Status'] ?? 'Unknown'),
          ),
          const SizedBox(height: 24),
          
          // Order Information
          Card(
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
                  
                  // Order information as a simple table
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(0.4),
                      1: FlexColumnWidth(0.6),
                    },
                    children: [
                      _buildInfoRow('Order Date:', _orderDateController.text),
                      _buildInfoRow('Customer:', _orderData!['Sell_to_Customer_Name'] ?? 'Unknown Customer'),
                      _buildInfoRow('Sale Code:', _saleCodeController.text),
                      _buildInfoRow('Delivery Date:', _deliveryDateController.text),
                      _buildInfoRow('Ship-to Address:', _getFormattedShipToAddress()),
                      _buildInfoRow('Location:', _getLocationName(_orderData!['Location_Code'])),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Order Item Form Widget
          OrderItemFormWidget(
            isSmallScreen: isSmallScreen,
            onAddItem: _addItem,
            locationCode: _orderData!['Location_Code'] as String? ?? '',
            customerPriceGroup: _orderData!['Customer_Price_Group'] as String? ?? '',
          ),
          
          const SizedBox(height: 24),
          
          // Order Items List Widget
          OrderItemsListWidget(
            items: _orderItems,
            isSmallScreen: isSmallScreen,
            onRemoveItem: _removeItem,
            onClearAll: _clearAllItems,
            totalAmount: _calculateOrderTotal(),
          ),
          
          const SizedBox(height: 24),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _saveOrderChanges,
              icon: _isSubmitting 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: const Text('SAVE CHANGES'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C5F2D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  void _addItem(Map<String, dynamic> item) {
    setState(() {
      _orderItems.add(item);
    });
    
    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added to order')),
    );
  }
  
  void _removeItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
    });
  }
  
  void _clearAllItems() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Items'),
        content: const Text('Are you sure you want to remove all items from this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _orderItems.clear();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
  
  double _calculateOrderTotal() {
    double total = 0;
    for (var item in _orderItems) {
      total += item['totalAmount'] as double;
    }
    return total;
  }
  
  // Save all changes to the order
  Future<void> _saveOrderChanges() async {
    // If no items, show an error
    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save order without items'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _submissionStatus = 'Preparing to update order...';
    });
    
    try {
      // 1. First, reopen the order if it's not already open
      if (_orderData!['Status'] != 'Open') {
        _updateSubmissionStatus('Reopening order for editing...');
        await _apiService.reopenSalesOrder(widget.orderNo);
      }
      
      // 2. Delete all existing order lines
      _updateSubmissionStatus('Removing existing items...');
      
      // Get all existing line numbers
      List<int> lineNumbers = [];
      for (var item in _orderItems) {
        if (item.containsKey('lineNo') && item['lineNo'] != null && item['lineNo'] > 0) {
          lineNumbers.add(item['lineNo'] as int);
        }
      }
      
      // Delete lines in reverse order to avoid issues
      lineNumbers.sort((a, b) => b.compareTo(a)); // Sort descending
      
      for (var lineNo in lineNumbers) {
        await _apiService.deleteSalesOrderLine(widget.orderNo, lineNo);
      }
      
      // 3. Add all items as new lines
      _updateSubmissionStatus('Adding updated items...');
      
      for (int i = 0; i < _orderItems.length; i++) {
        final item = _orderItems[i];
        _updateSubmissionStatus('Adding item ${i+1} of ${_orderItems.length}: ${item['itemDescription']}...');
        
        // Convert quantity to integer as required by the API
        final int quantity = item['quantity'].round();
        
        await _apiService.addSalesOrderLine(
          documentNo: widget.orderNo,
          itemNo: item['itemNo'],
          locationCode: _orderData!['Location_Code'] as String,
          quantity: quantity,
        );
      }
      
      _updateSubmissionStatus('Order updated successfully!');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Return to orders screen
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _submissionStatus = 'Error: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _updateSubmissionStatus(String status) {
    if (mounted) {
      setState(() {
        _submissionStatus = status;
      });
    }
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
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusChip(String status) {
    Color chipColor;

    switch (status) {
      case 'Completed':
        chipColor = Colors.green;
        break;
      case 'Released':
        chipColor = Colors.blue;
        break;
      case 'Pending Approval':
        chipColor = Colors.orange;
        break;
      case 'Open':
        chipColor = Colors.purple;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  String _getFormattedShipToAddress() {
    final shipToCode = _orderData!['Ship_to_Code'] as String? ?? '';
    final shipToName = _orderData!['Ship_to_Name'] as String? ?? '';
    final shipToAddress = _orderData!['Ship_to_Address'] as String? ?? '';
    
    if (shipToName.isNotEmpty && shipToCode.isNotEmpty) {
      return '$shipToCode - $shipToName${shipToAddress.isNotEmpty ? '\n$shipToAddress' : ''}';
    } else if (shipToName.isNotEmpty) {
      return shipToName;
    } else if (shipToCode.isNotEmpty) {
      return shipToCode;
    } else {
      return 'No ship-to address specified';
    }
  }
  
  String _getLocationName(String? locationCode) {
    if (locationCode == null || locationCode.isEmpty) {
      return 'No location specified';
    }
    
    final location = _locations.firstWhere(
      (loc) => loc.code == locationCode,
      orElse: () => Location(code: locationCode, name: locationCode),
    );
    
    return '${location.code} - ${location.name}';
  }
}