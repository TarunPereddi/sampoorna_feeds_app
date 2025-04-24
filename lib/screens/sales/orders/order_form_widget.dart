import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // Mock data for dropdowns - will be replaced with API data
  final List<String> _customers = [
    'B.K. Enterprises',
    'Prajjawal Enterprises',
    'Agro Suppliers Ltd',
    'Farm Solutions Inc',
    'Green Agro Ltd',
    'Farmhouse Supplies',
    'Agritech Solutions',
    'Rural Feeds Ltd',
    'Modern Agriculture Inc',
    'Country Poultry Solutions',
    'NextGen Farming',
    'Organic Solutions',
    'FarmEasy Supplies',
    'GrowWell Technologies',
  ];

  final List<String> _shipToLocations = [
    'Main Warehouse',
    'Delhi Branch',
    'Mumbai Branch',
    'Bangalore Branch',
    'Hyderabad Center',
    'Chennai Depot',
    'Kolkata Warehouse',
    'Pune Distribution Center',
    'Ahmedabad Storage',
    'Jaipur Facility',
  ];

  final List<String> _locations = [
    'Location 1',
    'Location 2',
    'Location 3',
    'Location 4',
    'North Zone',
    'South Zone',
    'East Zone',
    'West Zone',
    'Central Warehouse',
    'Distribution Hub',
  ];

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
  }

  @override
  void dispose() {
    _orderDateController.dispose();
    _deliveryDateController.dispose();
    _saleCodeController.dispose();
    super.dispose();
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
        SearchableDropdown(
          label: 'Customer Name',
          items: _customers,
          selectedItem: widget.orderData['customer'],
          onChanged: (value) {
            widget.onUpdate('customer', value);
            if (value != null) {
              // Auto-generate sale code based on customer name
              final saleCode = 'SC-${value.substring(0, min(3, value.length)).toUpperCase()}';
              _saleCodeController.text = saleCode;
              widget.onUpdate('saleCode', saleCode);
            }
          },
          required: true,
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
        SearchableDropdown(
          label: 'Ship To Code',
          items: _shipToLocations,
          selectedItem: widget.orderData['shipTo'],
          onChanged: (value) {
            widget.onUpdate('shipTo', value);
          },
          required: true,
        ),
        const SizedBox(height: 16),

        // Location
        SearchableDropdown(
          label: 'Location',
          items: _locations,
          selectedItem: widget.orderData['location'],
          onChanged: (value) {
            widget.onUpdate('location', value);
          },
          required: true,
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
              child: SearchableDropdown(
                label: 'Customer Name',
                items: _customers,
                selectedItem: widget.orderData['customer'],
                onChanged: (value) {
                  widget.onUpdate('customer', value);
                  if (value != null) {
                    // Auto-generate sale code based on customer name
                    final saleCode = 'SC-${value.substring(0, min(3, value.length)).toUpperCase()}';
                    _saleCodeController.text = saleCode;
                    widget.onUpdate('saleCode', saleCode);
                  }
                },
                required: true,
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
              child: SearchableDropdown(
                label: 'Ship To Code',
                items: _shipToLocations,
                selectedItem: widget.orderData['shipTo'],
                onChanged: (value) {
                  widget.onUpdate('shipTo', value);
                },
                required: true,
              ),
            ),
            const SizedBox(width: 16),
            // Location
            Expanded(
              child: SearchableDropdown(
                label: 'Location',
                items: _locations,
                selectedItem: widget.orderData['location'],
                onChanged: (value) {
                  widget.onUpdate('location', value);
                },
                required: true,
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

  // Helper for min function
  int min(int a, int b) {
    return a < b ? a : b;
  }
}