import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import 'order_form_widget.dart';
import 'order_item_form_widget.dart';
import 'order_items_list_widget.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderFormScrollController = ScrollController();
  final ApiService _apiService = ApiService();
  // Form Data Structure
  final Map<String, dynamic> _orderData = {
    'orderDate': DateTime.now(),
    'customer': null,
    'customerNo': null,
    'customerPriceGroup': null,
    'saleCode': '',
    'shipTo': null,
    'shipToCode': '', // Added to store the actual code for API
    'location': null,
    'locationCode': '',
    'items': <Map<String, dynamic>>[],
  };
  // Total order amount
  double _orderTotal = 0;

  // Loading state
  bool _isSubmitting = false;
  String _submissionStatus = ''; // Track submission status for user feedback
  @override
  void initState() {
    super.initState();
    // Initialize order date
    _orderData['orderDate'] = DateTime.now();
  }

  // Helper method to format currency values
  String _formatCurrency(double value) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return currencyFormat.format(value);
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

  // Handle form field updates
  void _handleFormUpdate(String key, dynamic value) {
  setState(() {
    _orderData[key] = value;

    // If location is updated, also update locationCode
    if (key == 'location' && value != null) {
      // Try to extract the location code from the selected location
      try {
        // Find the matching location in _locations list to get its code
        if (value is String && value.contains(' - ')) {
          final locationCode = value.split(' - ').first.trim();
          _orderData['locationCode'] = locationCode;
        }
      } catch (e) {
        _orderData['locationCode'] = '';
        debugPrint('Error extracting location code: $e');
      }

      _orderData['items'] = <Map<String, dynamic>>[];
    }
  });
}


  // Submit the order
  void _submitOrder() {
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
        title: const Text('Confirm Order Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to submit this order for ${_orderData['customer'] ?? "Unknown Customer"}?',
            ),
            const SizedBox(height: 12),
            Text(
              'Total Items: ${_orderData['items'].length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),            Text(
              'Total Amount: ${_formatCurrency(_orderTotal)}',
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
              _processOrderSubmission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  // Process the order submission
  Future<void> _processOrderSubmission() async {
    // Set a flag to track if this widget is still mounted before showing dialogs
    bool isCurrentlyMounted = true;
    
    setState(() {
      _isSubmitting = true;
      _submissionStatus = 'Preparing order submission...';
    });

    try {
      // Get the current authenticated sales person
      final authService = Provider.of<AuthService>(context, listen: false);
      final salesPerson = authService.currentUser;
      
      if (salesPerson == null) {
        throw Exception('User not authenticated');
      }

      // Extract customer number
      String customerNo = _orderData['customerNo'] ?? '';
      if (customerNo.isEmpty) {
        throw Exception('Invalid customer selection');
      }

      // Get the ship-to code
      String shipToCode = _orderData['shipToCode'] ?? '';
      
      // Extract location code
      String locationCode = _orderData['locationCode'] ?? '';      if (locationCode.isEmpty) {
        throw Exception('Invalid location selection');
      }

      // 1. Create the Sales Order Header
      _updateSubmissionStatus('Creating order...');
      
      // Wrap API calls in try-catch blocks to handle individual failures
      Map<String, dynamic> salesOrderResponse;
      try {
        salesOrderResponse = await _apiService.createSalesOrder(
          customerNo: customerNo,
          shipToCode: shipToCode,
          locationCode: locationCode,
          salesPersonCode: salesPerson.code,
        );
      } catch (headerError) {
        print('Error creating sales order header: $headerError');
        throw Exception('Failed to create order: ${_getReadableErrorMessage(headerError)}');
      }
      
      // Extract the order number from the response
      final orderNo = salesOrderResponse['No'];
      if (orderNo == null || orderNo.isEmpty) {
        throw Exception('Order number not received from server');
      }
      
      // Check if widget is still mounted before updating UI
      if (!mounted) {
        isCurrentlyMounted = false;
        return;
      }
      
      _updateSubmissionStatus('Order created: $orderNo');
      
      // 2. Add Sales Order Lines for each item
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
          print('Error adding item ${item['itemNo']}: $itemError');
          failedItems.add('${item['itemDescription']} (${item['itemNo']})');
          _updateSubmissionStatus('Failed to add item ${i+1}: ${item['itemDescription']}');
        }
      }
      
      // Check if widget is still mounted before wrapping up
      if (!mounted) {
        isCurrentlyMounted = false;
        return;
      }
      
      // Order completed - check if any items failed
      setState(() {
        _isSubmitting = false;
        if (failedItems.isEmpty) {
          _submissionStatus = 'Order submitted successfully!';
        } else {
          _submissionStatus = 'Order created with some issues';
        }
      });      // Show appropriate message
      if (isCurrentlyMounted) {
        if (failedItems.isEmpty) {
          // All items added successfully
          // First close the create order screen
          Navigator.of(context).pop();
          
          // Then show the success dialog
          _showOrderSummaryDialog(orderNo);
        } else {
          // For partial success, close screen then show dialog
          Navigator.of(context).pop();
          
          // Show partial success dialog
          _showPartialSuccessDialog(orderNo, failedItems);
        }
      }
    } catch (e) {
      // Check if widget is still mounted before updating UI
      if (!mounted) {
        return;
      }
      
      print('Order submission error: $e');
      
      // Extract error message from API response if available
    String errorMessage = _getReadableErrorMessage(e);
    
    setState(() {
      _isSubmitting = false;
      _submissionStatus = 'Error: $errorMessage';
    });

      // Show error message dialog instead of snackbar for more visibility
      if (isCurrentlyMounted) {
        try {
          _showErrorDialog(_getReadableErrorMessage(e));
        } catch (dialogError) {
          // Last resort error handling
          print('Error showing error dialog: $dialogError');
          // Try to show at least a snackbar
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to place order: ${_getReadableErrorMessage(e)}'),
                backgroundColor: Colors.red,
              ),
            );
          } catch (snackbarError) {
            print('Failed to show snackbar: $snackbarError');
          }
        }
      }
    }
  }

  // Helper method to update the submission status
  void _updateSubmissionStatus(String status) {
    if (mounted) {
      setState(() {
        _submissionStatus = status;
      });
    }
  }
  // Handle API errors with user-friendly messages
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
    } else if (errorMessage.contains('500') || errorMessage.contains('503')) {
      return 'We are experiencing technical difficulties. Please try again in a few moments.';
    }

    // If no specific pattern is found, return a more user-friendly version of the error
    return errorMessage.replaceAll('Exception: ', '');
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create New Order',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2C5F2D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Help button
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: _isSubmitting
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
                    // Title
                    const Text(
                      'Create Customer Order',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Order Information Form
                    OrderFormWidget(
                      orderData: _orderData,
                      isSmallScreen: isSmallScreen,
                      onUpdate: _handleFormUpdate,
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
                        onPressed: _submitOrder,
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text(
                          'Submit Order',
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

  // Show help dialog
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Form Help'),
        content: const SingleChildScrollView(
          child: ListBody(
            children: [
              Text('• Fill in all required fields (marked with *).'),
              Text('• Add items to the order using the Add Items section.'),
              Text('• You can search for customers, items, and locations.'),
              Text('• Remove items by clicking the delete icon.'),
              Text('• Review all details before submitting the order.'),
              SizedBox(height: 12),
              Text('For API integration support, contact the development team.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Got it'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }  // Show order summary dialog
  void _showOrderSummaryDialog(String orderNo) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        // Get screen size for responsive design
        final screenSize = MediaQuery.of(context).size;
        final dialogWidth = screenSize.width < 600 
            ? screenSize.width * 0.9  // 90% of screen width on small screens
            : 550.0;                  // Fixed width on larger screens
            
        return Dialog(
          // Set maximum width to prevent overflow
          insetPadding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.05, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: screenSize.height * 0.8, // Limit height to 80% of screen height
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title bar with fixed height
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C5F2D),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Order Placed Successfully',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content area with scrolling
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Number: $orderNo', 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        // Customer and Location with text overflow handling
                        Text(
                          'Customer: ${_orderData['customer']}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        Text(
                          'Location: ${_orderData['location']}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        
                        const Divider(height: 24),
                        
                        const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        
                        // List all items with proper overflow handling
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
                                    Text(
                                      '${item['itemDescription']} (${item['itemNo']})',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),                                    Text(
                                      '${item['quantity']} ${item['unitOfMeasure']} x ${_formatCurrency(item['price'] as double)} = ${_formatCurrency(item['totalAmount'] as double)}',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
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
                            const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),                            Text(
                              _formatCurrency(_orderTotal),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Action buttons
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      // Close dialog
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008000),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }  // Show partial success dialog when some items failed to be added
  void _showPartialSuccessDialog(String orderNo, List<String> failedItems) {
    // Use try-catch to handle any widget tree issues
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 28),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Order Created With Issues',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Number: $orderNo', 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    const Text(
                      'The order was created, but some items could not be added:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    
                    // List failed items
                    ...failedItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Colors.red)),
                          Expanded(
                            child: Text(
                              item, 
                              style: const TextStyle(color: Colors.red),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                    
                    const SizedBox(height: 16),
                    const Text(
                      'Please note the order number and contact support if needed.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('Close'),
                  onPressed: () {
                    // Close dialog
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
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
            content: Text('Order created with some issues. Order #: $orderNo'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      } catch (snackbarError) {
        print('Failed to show snackbar: $snackbarError');
      }
    }
  }  // Show error dialog when order creation fails
  void _showErrorDialog(String errorMessage) {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 28),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Order Submission Failed',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'We couldn\'t create your order due to the following error:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red.shade800),
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'What to do next:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Check your internet connection'),
                    const Text('• Verify all order details are correct'),
                    const Text('• Try again in a few moments'),
                    const Text('• Contact support if the issue persists'),
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      child: const Text('Try Again'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      child: const Text('Go Back'),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
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
            content: Text('Failed to place order: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      } catch (snackbarError) {
        print('Failed to show snackbar: $snackbarError');
      }
    }
  }

  @override
  void dispose() {
    _orderFormScrollController.dispose();
    super.dispose();
  }
}