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

class _OrderFormWidgetState extends State<OrderFormWidget> {  // Controllers
  final TextEditingController _orderDateController = TextEditingController();
  final TextEditingController _saleCodeController = TextEditingController();
  final TextEditingController _customerSearchController = TextEditingController();

  // API Service
  final ApiService _apiService = ApiService();
  // Data Lists
  List<Customer> _customers = [];
  List<ShipTo> _shipToLocations = [];
  List<Location> _locations = [];
  // Loading states
  bool _isLoadingShipTo = false;
  bool _isLoadingLocations = false;

  // For debounced customer search
  Timer? _debounce;

  @override
  void initState() {
    super.initState();    // Initialize date controllers
    if (widget.orderData['orderDate'] != null) {
      _orderDateController.text = DateFormat('dd/MM/yyyy').format(widget.orderData['orderDate']);
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
    });    // Initial fetch of limited customers and locations with staggered delays
    _fetchInitialCustomers();
    
    // Add delay before fetching locations to prevent API overload
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fetchLocations();
      }
    });

    // If customer is already selected, fetch ship-to addresses with additional delay
    if (widget.orderData['customer'] != null) {
      // Find customer by name
      Customer? selectedCustomer = _getCustomerByName(widget.orderData['customer']);
      if (selectedCustomer != null) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _fetchShipToAddresses(selectedCustomer.no);
          }
        });
      }
    }
  }
  @override
  void dispose() {
    _orderDateController.dispose();
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
      widget.onUpdate('saleCode', saleCode);      // Fetch ship-to addresses for this customer with delay to prevent 503 errors
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _fetchShipToAddresses(customer.no);
        }
      });
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
    try {
      // Get the sales person from auth service
      final authService = Provider.of<AuthService>(context, listen: false);
      final salesPerson = authService.currentUser;
      
      if (salesPerson == null) {
        throw Exception('User not authenticated');
      }

      // For team persona, use teamCode and Team_Code field
      final isTeamPersona = salesPerson.teamCode.isNotEmpty;
      final customersData = await _apiService.getCustomers(
        limit: 20,
        salesPersonCode: isTeamPersona ? salesPerson.teamCode : salesPerson.code,
        fieldName: isTeamPersona ? 'Team_Code' : 'Salesperson_Code',
      );
      setState(() {
        _customers = customersData.map((json) => Customer.fromJson(json)).toList();
      });    } catch (e) {      if (mounted) {
        // Only show error dialog for 400 errors with message key, ignore 503 errors
        final String errorStr = e.toString();
        if (errorStr.contains("400") && errorStr.contains("message") && !errorStr.contains("503")) {
          _showErrorDialog('Error loading customers: $e');
        }
      }
    }
  }
  Future<void> _searchCustomers(String query) async {
    try {
      // Get the sales person from auth service
      final authService = Provider.of<AuthService>(context, listen: false);
      final salesPerson = authService.currentUser;
      
      if (salesPerson == null) {
        throw Exception('User not authenticated');
      }

      // For team persona, use teamCode and Team_Code field
      final isTeamPersona = salesPerson.teamCode.isNotEmpty;
      final customersData = await _apiService.getCustomers(
        searchQuery: query,
        salesPersonCode: isTeamPersona ? salesPerson.teamCode : salesPerson.code,
        fieldName: isTeamPersona ? 'Team_Code' : 'Salesperson_Code',
      );
      setState(() {
        _customers = customersData.map((json) => Customer.fromJson(json)).toList();
      });    } catch (e) {      if (mounted) {
        // Only show error dialog for 400 errors with message key, ignore 503 errors
        final String errorStr = e.toString();
        if (errorStr.contains("400") && errorStr.contains("message") && !errorStr.contains("503")) {
          _showErrorDialog('Error searching customers: $e');
        }
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
    } catch (e) {      setState(() {
        _isLoadingShipTo = false;
      });      if (mounted) {
        // Only show error dialog for 400 errors with message key, ignore 503 errors
        final String errorStr = e.toString();
        if (errorStr.contains("400") && errorStr.contains("message") && !errorStr.contains("503")) {
          _showErrorDialog('Error loading ship-to addresses: $e');
        }
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
      });    } catch (e) {
      setState(() {
        _isLoadingLocations = false;
      });
      if (mounted) {
        // Only show error dialog for 400 errors with message key, ignore 503 errors
        final String errorStr = e.toString();
        if (errorStr.contains("400") && errorStr.contains("message") && !errorStr.contains("503")) {
          _showErrorDialog('Error loading locations: $e');
        }
      }
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
  }  // Layout for small screens (stacked)
  Widget _buildSmallScreenLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order Date only (non-editable, today's date)
        _buildOrderDateDisplay(),
        const SizedBox(height: 16),
        
        // Customer Selection
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Name with Sale Code beside it
            Row(
              children: [
                const Text(
                  'Customer Name*',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.orderData['saleCode'] != null && widget.orderData['saleCode'].isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200, width: 1),
                    ),
                    child: Text(
                      widget.orderData['saleCode'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
              ],
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
      children: [        // Row 1: Order Date and Customer
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Date (non-editable, today's date)
            Expanded(
              child: _buildOrderDateDisplay(),
            ),
            const SizedBox(width: 16),
            // Customer Selection
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Name with Sale Code beside it
                  Row(
                    children: [
                      const Text(
                        'Customer Name*',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.orderData['saleCode'] != null && widget.orderData['saleCode'].isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade200, width: 1),
                          ),
                          child: Text(
                            widget.orderData['saleCode'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                    ],
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

        // Row 2: Ship To and Location
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
  // Build order date display (non-editable, shows today's date)
  Widget _buildOrderDateDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Date*',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                DateFormat('dd/MM/yyyy').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Build Ship To selection widget
  Widget _buildShipToSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ship To Code',
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
              // Keep this snackbar as it's a UI validation, not an API error
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
}