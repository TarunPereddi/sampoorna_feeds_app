import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/location.dart';
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
    'deliveryDate': null,
    'customer': null,
    'saleCode': '',
    'shipTo': null,
    'location': null,
    'locationCode': '',
    'items': <Map<String, dynamic>>[],
  };

  // Total order amount
  double _orderTotal = 0;

  // Loading state
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize order date
    _orderData['orderDate'] = DateTime.now();
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
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get the current authenticated sales person
      final authService = Provider.of<AuthService>(context, listen: false);
      final salesPerson = authService.currentUser;
      
      if (salesPerson == null) {
        throw Exception('User not authenticated');
      }

      // Extract customer number from the selected customer
      String? customerNo;
      if (_orderData['customer'] != null && _orderData['customer'].contains(' - ')) {
        customerNo = _orderData['customer'].split(' - ').first.trim();
      }
      
      if (customerNo == null) {
        throw Exception('Invalid customer selection');
      }

      // Prepare order data for API
      final Map<String, dynamic> orderPayload = {
        'Document_Type': 'Order',
        'Sell_to_Customer_No': customerNo,
        'Order_Date': DateFormat('yyyy-MM-dd').format(_orderData['orderDate']),
        'Posting_Date': DateFormat('yyyy-MM-dd').format(_orderData['orderDate']),
        'Document_Date': DateFormat('yyyy-MM-dd').format(_orderData['orderDate']),
        'Requested_Delivery_Date': _orderData['deliveryDate'] != null 
            ? DateFormat('yyyy-MM-dd').format(_orderData['deliveryDate'])
            : DateFormat('yyyy-MM-dd').format(_orderData['orderDate']),
        'Salesperson_Code': salesPerson.code,
        'Location_Code': _orderData['locationCode'],
        'Status': 'Open',
        'lines': _orderData['items'].map((item) => {
          'Type': 'Item',
          'No': item['itemNo'],
          'Description': item['itemDescription'],
          'Quantity': item['quantity'],
          'Unit_of_Measure': item['unitOfMeasure'],
          'Unit_Price': item['price'],
        }).toList(),
      };

      // In a real app, you would call the API service
      debugPrint('Order Payload: $orderPayload');
      
      // Simulate API call for now
      await Future.delayed(const Duration(seconds: 2));
      
      // await _apiService.createSalesOrder(orderPayload);

      setState(() {
        _isSubmitting = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order submitted successfully!'),
            backgroundColor: Color(0xFF008000),
          ),
        );

        // Navigate back after short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF008000)),
            SizedBox(height: 16),
            Text('Processing your order...'),
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
  }

  @override
  void dispose() {
    _orderFormScrollController.dispose();
    super.dispose();
  }
}