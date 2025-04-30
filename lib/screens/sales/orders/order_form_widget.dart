import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../models/customer.dart';
import '../../../models/ship_to.dart';
import '../../../models/location.dart';
import '../../../services/api_service.dart';
import 'searchable_dropdown.dart';

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

    // Initial fetch of limited customers
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

  Customer? _getCustomerByName(String customerName) {
    try {
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
      final customersData = await _apiService.getCustomers(limit: 20);
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
      final customersData = await _apiService.getCustomers(searchQuery: query);
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
      final locationsData = await _apiService.getLocations();
      setState(() {
        _locations = locationsData.map((json) => Location.fromJson(json)).toList();
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocations = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading locations: $e')),
        );
      }
    }
  }

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
          onSelect: (date) {
            widget.onUpdate('orderDate', date);
          },
        ),
        const SizedBox(height: 16),

        // Customer Dropdown with Search
        _isLoadingCustomers
            ? const Center(child: CircularProgressIndicator())
            : SearchableDropdown<Customer>(
          label: 'Customer Name',
          items: _customers,
          selectedItem: widget.orderData['customer'] != null
              ? _getCustomerByName(widget.orderData['customer'])
              : null,
          onChanged: (customer) {
            if (customer != null) {
              widget.onUpdate('customer', customer.name);

              // Generate sale code based on customer number
              final saleCode = 'SC-${customer.no}';
              _saleCodeController.text = saleCode;
              widget.onUpdate('saleCode', saleCode);

              // Fetch ship-to addresses for this customer
              _fetchShipToAddresses(customer.no);
            } else {
              widget.onUpdate('customer', null);
              _saleCodeController.clear();
              widget.onUpdate('saleCode', '');
              setState(() {
                _shipToLocations = [];
              });
            }
          },
          required: true,
          displayStringForItem: (Customer customer) => '${customer.no} - ${customer.name}',
          searchController: _customerSearchController,
          onSearchTextChanged: (String query) {
            // Debounced search is handled by listener in initState
          },
        ),
        const SizedBox(height: 16),

        // Sale Code
        _buildTextField(
          label: 'Customer Sale Code',
          controller: _saleCodeController,
          enabled: false,
        ),
        const SizedBox(height: 16),

        // Delivery Date
        _buildDateField(
          label: 'Request Del. Date',
          controller: _deliveryDateController,
          required: true,
          onSelect: (date) {
            widget.onUpdate('deliveryDate', date);
          },
        ),
        const SizedBox(height: 16),

        // Ship To
        _isLoadingShipTo
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchableDropdown<ShipTo>(
              label: 'Ship To Code',
              items: _shipToLocations,
              selectedItem: widget.orderData['shipTo'] != null && _shipToLocations.isNotEmpty
                  ? _shipToLocations.firstWhere(
                    (shipTo) => shipTo.name == widget.orderData['shipTo'],
                orElse: () => _shipToLocations.first,
              )
                  : null,
              onChanged: (shipTo) {
                widget.onUpdate('shipTo', shipTo?.name);
              },
              required: true,
              displayStringForItem: (ShipTo shipTo) => '${shipTo.code} - ${shipTo.name}',
            ),

            // Add New Ship-To button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _showAddShipToDialog();
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add New'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Location
        _isLoadingLocations
            ? const Center(child: CircularProgressIndicator())
            : SearchableDropdown<Location>(
          label: 'Location',
          items: _locations,
          selectedItem: widget.orderData['location'] != null && _locations.isNotEmpty
              ? _locations.firstWhere(
                (location) => location.name == widget.orderData['location'],
            orElse: () => _locations.first,
          )
              : null,
          onChanged: (location) {
            widget.onUpdate('location', location?.name);
          },
          required: true,
          displayStringForItem: (Location location) => '${location.code} - ${location.name}',
        ),
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
                onSelect: (date) {
                  widget.onUpdate('orderDate', date);
                },
              ),
            ),
            const SizedBox(width: 16),
            // Customer Dropdown with Search
            Expanded(
              child: _isLoadingCustomers
                  ? const Center(child: CircularProgressIndicator())
                  : SearchableDropdown<Customer>(
                label: 'Customer Name',
                items: _customers,
                selectedItem: widget.orderData['customer'] != null
                    ? _getCustomerByName(widget.orderData['customer'])
                    : null,
                onChanged: (customer) {
                  if (customer != null) {
                    widget.onUpdate('customer', customer.name);

                    // Generate sale code based on customer number
                    final saleCode = 'SC-${customer.no}';
                    _saleCodeController.text = saleCode;
                    widget.onUpdate('saleCode', saleCode);

                    // Fetch ship-to addresses for this customer
                    _fetchShipToAddresses(customer.no);
                  } else {
                    widget.onUpdate('customer', null);
                    _saleCodeController.clear();
                    widget.onUpdate('saleCode', '');
                    setState(() {
                      _shipToLocations = [];
                    });
                  }
                },
                required: true,
                displayStringForItem: (Customer customer) => '${customer.no} - ${customer.name}',
                searchController: _customerSearchController,
                onSearchTextChanged: (String query) {
                  // Debounced search is handled by listener in initState
                },
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
              child: _buildTextField(
                label: 'Customer Sale Code',
                controller: _saleCodeController,
                enabled: false,
              ),
            ),
            const SizedBox(width: 16),
            // Delivery Date
            Expanded(
              child: _buildDateField(
                label: 'Request Del. Date',
                controller: _deliveryDateController,
                required: true,
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
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchableDropdown<ShipTo>(
                    label: 'Ship To Code',
                    items: _shipToLocations,
                    selectedItem: widget.orderData['shipTo'] != null && _shipToLocations.isNotEmpty
                        ? _shipToLocations.firstWhere(
                          (shipTo) => shipTo.name == widget.orderData['shipTo'],
                      orElse: () => _shipToLocations.first,
                    )
                        : null,
                    onChanged: (shipTo) {
                      widget.onUpdate('shipTo', shipTo?.name);
                    },
                    required: true,
                    displayStringForItem: (ShipTo shipTo) => '${shipTo.code} - ${shipTo.name}',
                  ),

                  // Add New Ship-To button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        _showAddShipToDialog();
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add New'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Location
            Expanded(
              child: _isLoadingLocations
                  ? const Center(child: CircularProgressIndicator())
                  : SearchableDropdown<Location>(
                label: 'Location',
                items: _locations,
                selectedItem: widget.orderData['location'] != null && _locations.isNotEmpty
                    ? _locations.firstWhere(
                      (location) => location.name == widget.orderData['location'],
                  orElse: () => _locations.first,
                )
                    : null,
                onChanged: (location) {
                  widget.onUpdate('location', location?.name);
                },
                required: true,
                displayStringForItem: (Location location) => '${location.code} - ${location.name}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build a text field widget
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label*' : label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade100,
          ),
          validator: validator ?? (required
              ? (value) => value == null || value.isEmpty ? 'This field is required' : null
              : null),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // Build a date picker field
  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    required Function(DateTime) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label*' : label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
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
          validator: required
              ? (value) => value == null || value.isEmpty ? 'This field is required' : null
              : null,
          onTap: () async {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );

            if (pickedDate != null) {
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

  // Show add ship-to dialog
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

    final TextEditingController nameController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController cityController = TextEditingController();
    final TextEditingController stateController = TextEditingController();
    final TextEditingController postcodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Ship-To Address'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: postcodeController,
                decoration: const InputDecoration(
                  labelText: 'Post Code',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name is required')),
                );
                return;
              }

              // Here you would call the API to create a new ship-to address
              // For now, we'll just show a success message
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New ship-to address added successfully')),
              );

              // Refresh ship-to addresses after adding new one
              _fetchShipToAddresses(selectedCustomer.no);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Helper for min function
  int min(int a, int b) {
    return a < b ? a : b;
  }
}