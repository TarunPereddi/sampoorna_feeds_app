// lib/screens/sales/orders/edit_order_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/location.dart';
import '../../../models/customer.dart';
import '../../../models/ship_to.dart';
import 'order_form_widget.dart';
import 'order_item_form_widget.dart';
import 'order_items_list_widget.dart';

class EditOrderScreen extends StatefulWidget {
  final String orderNo;
  final Map<String, dynamic> initialOrderData;

  const EditOrderScreen({
    super.key,
    required this.orderNo,
    this.initialOrderData = const {},
  });

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderFormScrollController = ScrollController();
  final ApiService _apiService = ApiService();

  // Form Data Structure
  late Map<String, dynamic> _orderData;

  // Original order lines for comparison
  List<dynamic> _originalOrderLines = [];

  // Total order amount
  double _orderTotal = 0;

  // Loading state
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _submissionStatus = ''; // Track submission status for user feedback

  @override
  void initState() {
    super.initState();
    
    // Initialize order data with defaults and then populate from API
    _orderData = {
      'orderDate': DateTime.now(),
      'deliveryDate': null,
      'customer': null,
      'customerNo': null,
      'customerPriceGroup': null,
      'saleCode': '',
      'shipTo': null,
      'shipToCode': '',
      'location': null,
      'locationCode': '',
      'items': <Map<String, dynamic>>[],
    };
    
    // Load the order details
    _loadOrderDetails();
  }

  // Load order details from API
  Future<void> _loadOrderDetails() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // 1. Fetch the complete order details
    final orderResponse = await _apiService.getSalesOrders(
      searchFilter: "No eq '${widget.orderNo}'",
      limit: 1,
    );

    if (orderResponse['value'] == null || (orderResponse['value'] as List).isEmpty) {
      throw Exception('Order not found');
    }

    final orderData = (orderResponse['value'] as List)[0];
    
    // Extract basic info
    final String orderNo = orderData['No'] ?? '';
    final String customerNo = orderData['Sell_to_Customer_No'] ?? '';
    final String customerName = orderData['Sell_to_Customer_Name'] ?? '';
    final String locationCode = orderData['Location_Code'] ?? '';
    final String shipToCode = orderData['Ship_to_Code'] ?? '';
    final String customerPriceGroup = orderData['Customer_Price_Group'] ?? '';
    
    // 2. Parse dates
    DateTime? orderDate;
    if (orderData['Order_Date'] != null) {
      orderDate = DateTime.parse(orderData['Order_Date']);
    }
    
    DateTime? deliveryDate;
    if (orderData['Requested_Delivery_Date'] != null) {
      try {
        deliveryDate = DateTime.parse(orderData['Requested_Delivery_Date']);
      } catch (e) {
        print('Error parsing delivery date: $e');
      }
    }
    
    // 3. Get order lines
    final orderLines = await _apiService.getSalesOrderLines(orderNo);
    _originalOrderLines = List.from(orderLines);
    
    // 4. Convert order lines to our item format
    List<Map<String, dynamic>> items = [];
    for (var line in orderLines) {
      // Skip non-item lines if any
      if (line['Type'] != 'Item') continue;
      
      double quantity = 0;
      if (line['Quantity'] != null) {
        quantity = line['Quantity'] is int
            ? (line['Quantity'] as int).toDouble()
            : line['Quantity'] as double;
      }
      
      double unitPrice = 0;
      if (line['Unit_Price'] != null) {
        unitPrice = line['Unit_Price'] is int
            ? (line['Unit_Price'] as int).toDouble()
            : line['Unit_Price'] as double;
      }
      
      double lineAmount = 0;
      if (line['Line_Amount'] != null) {
        lineAmount = line['Line_Amount'] is int
            ? (line['Line_Amount'] as int).toDouble()
            : line['Line_Amount'] as double;
      }
      
      // Add item to our list
      items.add({
        'lineNo': line['Line_No'],
        'itemNo': line['No'],
        'itemDescription': line['Description'],
        'unitOfMeasure': line['Unit_of_Measure'],
        'quantity': quantity,
        'mrp': unitPrice, // Default to unit price if MRP not available
        'price': unitPrice,
        'totalAmount': lineAmount,
      });
    }
    
    // 5. Get location info
    String locationName = locationCode;
    try {
      final locationsData = await _apiService.getLocations(locationCodes: [locationCode]);
      if (locationsData.isNotEmpty) {
        locationName = "${locationCode} - ${locationsData[0]['Name']}";
      }
    } catch (e) {
      debugPrint('Error fetching location info: $e');
    }
    
    // 6. Get ship-to info
    String shipToName = shipToCode;
    if (shipToCode.isNotEmpty) {
      try {
        final shipToData = await _apiService.getShipToAddresses(customerNo: customerNo);
        for (var address in shipToData) {
          if (address['Code'] == shipToCode) {
            shipToName = address['Name'] ?? shipToCode;
            break;
          }
        }
      } catch (e) {
        debugPrint('Error fetching ship-to info: $e');
      }
    }
    
    // 7. Update order data with all fetched info
    setState(() {
      _orderData = {
        'orderNo': orderNo,
        'orderDate': orderDate ?? DateTime.now(),
        'deliveryDate': deliveryDate,
        'customer': "$customerNo - $customerName",
        'customerNo': customerNo,
        'customerPriceGroup': customerPriceGroup,
        'saleCode': 'SC-$customerNo', // Generate a sale code
        'shipTo': shipToName,
        'shipToCode': shipToCode,
        'location': locationName,
        'locationCode': locationCode,
        'items': items,
      };
      
      // Calculate total
      _updateOrderTotal();
      
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading order details: $e')),
    );
    
    // Go back to previous screen
    Navigator.of(context).pop();
  }
}
  Future<void> _processOrderUpdate() async {
  bool isCurrentlyMounted = true;
  
  setState(() {
    _isSubmitting = true;
    _submissionStatus = 'Preparing order update...';
  });

  try {
    // Get the current authenticated sales person
    final authService = Provider.of<AuthService>(context, listen: false);
    final salesPerson = authService.currentUser;
    
    if (salesPerson == null) {
      throw Exception('User not authenticated');
    }

    final String orderNo = _orderData['orderNo'];
    final String locationCode = _orderData['locationCode'];

    // 1. Reopen the order if needed
    _updateSubmissionStatus('Reopening order for editing...');
    
    try {
      await _apiService.reopenSalesOrder(orderNo);
      _updateSubmissionStatus('Order reopened successfully');
    } catch (e) {
      // If reopening fails, it may already be open, so continue
      debugPrint('Could not reopen order, it may already be open: $e');
    }

    // 2. Delete existing order lines
    _updateSubmissionStatus('Removing existing items...');
    
    for (var originalLine in _originalOrderLines) {
      if (originalLine['Type'] != 'Item') continue; // Skip non-item lines
      
      final int lineNo = originalLine['Line_No'];
      
      try {
        await _apiService.deleteSalesOrderLine(orderNo, lineNo);
        _updateSubmissionStatus('Removed item: ${originalLine['Description']}');
      } catch (e) {
        // Log error but continue with next item
        debugPrint('Error removing item line $lineNo: $e');
      }
    }
    
    // 3. Add updated order lines
    _updateSubmissionStatus('Adding updated items...');
    
    List<String> failedItems = [];
    
    for (int i = 0; i < _orderData['items'].length; i++) {
      if (!mounted) {
        isCurrentlyMounted = false;
        return;
      }
      
      final item = _orderData['items'][i];
      _updateSubmissionStatus('Adding item ${i+1} of ${_orderData['items'].length}: ${item['itemDescription']}...');
      
      // Convert quantity to integer as required by the API
      final int quantity = item['quantity'].round();
      
      try {
        await _apiService.addSalesOrderLine(
          documentNo: orderNo,
          itemNo: item['itemNo'],
          locationCode: locationCode,
          quantity: quantity,
        );
        
        _updateSubmissionStatus('Added item ${i+1}: ${item['itemDescription']}');
      } catch (itemError) {
        // Log error but continue with next item
        debugPrint('Error adding item ${item['itemNo']}: $itemError');
        failedItems.add('${item['itemDescription']} (${item['itemNo']})');
        _updateSubmissionStatus('Failed to add item ${i+1}: ${item['itemDescription']}');
      }
    }
    
    // 4. Update delivery date if needed
    if (_orderData['deliveryDate'] != null) {
      _updateSubmissionStatus('Updating delivery date...');
      
      try {
        // You'll need to implement an API method to update the delivery date
        // For now, we'll assume it's handled automatically
      } catch (e) {
        debugPrint('Error updating delivery date: $e');
      }
    }
    
    // Check if widget is still mounted before wrapping up
    if (!mounted) {
      isCurrentlyMounted = false;
      return;
    }
    
    // Order update completed - check if any items failed
    setState(() {
      _isSubmitting = false;
      if (failedItems.isEmpty) {
        _submissionStatus = 'Order updated successfully!';
      } else {
        _submissionStatus = 'Order updated with some issues';
      }
    });

    // Show appropriate message
    if (isCurrentlyMounted) {
      if (failedItems.isEmpty) {
        // All items updated successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order updated successfully!'),
            backgroundColor: Color(0xFF008000),
          ),
        );
        
        // Show order summary dialog
        _showOrderSummaryDialog(orderNo);
      } else {
        // Some items failed, show partial success dialog
        _showPartialSuccessDialog(orderNo, failedItems);
      }
    }
  } catch (e) {
    // Check if widget is still mounted before updating UI
    if (!mounted) {
      return;
    }
    
    debugPrint('Order update error: $e');
    
    setState(() {
      _isSubmitting = false;
      _submissionStatus = 'Error: ${_getReadableErrorMessage(e)}';
    });

    // Show error message dialog
    if (isCurrentlyMounted) {
      _showErrorDialog(_getReadableErrorMessage(e));
    }
  }
}
String _getReadableErrorMessage(dynamic error) {
  String errorMessage = error.toString();

  // Check for API error response in JSON format
  if (errorMessage.contains("error") && errorMessage.contains("message")) {
    try {
      // Extract just the message part from the error response
      final RegExp messageRegex = RegExp(r'"message"\s*:\s*"([^"]+)"');
      final match = messageRegex.firstMatch(errorMessage);
      
      if (match != null && match.groupCount >= 1) {
        String apiMessage = match.group(1) ?? errorMessage;
        
        // Remove the CorrelationId portion if present
        if (apiMessage.contains("CorrelationId")) {
          apiMessage = apiMessage.split("CorrelationId")[0].trim();
          // Remove trailing punctuation if any
          if (apiMessage.endsWith(".") || apiMessage.endsWith(",") || apiMessage.endsWith(" ")) {
            apiMessage = apiMessage.substring(0, apiMessage.length - 1).trim();
          }
        }
        
        return apiMessage;
      }
    } catch (e) {
      // If parsing fails, continue with general handling
      print('Error parsing API error message: $e');
    }
  }

  // Check for specific error patterns and provide friendly messages
  if (errorMessage.contains('Failed to connect')) {
    return 'Could not connect to the server. Please check your internet connection.';
  } else if (errorMessage.contains('timed out')) {
    return 'Request timed out. Please try again.';
  } else if (errorMessage.contains('400')) {
    return 'Invalid request. Please check your order details.';
  } else if (errorMessage.contains('401') || errorMessage.contains('403')) {
    return 'Authentication error. Please log in again.';
  } else if (errorMessage.contains('500')) {
    return 'Server error. Please try again later.';
  }

  // If no specific pattern is found, return a more user-friendly version of the error
  return errorMessage.replaceAll('Exception: ', '');
}

// Show error dialog when order update fails - copy from CreateOrderScreen
void _showErrorDialog(String errorMessage) {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Order Update Failed'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We couldn\'t update your order due to the following error:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'What to do next:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text('• Check your internet connection'),
                Text('• Verify all order details are correct'),
                Text('• Try again in a few moments'),
                Text('• Contact support if the issue persists'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Go Back'),
              onPressed: () {
                // First close the dialog, then go back to previous screen
                Navigator.of(context).pop(); // Close dialog
                // Use popUntil to go back to the correct screen
                Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/sales');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  } catch (e) {
    // If dialog fails, use a snackbar as fallback
    print('Error showing error dialog: $e');
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order: $errorMessage'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (snackbarError) {
      print('Failed to show snackbar: $snackbarError');
    }
  }
}

// Show success dialog
void _showOrderSummaryDialog(String orderNo) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            const Text('Order Updated Successfully'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Number: $orderNo', 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              Text('Customer: ${_orderData['customer']}'),
              Text('Location: ${_orderData['location']}'),
              
              const Divider(height: 24),
              
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // List all items
              ..._orderData['items'].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item['itemDescription']} (${item['itemNo']})'),
                          Text(
                            '${item['quantity']} ${item['unitOfMeasure']} x ₹${item['price'].toStringAsFixed(2)} = ₹${item['totalAmount'].toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
              
              const Divider(height: 24),
              
              // Total amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '₹${_orderTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/sales');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008000),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    },
  );
}

// Show partial success dialog
void _showPartialSuccessDialog(String orderNo, List<String> failedItems) {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('Order Updated With Issues'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Number: $orderNo', 
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                
                Text(
                  'The order was updated, but some items could not be added:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                
                // List failed items
                ...failedItems.map((item) => Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: Colors.red)),
                      Expanded(child: Text(item, style: TextStyle(color: Colors.red))),
                    ],
                  ),
                )).toList(),
                
                SizedBox(height: 16),
                Text(
                  'Please note the order number and contact support if needed.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/sales');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  } catch (e) {
    // If dialog fails, try a simple snackbar as fallback
    print('Error showing partial success dialog: $e');
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order updated with some issues. Order #: $orderNo'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (snackbarError) {
      print('Failed to show snackbar: $snackbarError');
    }
  }
}

  void _updateSubmissionStatus(String status) {
  if (mounted) {
    setState(() {
      _submissionStatus = status;
    });
  }
}

  // Calculate total order amount
  void _updateOrderTotal() {
    double total = 0;
    for (var item in _orderData['items']) {
      total += item['totalAmount'] as double;
    }
    setState(() {
      _orderTotal = total;
    });
  }

  // Add an item to the order
  void addItemToOrder(Map<String, dynamic> item) {
    setState(() {
      _orderData['items'].add(item);
      _updateOrderTotal();
    });

    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added to order')),
    );

    // Scroll to the items list
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_orderFormScrollController.hasClients) {
        _orderFormScrollController.animateTo(
          _orderFormScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Remove an item from the order
  void removeItemFromOrder(int index) {
    setState(() {
      _orderData['items'].removeAt(index);
      _updateOrderTotal();
    });
  }

  // Clear all items from the order
  void clearAllItems() {
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
                _orderData['items'].clear();
                _updateOrderTotal();
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

  // Handle form field updates - only for fields that can be edited (delivery date)
  void _handleFormUpdate(String key, dynamic value) {
    setState(() {
      if (key == 'deliveryDate') {
        _orderData[key] = value;
      }
      // Ignore updates to other fields that should be read-only
    });
  }

  // Submit the order updates
  void _submitOrderUpdates() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_orderData['items'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to the order')),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to update this order?',
            ),
            const SizedBox(height: 12),
            Text(
              'Total Items: ${_orderData['items'].length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Total Amount: ₹${_orderTotal.toStringAsFixed(2)}',
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
              _processOrderUpdate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;

    return Scaffold(
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isSubmitting
              ? Center(
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
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    controller: _orderFormScrollController,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order ID display
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Editing Order: ${widget.orderNo}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Order Information Form - readonly except for delivery date
                        // We'll need to modify OrderFormWidget to support read-only mode
                        // or create a simplified read-only version for editing
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
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
                                
                                // Display read-only order info
                                _buildReadOnlyInfo(
                                  'Customer',
                                  _orderData['customer'] ?? 'Not specified',
                                ),
                                
                                const SizedBox(height: 12),
                                
                                _buildReadOnlyInfo(
                                  'Order Date',
                                  _orderData['orderDate'] != null
                                      ? DateFormat('dd/MM/yyyy').format(_orderData['orderDate'])
                                      : 'Not specified',
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Editable delivery date
                                _buildDateField(
                                  label: 'Delivery Date',
                                  initialDate: _orderData['deliveryDate'],
                                  onSelect: (date) {
                                    _handleFormUpdate('deliveryDate', date);
                                  },
                                ),
                                
                                const SizedBox(height: 12),
                                
                                _buildReadOnlyInfo(
                                  'Location',
                                  _orderData['location'] ?? 'Not specified',
                                ),
                                
                                const SizedBox(height: 12),
                                
                                _buildReadOnlyInfo(
                                  'Ship To',
                                  _orderData['shipTo'] ?? 'Not specified',
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Item Entry Form
                        OrderItemFormWidget(
                          isSmallScreen: isSmallScreen,
                          onAddItem: addItemToOrder,
                          locationCode: _orderData['locationCode'],
                          customerPriceGroup: _orderData['customerPriceGroup'],
                        ),

                        const SizedBox(height: 24),

                        // Order Items List
                        OrderItemsListWidget(
                          items: _orderData['items'],
                          isSmallScreen: isSmallScreen,
                          onRemoveItem: removeItemFromOrder,
                          onClearAll: clearAllItems,
                          totalAmount: _orderTotal,
                        ),

                        const SizedBox(height: 24),

                        // Submit Button
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _submitOrderUpdates,
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text(
                              'Update Order',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C5F2D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Helper method to build read-only info display
  Widget _buildReadOnlyInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(value),
        ),
      ],
    );
  }

  // Helper method to build a date field
  Widget _buildDateField({
    required String label,
    DateTime? initialDate,
    required Function(DateTime) onSelect,
  }) {
    final TextEditingController controller = TextEditingController(
      text: initialDate != null ? DateFormat('dd/MM/yyyy').format(initialDate) : '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label*',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: const Icon(Icons.calendar_today, size: 20),
          ),
          validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
          onTap: () async {
            final DateTime now = DateTime.now();
            
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: initialDate ?? now,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );

            if (pickedDate != null) {
              // Ensure delivery date is not before order date
              if (_orderData['orderDate'] != null) {
                final orderDate = _orderData['orderDate'] as DateTime;
                if (pickedDate.isBefore(orderDate)) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delivery date cannot be before order date'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }
              }
              
              setState(() {
                controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                onSelect(pickedDate);
              });
            }
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _orderFormScrollController.dispose();
    super.dispose();
  }

  
}