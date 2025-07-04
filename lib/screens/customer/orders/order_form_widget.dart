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

  // API Service
  final ApiService _apiService = ApiService();
  // Data Lists
  List<ShipTo> _shipToLocations = [];
  List<Location> _locations = [];
  // Loading states
  bool _isLoadingShipTo = false;
  bool _isLoadingLocations = false;

  @override
  void initState() {
    super.initState();
    // Set order date if provided
    if (widget.orderData['orderDate'] != null) {
      _orderDateController.text = DateFormat('dd/MM/yyyy').format(widget.orderData['orderDate']);
    }

    // Pre-select customer as the logged-in user (set only once, no setState or delayed call)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final customer = authService.currentUser;
      if (customer != null) {
        widget.onUpdate('customer', customer.name);
        widget.onUpdate('customerNo', customer.no);
        widget.onUpdate('customerPriceGroup', customer.customerPriceGroup);
        // Generate sale code based on customer number
        final saleCode = 'SC-${customer.no}';
        _saleCodeController.text = saleCode;
        widget.onUpdate('saleCode', saleCode);
        _fetchShipToAddresses(customer.no);

        // Parse location codes from customer.Customer_Location (comma-separated string)
        List<String> locationCodes = [];
        if (customer.customerLocation != null && customer.customerLocation is String && customer.customerLocation.toString().trim().isNotEmpty) {
          locationCodes = customer.customerLocation.toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
        // Store in orderData for later use if needed
        widget.onUpdate('locationCodes', locationCodes);
        // Fetch locations using these codes
        _fetchLocationsWithCodes(locationCodes);
      }
    });

    // Remove old fetch locations call for customer user
  }
  @override
  void dispose() {
    _orderDateController.dispose();
    _saleCodeController.dispose();
    super.dispose();
  }

  // Customer cannot be changed by the user, so this is not needed anymore

  // Customer selection helpers are not needed anymore
  // Customer fetching/searching is not needed for customer user

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

  Future<void> _fetchLocationsWithCodes(List<String> locationCodes) async {
    setState(() {
      _isLoadingLocations = true;
    });

    try {
      if (locationCodes.isEmpty) {
        throw Exception('No locations assigned to this user');
      }

      // Fetch only the locations assigned to the customer
      final locationsData = await _apiService.getLocations(locationCodes: locationCodes);
      setState(() {
        _locations = locationsData.map((json) => Location.fromJson(json)).toList();
        _isLoadingLocations = false;
      });
    } catch (e) {
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
        // Customer Name (pre-selected, not editable)
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.orderData['customer'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const Icon(Icons.lock, size: 14, color: Colors.grey),
            ],
          ),
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
            // Order Date (non-editable, today's date)
            Expanded(
              child: _buildOrderDateDisplay(),
            ),
            const SizedBox(width: 16),
            // Customer Name (pre-selected, not editable)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.orderData['customer'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        const Icon(Icons.lock, size: 14, color: Colors.grey),
                      ],
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
    );
  }
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