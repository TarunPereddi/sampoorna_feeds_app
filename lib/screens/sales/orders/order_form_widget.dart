import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../models/customer.dart';
import '../../../models/ship_to.dart';
import '../../../models/location.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import 'customer_selection_screen.dart';
import 'ship_to_selection_screen.dart';
import 'location_selection_screen.dart';
import 'add_ship_to_screen.dart'; // Import the new screen

class OrderFormWidget extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final Function(String, dynamic) onUpdate;
  final bool isSmallScreen;

  const OrderFormWidget({
    super.key,
    required this.orderData,
    required this.onUpdate,
    required this.isSmallScreen,
  });

  @override
  State<OrderFormWidget> createState() => _OrderFormWidgetState();
}

class _OrderFormWidgetState extends State<OrderFormWidget> {
  // Controllers
  final TextEditingController _orderDateController = TextEditingController();
  final TextEditingController _deliveryDateController = TextEditingController();
  final TextEditingController _saleCodeController = TextEditingController();
  final TextEditingController _customerSearchController = TextEditingController();

  // API Service
  final ApiService _apiService = ApiService();

  // Data Lists
  List<Customer> _customers = [];
  List<ShipTo> _shipToLocations = [];
  List<Location> _locations = [];
  // Loading states
  bool _isLoadingCustomers = false;
  bool _isLoadingShipTo = false;
  bool _isLoadingLocations = false;

  // For debounced customer search
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    // Initialize date controllers
    if (widget.orderData['orderDate'] != null) {
      _orderDateController.text = DateFormat('dd/MM/yyyy').format(widget.orderData['orderDate']);
    }

    if (widget.orderData['deliveryDate'] != null) {
      _deliveryDateController.text = DateFormat('dd/MM/yyyy').format(widget.orderData['deliveryDate']);
    }

    _saleCodeController.text = widget.orderData['saleCode'] ?? '';

    // Setup customer search listener with debounce
    _customerSearchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (_customerSearchController.text.length >= 3) {
          _searchCustomers(_customerSearchController.text);
        }
      });
    });

    // Initial fetch of limited customers and locations
    _fetchInitialCustomers();
    _fetchLocations();

    // If customer is already selected, fetch ship-to addresses
    if (widget.orderData['customer'] != null) {
      // Find customer by name
      Customer? selectedCustomer = _getCustomerByName(widget.orderData['customer']);
      if (selectedCustomer != null) {
        _fetchShipToAddresses(selectedCustomer.no);
      }
    }
  }

  @override
  void dispose() {
    _orderDateController.dispose();
    _deliveryDateController.dispose();
    _saleCodeController.dispose();
    _customerSearchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleCustomerChange(Customer? customer) {
    if (customer != null) {
      widget.onUpdate('customer', '${customer.no} - ${customer.name}');
      widget.onUpdate('customerNo', customer.no);
      widget.onUpdate('customerPriceGroup', customer.customerPriceGroup); // Add this line

      // Generate sale code based on customer number
      final saleCode = 'SC-${customer.no}';
      _saleCodeController.text = saleCode;
      widget.onUpdate('saleCode', saleCode);

      // Fetch ship-to addresses for this customer
      _fetchShipToAddresses(customer.no);
    } else {
      widget.onUpdate('customer', null);
      widget.onUpdate('customerNo', null);
      widget.onUpdate('customerPriceGroup', null); // Add this line
      _saleCodeController.clear();
      widget.onUpdate('saleCode', '');
      setState(() {
        _shipToLocations = [];
      });
    }
    widget.onUpdate('shipTo', null);
  widget.onUpdate('shipToCode', '');
  }

  Customer? _getCustomerByName(String customerName) {
    try {
      if (customerName.contains(' - ')) {
        // If the format is "Code - Name"
        final customerCode = customerName.split(' - ').first.trim();
        return _customers.firstWhere((customer) => customer.no == customerCode);
      }
      return _customers.firstWhere((customer) => customer.name == customerName);
    } catch (e) {
      return null;
    }
  }

  Future<void> _fetchInitialCustomers() async {
    setState(() {
      _isLoadingCustomers = true;
    });

    try {
      // Get the sales person code from auth service
      final authService = Provider.of<AuthService>(context, listen: false);
      final salesPerson = authService.currentUser;
      
      if (salesPerson == null) {
        throw Exception('User not authenticated');
      }

      final customersData = await _apiService.getCustomers(
        limit: 20,
        salesPersonCode: salesPerson.code,
      );
      setState(() {
        _customers = customersData.map((json) => Customer.fromJson(json)).toList();
        _isLoadingCustomers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCustomers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading customers: $e')),
        );
      }
    }
  }

  Future<void> _searchCustomers(String query) async {
    setState(() {
      _isLoadingCustomers = true;
    });

    try {
      // Get the sales person code from auth service
      final authService = Provider.of<AuthService>(context, listen: false);
      final salesPerson = authService.currentUser;
      
      if (salesPerson == null) {
        throw Exception('User not authenticated');
      }

      final customersData = await _apiService.getCustomers(
        searchQuery: query,
        salesPersonCode: salesPerson.code,
      );
      setState(() {
        _customers = customersData.map((json) => Customer.fromJson(json)).toList();
        _isLoadingCustomers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCustomers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching customers: $e')),
        );
      }
    }
  }

  Future<void> _fetchShipToAddresses(String customerNo) async {
    setState(() {
      _isLoadingShipTo = true;
      _shipToLocations = []; // Clear previous ship-to addresses
    });

    try {
      final shipToData = await _apiService.getShipToAddresses(customerNo: customerNo);
      setState(() {
        _shipToLocations = shipToData.map((json) => ShipTo.fromJson(json)).toList();
        _isLoadingShipTo = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingShipTo = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ship-to addresses: $e')),
        );
      }
    }
  }

  Future<void> _fetchLocations() async {
    setState(() {
      _isLoadingLocations = true;
    });

    try {
      // Get the sales person from auth service to access their locations
      final authService = Provider.of<AuthService>(context, listen: false);
      final salesPerson = authService.currentUser;
      
      if (salesPerson == null) {
        throw Exception('User not authenticated');
      }

      // Get the location codes from the sales person object
      final locationCodes = salesPerson.locationCodes;
      
      if (locationCodes.isEmpty) {
        throw Exception('No locations assigned to this user');
      }

      // Fetch only the locations assigned to the sales person
      final locationsData = await _apiService.getLocations(locationCodes: locationCodes);
      
      setState(() {
        _locations = locationsData.map((json) => Location.fromJson(json)).toList();
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocations = false;
      });
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Error loading locations: $e')),
      //   );
      // }
    }
  }
  // _addShipToAddress method has been removed as it's no longer needed
  // Ship-to address creation is now handled by the AddShipToScreen

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            const Text(
              'Order Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Responsive layout based on screen size
            widget.isSmallScreen
                ? _buildSmallScreenLayout()
                : _buildLargeScreenLayout(),
          ],
        ),
      ),
    );
  }

  // Layout for small screens (stacked)
  Widget _buildSmallScreenLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order Date
        _buildDateField(
          label: 'Order Date',
          controller: _orderDateController,
          required: true,
          isCurrentDate: true,
          onSelect: (date) {
            widget.onUpdate('orderDate', date);
          },
        ),
        const SizedBox(height: 16),        // Customer Selection
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Name*',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                // Navigate to customer selection screen
                final selectedCustomer = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerSelectionScreen(
                      initialSelection: widget.orderData['customer'] != null
                          ? _getCustomerByName(widget.orderData['customer'])
                          : null,
                    ),
                  ),
                );

                if (selectedCustomer != null) {
                  _handleCustomerChange(selectedCustomer);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.orderData['customer'] != null
                            ? widget.orderData['customer']
                            : 'Select a customer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: widget.orderData['customer'] != null 
                            ? Colors.black 
                            : Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Sale Code
        _buildSaleCodeDisplay(),
        const SizedBox(height: 16),

        // Delivery Date
        _buildDateField(
          label: 'Request Del. Date',
          controller: _deliveryDateController,
          required: true,
          isCurrentDate: false,
          onSelect: (date) {
            widget.onUpdate('deliveryDate', date);
          },
        ),
        const SizedBox(height: 16),

        // Ship To
        _isLoadingShipTo
            ? const Center(child: CircularProgressIndicator())
            : _buildShipToSelection(),
        const SizedBox(height: 16),

        // Location
        _isLoadingLocations
            ? const Center(child: CircularProgressIndicator())
            : _buildLocationSelection(),
      ],
    );
  }

  // Layout for larger screens (grid)
  Widget _buildLargeScreenLayout() {
    return Column(
      children: [
        // Row 1: Order Date and Customer
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Date
            Expanded(
              child: _buildDateField(
                label: 'Order Date',
                controller: _orderDateController,
                required: true,
                isCurrentDate: true,
                onSelect: (date) {
                  widget.onUpdate('orderDate', date);
                },
              ),
            ),
            const SizedBox(width: 16),            // Customer Selection
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Name*',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      // Navigate to customer selection screen
                      final selectedCustomer = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerSelectionScreen(
                            initialSelection: widget.orderData['customer'] != null
                                ? _getCustomerByName(widget.orderData['customer'])
                                : null,
                          ),
                        ),
                      );

                      if (selectedCustomer != null) {
                        _handleCustomerChange(selectedCustomer);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.orderData['customer'] != null
                                  ? widget.orderData['customer']
                                  : 'Select a customer',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: widget.orderData['customer'] != null 
                                  ? Colors.black 
                                  : Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 2: Sale Code and Delivery Date
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sale Code
            Expanded(
              child: _buildSaleCodeDisplay(),
            ),
            const SizedBox(width: 16),
            // Delivery Date
            Expanded(
              child: _buildDateField(
                label: 'Request Del. Date',
                controller: _deliveryDateController,
                required: true,
                isCurrentDate: false,
                onSelect: (date) {
                  widget.onUpdate('deliveryDate', date);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 3: Ship To and Location
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ship To
            Expanded(
              child: _isLoadingShipTo
                  ? const Center(child: CircularProgressIndicator())
                  : _buildShipToSelection(),
            ),
            const SizedBox(width: 16),
            // Location
            Expanded(
              child: _isLoadingLocations
                  ? const Center(child: CircularProgressIndicator())
                  : _buildLocationSelection(),
            ),
          ],
        ),
      ],
    );  }
  // Build a date picker field
  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    bool isCurrentDate = false, // If true, date cannot be before today
    required Function(DateTime) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label*' : label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
            isDense: true,
          ),
          validator: required
              ? (value) => value == null || value.isEmpty ? 'This field is required' : null
              : null,
          onTap: () async {
            // Set minimum date based on isCurrentDate flag
            final DateTime now = DateTime.now();
            final DateTime minDate = isCurrentDate ? now : DateTime(2020);
            
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: isCurrentDate ? now : (widget.orderData['orderDate'] ?? now),
              firstDate: minDate,
              lastDate: DateTime(2030),
            );

            if (pickedDate != null) {
              // For delivery date, ensure it's not before order date
              if (!isCurrentDate && widget.orderData['orderDate'] != null) {
                final orderDate = widget.orderData['orderDate'] as DateTime;
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
        if (required && controller.text.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 6.0, left: 10.0),
          child: Text(
            'This field is required',
            style: TextStyle(
              color: Colors.red,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
  // Build a compact label for sale code (converts from large field to small label)
  Widget _buildSaleCodeDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sale Code',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.blue.shade200, width: 1),
          ),
          child: Text(
            widget.orderData['saleCode'] ?? 'Not assigned',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }
  // Build Ship To selection widget
  Widget _buildShipToSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ship To Code*',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            // Check if customer is selected
            if (widget.orderData['customerNo'] == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a customer first')),
              );
              return;
            }
            
            // Find currently selected ship-to
            ShipTo? currentShipTo;
            if (widget.orderData['shipTo'] != null && _shipToLocations.isNotEmpty) {
              try {
                currentShipTo = _shipToLocations.firstWhere(
                  (shipTo) => shipTo.name == widget.orderData['shipTo'],
                );
              } catch (e) {
                // Ship-to not found in list, ignore
              }
            }
            
            final selectedShipTo = await Navigator.push<ShipTo>(
              context,
              MaterialPageRoute(
                builder: (context) => ShipToSelectionScreen(
                  customerNo: widget.orderData['customerNo'],
                  initialSelection: currentShipTo,
                ),
              ),
            );
            
            if (selectedShipTo != null) {
              widget.onUpdate('shipTo', selectedShipTo.name);
              widget.onUpdate('shipToCode', selectedShipTo.code);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: widget.orderData['shipTo'] != null
                      ? Text(
                          widget.orderData['shipTo'].toString(),
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        )
                      : Text(
                          'Select ship-to address...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                ),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        ),        // Add New Ship-To button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              _showAddShipToDialog();
            },
            icon: const Icon(Icons.add, size: 14),
            label: const Text(
              'Add New',
              style: TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
      ],
    );
  }
  // Build Location selection widget
  Widget _buildLocationSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location*',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            // Find currently selected location
            Location? currentLocation;
            if (widget.orderData['location'] != null && _locations.isNotEmpty) {
              try {
                currentLocation = _locations.firstWhere(
                  (location) => location.name == widget.orderData['location'],
                );
              } catch (e) {
                // Location not found in list, ignore
              }
            }
            
            final selectedLocation = await Navigator.push<Location>(
              context,
              MaterialPageRoute(
                builder: (context) => LocationSelectionScreen(
                  locations: _locations,
                  initialSelection: currentLocation,
                ),
              ),
            );
            
            if (selectedLocation != null) {
              widget.onUpdate('location', selectedLocation.name);
              widget.onUpdate('locationCode', selectedLocation.code);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: widget.orderData['location'] != null
                      ? Text(
                          widget.orderData['location'].toString(),
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        )
                      : Text(
                          'Select location...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                ),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
  // Navigate to add ship-to screen
  void _showAddShipToDialog() {
    // Check if customer is selected
    if (widget.orderData['customer'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer first')),
      );
      return;
    }

    Customer? selectedCustomer = _getCustomerByName(widget.orderData['customer']);
    if (selectedCustomer == null) return;

    // Navigate to the AddShipToScreen instead of showing a dialog
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => AddShipToScreen(
          customerNo: selectedCustomer.no,
        ),
      ),
    ).then((newShipTo) {
      // If a new ship-to was added, refresh the list and select it
      if (newShipTo != null && newShipTo is ShipTo) {
        _fetchShipToAddresses(selectedCustomer.no);
        
        // Automatically select the new ship-to
        widget.onUpdate('shipTo', newShipTo.name);
        widget.onUpdate('shipToCode', newShipTo.code);
      }
    });
  }
}