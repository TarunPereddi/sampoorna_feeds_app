// Updated EditOrderScreen implementation with improved item management
// This approach uses a local items list and only submits changes when saving

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/customer.dart';
import '../../../models/sales_person.dart';
import '../../../models/location.dart';
import '../../../models/ship_to.dart';
import '../../../utils/app_colors.dart';
// import '../../../models/item.dart';
// import '../../../models/item_unit_of_measure.dart';
import 'order_item_form_widget.dart';
import 'order_items_list_widget.dart';
import 'ship_to_selection_screen.dart';

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
  List<ShipTo> _shipToAddresses = [];

  List<Map<String, dynamic>> _originalItems = [];
  List<int> _itemsToDelete = [];
  List<Map<String, dynamic>> _itemsToAdd = [];
  List<Map<String, dynamic>> _itemsToUpdate = [];
    // Controllers for editable fields
  final TextEditingController _orderDateController = TextEditingController();

  final TextEditingController _saleCodeController = TextEditingController();
  final TextEditingController _shipToCodeController = TextEditingController();
  
  // Track changes for ship-to address
  String? _originalShipToCode;
  String? _originalShipToName;
  bool _shipToCodeChanged = false;
  
  // Error state
  String? _errorMessage;
  String _submissionStatus = '';
  
  // Edit mode state
  bool _isEditingItem = false;
  int? _editingItemIndex;
  Map<String, dynamic>? _editingItemData;
  
  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }
  @override
  void dispose() {
    _orderDateController.dispose();
    _saleCodeController.dispose();
    _shipToCodeController.dispose();
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

      // Check for Customer_Price_Group
      if (_orderData!['Customer_Price_Group'] == null ||
          (_orderData!['Customer_Price_Group'] as String).isEmpty) {

        // If not found in order data, get it from the customer details
        final customerNo = _orderData!['Sell_to_Customer_No'] as String?;
        if (customerNo != null && customerNo.isNotEmpty) {
          try {
            final customerDetails = await _apiService.getCustomerDetails(customerNo);

            // Extract the Customer_Price_Group
            if (customerDetails.containsKey('Customer_Price_Group') &&
                customerDetails['Customer_Price_Group'] != null) {

              _orderData!['Customer_Price_Group'] = customerDetails['Customer_Price_Group'];
              debugPrint('Customer_Price_Group from customer: ${_orderData!['Customer_Price_Group']}');
            }
          } catch (e) {
            debugPrint('Error fetching customer details: $e');
          }
        }
      } else {
        debugPrint('Customer_Price_Group from order: ${_orderData!['Customer_Price_Group']}');
      }      // Keep a copy of existing items to check for undeletable status
      // final List<Map<String, dynamic>> previousItems = List.from(_orderItems);

      // Fetch order lines
      final orderLines = await _apiService.getSalesOrderLines(widget.orderNo);
      // Convert order lines to the format used by OrderItemsListWidget
      _originalItems = orderLines.map((line) {
        final itemNo = line['No'] as String? ?? '';
        final description = line['Description'] as String? ?? '';

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
        
        // Check if this item was previously marked as cannot delete
        bool wasUndeletable = false;
        String? errorReason;
        if (_orderItems.isNotEmpty) {
          for (var existingItem in _orderItems) {
            if (existingItem['lineNo'] == lineNo && existingItem['cannotDelete'] == true) {
              wasUndeletable = true;
              // Extract the error reason from description if it exists
              final RegExp regex = RegExp(r'\((.*?)\)$');
              final match = regex.firstMatch(existingItem['itemDescription'].toString());
              if (match != null && match.group(1) != null) {
                errorReason = match.group(1);
              }
              break;
            }
          }
        }
        
        // Debug info for line numbers
        debugPrint('Order line: $lineNo - $itemNo - $description${wasUndeletable ? " (Undeletable)" : ""}');

        return {
          'itemNo': itemNo,
          'itemDescription': wasUndeletable && errorReason != null 
              ? '$description ($errorReason)'
              : description,
          'quantity': quantity,
          'price': unitPrice,
          'mrp': unitPrice,
          'unitOfMeasure': unitOfMeasure,
          'totalAmount': lineAmount,
          'lineNo': lineNo,
          'cannotDelete': wasUndeletable,
        };
      }).toList();
      
      // Initialize _orderItems with a copy of original items
      _orderItems = List.from(_originalItems);

      // Clear tracking collections since we're reloading
      _itemsToDelete = [];
      _itemsToAdd = [];
      _itemsToUpdate = [];

      debugPrint('Order items loaded: ${_orderItems.length}');
      // Log all line numbers for verification
      for (var item in _orderItems) {
        if (item.containsKey('lineNo') && item['lineNo'] != null && item['lineNo'] > 0) {
          debugPrint('Tracking order line: ${item['lineNo']} - ${item['itemDescription']}');
        }
      }

      // Fetch locations
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        List<String> locationCodes = [];
        
        // Handle both Customer and SalesPerson types
        if (currentUser is Customer) {
          locationCodes = currentUser.locationCodes;
        } else if (currentUser is SalesPerson) {
          locationCodes = currentUser.locationCodes;
        }
        
        if (locationCodes.isNotEmpty) {
          debugPrint('Loading locations with codes: $locationCodes');
          final locationsData = await _apiService.getLocations(locationCodes: locationCodes);
          _locations = locationsData.map((json) => Location.fromJson(json)).toList();
          debugPrint('Locations loaded successfully: ${_locations.length} locations');
        } else {
          debugPrint('No location codes available for current user');
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
      
      if (orderDate != null) {
        _orderDateController.text = DateFormat('dd/MM/yyyy').format(orderDate);
      }
      
      // Initialize sale code
      if (_orderData!['Sell_to_Customer_No'] != null) {
        _saleCodeController.text = 'SC-${_orderData!['Sell_to_Customer_No']}';
      }
        // Initialize ship-to code and track original value
      final shipToCode = _orderData!['Ship_to_Code'] as String? ?? '';
      final shipToName = _orderData!['Ship_to_Name'] as String? ?? '';
      _shipToCodeController.text = shipToCode;
      _originalShipToCode = shipToCode;
      _originalShipToName = shipToName;
      _shipToCodeChanged = false;
      
      // Add listener to track changes
      _shipToCodeController.addListener(_onShipToCodeChanged);
      
      // Fetch ship-to addresses for the customer
      final customerNo = _orderData!['Sell_to_Customer_No'] as String?;
      if (customerNo != null && customerNo.isNotEmpty) {
        _fetchShipToAddresses(customerNo);
      }
    }
  }
    void _onShipToCodeChanged() {
    final currentValue = _shipToCodeController.text.trim();
    setState(() {
      _shipToCodeChanged = currentValue != (_originalShipToCode ?? '');
    });
  }

  Future<void> _fetchShipToAddresses(String customerNo) async {
    try {
      final shipToData = await _apiService.getShipToAddresses(customerNo: customerNo);
      setState(() {
        _shipToAddresses = shipToData.map((json) => ShipTo.fromJson(json)).toList();
      });
    } catch (e) {
      debugPrint('Error loading ship-to addresses: $e');
      // Don't show error to user as this is not critical for editing
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
          ),          actions: [
            // Help or other actions can go here if needed
          ],
        ),        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isSubmitting
            ? _buildSubmittingView()
            : _errorMessage != null
              ? _buildErrorView()
              : _buildOrderEditForm(),
        bottomNavigationBar: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button (smaller version)
                  SizedBox(
                    width: 100,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('BACK', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Save button (larger and more prominent)
                  Expanded(
                    flex: 2,
                    child: Tooltip(
                      message: _isEditingItem 
                          ? 'Please complete or cancel the item edit to save the order'
                          : _isSubmitting 
                              ? 'Saving order...'
                              : 'Save order changes',
                      child: ElevatedButton.icon(
                        onPressed: (_isSubmitting || _isEditingItem) ? null : _saveOrderChanges,
                      icon: _isSubmitting 
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save, size: 18),
                        label: const Text('SAVE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF008000),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
          
          // Editing mode indicator
          if (_isEditingItem)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Item editing in progress. Please complete or cancel the edit before saving the order.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16), // Reduced spacing
            // Order Information
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Information',
                    style: TextStyle(
                      fontSize: 16, // Reduced font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced spacing                  // Order information as a simple table
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(0.4),
                      1: FlexColumnWidth(0.6),
                    },
                    children: [
                      _buildInfoRow('Order Date:', _orderDateController.text),
                      _buildInfoRow('Customer:', _orderData!['Sell_to_Customer_Name'] ?? 'Unknown Customer'),
                      _buildEditableShipToRow(),
                      _buildInfoRow('Location:', _getLocationName(_orderData!['Location_Code'])),
                    ],
                  ),
                ],
              ),
            ),          ),
          const SizedBox(height: 16), // Reduced spacing

          // Order Item Form Widget
          OrderItemFormWidget(
            isSmallScreen: isSmallScreen,
            onAddItem: _addItem,
            onCancelEdit: _cancelEdit,
            locationCode: _orderData!['Location_Code'] as String? ?? '',
            customerPriceGroup: _orderData!['Customer_Price_Group'] as String? ?? '',
            isEditMode: _isEditingItem,
            editingItemData: _editingItemData,
          ),
          const SizedBox(height: 16), // Reduced spacing
          
          // Order Items List Widget
          OrderItemsListWidget(
            items: _orderItems,
            isSmallScreen: isSmallScreen,
            onRemoveItem: _removeItem,
            onClearAll: _clearAllItems,
            totalAmount: _calculateOrderTotal(),
            onEditItem: _editItem, // Pass the edit callback
          ),
          
          const SizedBox(height: 16), // Reduced spacing
        ],
      ),
    );
  }

  void _addItem(Map<String, dynamic> item) {
    // Check if we're in edit mode
    if (_isEditingItem) {
      _updateItem(item);
      return;
    }
    
    // Only add to the _itemsToAdd list if it's truly a new item (no lineNo)
    if (!item.containsKey('lineNo') || item['lineNo'] == null || item['lineNo'] <= 0) {
      _itemsToAdd.add(item);
    }

    setState(() {
      _orderItems.add(item);
    });

    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added to order')),
    );
  }  void _removeItem(int index) {
    final item = _orderItems[index];

    // Check if this item is marked as cannot delete
    if (item['cannotDelete'] == true) {
      // Show a message explaining why the item cannot be deleted
      String errorReason = "This item cannot be deleted";
      if (item['itemDescription'] != null) {
        final RegExp regex = RegExp(r'\((.*?)\)$');
        final match = regex.firstMatch(item['itemDescription']);
        if (match != null && match.group(1) != null) {
          errorReason = "This item cannot be deleted: ${match.group(1)}";
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorReason),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return; // Don't proceed with deletion
    }

    // If the item has a line number (existing item), add to delete list
    if (item.containsKey('lineNo') && item['lineNo'] != null && item['lineNo'] > 0) {
      final lineNo = item['lineNo'] as int;
      if (!_itemsToDelete.contains(lineNo)) {
        _itemsToDelete.add(lineNo);
        debugPrint('Added line $lineNo to delete list');
      }
    }

    setState(() {
      _orderItems.removeAt(index);
    });
  }

  void _clearAllItems() {
    setState(() {
      // Clear all items from the order
      _orderItems.clear();
      
      // Clear all tracking lists
      _itemsToAdd.clear();
      _itemsToUpdate.clear();
      _itemsToDelete.clear();
      
      // Reset editing state
      _isEditingItem = false;
    });
    
    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All items cleared from order'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _editItem(int index) {
    final item = _orderItems[index];
    
    setState(() {
      _isEditingItem = true;
      _editingItemIndex = index;
      _editingItemData = Map<String, dynamic>.from(item);
    });
    
    debugPrint('Editing item at index $index: ${item['itemDescription']}');
  }

  void _updateItem(Map<String, dynamic> updatedItem) {
    if (_editingItemIndex == null) return;
    
    final originalItem = _orderItems[_editingItemIndex!];
    
    // Check if this is an existing item (has lineNo) or a new item
    if (originalItem.containsKey('lineNo') && originalItem['lineNo'] != null && originalItem['lineNo'] > 0) {
      // This is an existing item - track it for update
      final lineNo = originalItem['lineNo'] as int;
      
      // Remove from update list if it exists (to avoid duplicates)
      _itemsToUpdate.removeWhere((item) => item['lineNo'] == lineNo);
      
      // Add the updated item to the update list
      _itemsToUpdate.add(updatedItem);
      
      debugPrint('Added line $lineNo to update list with item: ${updatedItem['itemNo']}, description: ${updatedItem['itemDescription']}, quantity: ${updatedItem['quantity']}, UOM: ${updatedItem['unitOfMeasure']}');
    } else {
      // This is a new item being edited before save - just update it in place
      debugPrint('Updating new item (not yet saved) at index $_editingItemIndex');
    }
    
    // Update the item in the display list
    setState(() {
      _orderItems[_editingItemIndex!] = updatedItem;
      _isEditingItem = false;
      _editingItemIndex = null;
      _editingItemData = null;
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _cancelEdit() {
    setState(() {
      _isEditingItem = false;
      _editingItemIndex = null;
      _editingItemData = null;
    });
  }

  // ...existing code...
  
  double _calculateOrderTotal() {
    double total = 0;
    for (var item in _orderItems) {
      total += item['totalAmount'] as double;
    }
    return total;
  }  // Save all changes to the order
  Future<void> _saveOrderChanges() async {
    setState(() {
      _isSubmitting = true;
      _submissionStatus = 'Preparing to update order...';
    });
    
    // Track failed deletions
    List<Map<String, dynamic>> failedDeletions = [];
    
    try {
      // 1. First, reopen the order if it's not already open
      if (_orderData!['Status'] != 'Open') {
        _updateSubmissionStatus('Reopening order for editing...');
        await _apiService.reopenSalesOrder(widget.orderNo);
      }

      // 2. Update ship-to code if it has changed
      if (_shipToCodeChanged) {
        _updateSubmissionStatus('Updating ship-to address...');
        final newShipToCode = _shipToCodeController.text.trim();
        debugPrint('Updating ship-to code from "${_originalShipToCode}" to "$newShipToCode"');
        try {
          await _apiService.updateOrderShipToCode(
            documentNo: widget.orderNo,
            shipToCode: newShipToCode,
          );
          debugPrint('Ship-to code updated successfully');
        } catch (e) {
          debugPrint('Error updating ship-to code: $e');
          throw Exception('Failed to update ship-to address: $e');
        }
      }

      debugPrint('Order items count before saving: ${_orderItems.length}');
      debugPrint('Items to delete count: ${_itemsToDelete.length}');

      // 3. Delete items that need to be removed
      if (_itemsToDelete.isNotEmpty) {
        _updateSubmissionStatus('Removing items...');
        
        // Log all items to be deleted
        debugPrint('Items to delete (${_itemsToDelete.length}): $_itemsToDelete');        
        // Sort in descending order to avoid index issues
        _itemsToDelete.sort((a, b) => b.compareTo(a));

        // Process each line for deletion
        List<int> successfullyDeletedLines = [];
        
        for (var lineNo in _itemsToDelete) {
          _updateSubmissionStatus('Deleting line $lineNo...');
          debugPrint('Deleting line: $lineNo');
          try {
            await _apiService.deleteSalesOrderLine(widget.orderNo, lineNo);
            debugPrint('Successfully deleted line: $lineNo');
            successfullyDeletedLines.add(lineNo);
          } catch (e) {
            debugPrint('Error deleting line $lineNo: $e');
            // Extract error message and line info
            String errorMessage = e.toString();
            // Find the item description for this line number
            String itemDescription = "Unknown Item";
            Map<String, dynamic>? failedItem;
            
            for (var item in _originalItems) {
              if (item['lineNo'] == lineNo) {
                itemDescription = item['itemDescription'];
                failedItem = Map<String, dynamic>.from(item);
                break;
              }
            }
            
            // Clean up the error message to extract the actual reason
            String displayError = "";
            if (errorMessage.contains("Item Already Shipped")) {
              displayError = "Already Shipped";
            } else if (errorMessage.contains("message")) {
              try {
                // Try to extract the message part from the error JSON
                int messageStart = errorMessage.indexOf("message") + 10; // "message":"
                int messageEnd = errorMessage.indexOf(".", messageStart);
                if (messageEnd == -1) {
                  messageEnd = errorMessage.indexOf("\"", messageStart);
                }
                if (messageStart > 0 && messageEnd > messageStart) {
                  displayError = errorMessage.substring(messageStart, messageEnd);
                }
              } catch (formatEx) {
                displayError = "Cannot Delete";
                debugPrint('Error formatting error message: $formatEx');
              }
            } else {
              displayError = "Cannot Delete";
            }
            
            // Add to failed deletions list with complete error info
            failedDeletions.add({
              'lineNo': lineNo,
              'description': itemDescription,
              'error': errorMessage,
              'displayError': displayError,
              'item': failedItem
            });
          }
        }
        
        // Remove only the successfully deleted lines from _itemsToDelete
        for (var lineNo in successfullyDeletedLines) {
          _itemsToDelete.remove(lineNo);
        }
        
        // If there were failed deletions, restore them to the order items list with error tags
        if (failedDeletions.isNotEmpty && mounted) {
          for (var failedItem in failedDeletions) {
            if (failedItem['item'] != null) {
              Map<String, dynamic> item = failedItem['item'];
              // Add an error tag to the item description
              item['itemDescription'] = "${item['itemDescription']} (${failedItem['displayError']})";
              item['cannotDelete'] = true;
              
              // Add the item back to the order items
              setState(() {
                _orderItems.add(item);
              });
            }
          }
          
          // Show the error dialog
          Future.microtask(() => _showDeleteErrorDialog(failedDeletions));
        }
      } else {
        debugPrint('No items to delete');
      }

      // 3. Add ONLY new items (not existing ones)
      // First, get a list of items that don't have a line number (these are new)
      List<Map<String, dynamic>> onlyNewItems = _orderItems.where((item) {
        return !item.containsKey('lineNo') || item['lineNo'] == null || item['lineNo'] <= 0;
      }).toList();

      if (onlyNewItems.isNotEmpty) {
        _updateSubmissionStatus('Adding new items...');

        for (int i = 0; i < onlyNewItems.length; i++) {
          final item = onlyNewItems[i];
          _updateSubmissionStatus('Adding item ${i+1} of ${onlyNewItems.length}: ${item['itemDescription']}...');

          // Convert quantity to integer as required by the API
          final int quantity = item['quantity'].round();          await _apiService.addSalesOrderLine(
            documentNo: widget.orderNo,
            itemNo: item['itemNo'],
            locationCode: _orderData!['Location_Code'] as String,
            quantity: quantity,
            unitOfMeasureCode: item['unitOfMeasure'],
          );
        }
      }

      // 4. Update existing items that have been modified
      if (_itemsToUpdate.isNotEmpty) {
        _updateSubmissionStatus('Updating existing items...');

        for (int i = 0; i < _itemsToUpdate.length; i++) {
          final item = _itemsToUpdate[i];
          final lineNo = item['lineNo'] as int;
          
          _updateSubmissionStatus('Updating item ${i+1} of ${_itemsToUpdate.length}: ${item['itemDescription']}...');

          debugPrint('Updating line $lineNo: ItemNo=${item['itemNo']}, Description=${item['itemDescription']}, Quantity=${item['quantity']}, UOM=${item['unitOfMeasure']}');

          try {
            await _apiService.updateSalesOrderLine(
              documentNo: widget.orderNo,
              lineNo: lineNo,
              itemNo: item['itemNo'] as String,
              description: item['itemDescription'] as String,
              quantity: item['quantity'] as double,
              unitOfMeasureCode: item['unitOfMeasure'] as String,
            );
            
            debugPrint('Successfully updated line $lineNo');
          } catch (e) {
            debugPrint('Error updating line $lineNo: $e');
            throw Exception('Failed to update item ${item['itemDescription']}: $e');
          }
        }
      }

      _updateSubmissionStatus('Order updated successfully!');
      
      // Reset ship-to code change tracking after successful update
      if (_shipToCodeChanged) {
        _originalShipToCode = _shipToCodeController.text.trim();
        _shipToCodeChanged = false;
      }
      
      // Determine if we should return to order screen or stay on edit screen
      bool shouldStayOnEditScreen = failedDeletions.isNotEmpty;
        // Show success message only if everything was successful
      if (!failedDeletions.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }      setState(() {
        _isSubmitting = false;
        // Clear the tracking arrays after successful update
        if (!shouldStayOnEditScreen) {
          _itemsToDelete.clear();
          _itemsToAdd.clear();
          _itemsToUpdate.clear();
        }
      });
      
      // Return to orders screen only if everything was successful
      if (mounted && !shouldStayOnEditScreen) {
        Navigator.of(context).pop();
      }
      
      // If staying on screen due to errors, reload the order details
      if (shouldStayOnEditScreen && mounted) {
        Future.microtask(() => _loadOrderDetails());
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
  }    TableRow _buildInfoRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0), // Reduced vertical padding
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              fontSize: 13, // Slightly smaller font
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0), // Reduced vertical padding
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13, // Slightly smaller font
            ),
          ),
        ),
      ],
    );
  }
  TableRow _buildEditableShipToRow() {
    // Get current ship-to display text (code + name if available)
    String displayText = _shipToCodeController.text.trim();
    if (_originalShipToName != null && _originalShipToName!.isNotEmpty && displayText.isNotEmpty) {
      displayText = '${_shipToCodeController.text.trim()} - $_originalShipToName';
    }
    
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Text(
            'Ship-to Code:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: GestureDetector(
            onTap: () async {
              // Check if we have customer data
              final customerNo = _orderData?['Sell_to_Customer_No'] as String?;
              if (customerNo == null || customerNo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customer information not available')),
                );
                return;
              }
              
              // Find currently selected ship-to
              ShipTo? currentShipTo;
              if (_shipToCodeController.text.trim().isNotEmpty && _shipToAddresses.isNotEmpty) {
                try {
                  currentShipTo = _shipToAddresses.firstWhere(
                    (shipTo) => shipTo.code == _shipToCodeController.text.trim(),
                  );
                } catch (e) {
                  // Ship-to not found in list, ignore
                }
              }
              
              final selectedShipTo = await Navigator.push<ShipTo>(
                context,
                MaterialPageRoute(
                  builder: (context) => ShipToSelectionScreen(
                    customerNo: customerNo,
                    initialSelection: currentShipTo,
                  ),
                ),
              );
              
              if (selectedShipTo != null) {
                setState(() {
                  _shipToCodeController.text = selectedShipTo.code;
                  _originalShipToName = selectedShipTo.name;
                  _shipToCodeChanged = selectedShipTo.code != (_originalShipToCode ?? '');
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayText.isNotEmpty ? displayText : 'Tap to select ship-to address',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: displayText.isNotEmpty ? Colors.black : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Clear button - always show to allow clearing the field
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _shipToCodeController.clear();
                            _originalShipToName = null;
                            _shipToCodeChanged = '' != (_originalShipToCode ?? '');
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.clear,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Edit indicator
                      if (_shipToCodeChanged)
                        Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.orange.shade600,
                        ),
                      if (_shipToCodeChanged)
                        const SizedBox(width: 4),
                      // Dropdown arrow
                      Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
    Widget _buildStatusChip(String status) {
    Color chipColor;

    switch (status.toLowerCase()) {
      case 'completed':
        chipColor = AppColors.statusCompleted;
        break;
      case 'released':
        chipColor = AppColors.statusReleased;
        break;
      case 'pending approval':
        chipColor = AppColors.statusPending;
        break;
      case 'open':
        chipColor = AppColors.statusOpen;
        break;
      default:
        chipColor = AppColors.statusDefault;
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
    // Show error dialog for failed deletions
  void _showDeleteErrorDialog(List<Map<String, dynamic>> failedDeletions) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
            const SizedBox(width: 8),
            const Text('Could Not Delete Some Items'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following items could not be deleted:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...failedDeletions.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.red.shade50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item['description'],
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reason: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item['displayError'] ?? 'Unknown error',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )).toList(),
              const SizedBox(height: 8),
              Text(
                'These items have been tagged and cannot be deleted.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK, GOT IT'),
          ),
        ],
      ),
    );
  }
}