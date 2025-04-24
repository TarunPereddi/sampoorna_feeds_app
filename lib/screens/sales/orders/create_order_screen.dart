import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  // Date controllers
  final TextEditingController _orderDateController = TextEditingController();
  final TextEditingController _deliveryDateController = TextEditingController();

  // Form field controllers
  final TextEditingController _saleCodeController = TextEditingController();

  // Selected values
  String? _selectedCustomer;
  String? _selectedShipTo;
  String? _selectedLocation;
  String? _selectedItem;
  String? _selectedUnitOfMeasure;

  // Item list for the order
  final List<Map<String, dynamic>> _orderItems = [];

  // Mock data for dropdowns
  final List<String> _customers = [
    'B.K. Enterprises',
    'Prajjawal Enterprises',
    'Agro Suppliers Ltd',
    'Farm Solutions Inc',
    'Green Agro Ltd',
  ];

  final List<String> _shipToLocations = [
    'Main Warehouse',
    'Delhi Branch',
    'Mumbai Branch',
    'Bangalore Branch',
  ];

  final List<String> _locations = [
    'Location 1',
    'Location 2',
    'Location 3',
    'Location 4',
  ];

  final List<String> _items = [
    'Item 1 - Feed Type A',
    'Item 2 - Protein Supplement',
    'Item 3 - Mineral Mix',
    'Item 4 - Growth Booster',
  ];

  final List<String> _unitsOfMeasure = [
    'Bag',
    'Kg',
    'Box',
    'Set',
  ];

  // Current item fields
  double _quantity = 0;
  double _mrp = 0;
  double _price = 0;
  double _totalAmount = 0;

  // Total order amount
  double _orderTotal = 0;

  @override
  void initState() {
    super.initState();
    // Set current date as default
    _orderDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Order',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Order Header
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
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Customer Dropdown
                            Expanded(
                              child: _buildSearchableDropdown(
                                label: 'Customer Name',
                                value: _selectedCustomer,
                                items: _customers,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedCustomer = value;
                                      // Auto-fill sale code based on customer
                                      _saleCodeController.text = 'SC-${_selectedCustomer!.substring(0, 3).toUpperCase()}';
                                    });
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
                              child: _buildSearchableDropdown(
                                label: 'Ship To Code',
                                value: _selectedShipTo,
                                items: _shipToLocations,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedShipTo = value;
                                  });
                                },
                                required: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Location
                            Expanded(
                              child: _buildSearchableDropdown(
                                label: 'Location',
                                value: _selectedLocation,
                                items: _locations,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedLocation = value;
                                  });
                                },
                                required: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Item Entry Form
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Row 1: Item and Unit of Measure
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Item No
                            Expanded(
                              flex: 2,
                              child: _buildSearchableDropdown(
                                label: 'Item No',
                                value: _selectedItem,
                                items: _items,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedItem = value;
                                    // Reset price and MRP as item changed
                                    _mrp = 100; // Mock MRP value
                                    _price = _mrp; // Default price is MRP
                                  });
                                },
                                required: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Unit of Measure
                            Expanded(
                              flex: 1,
                              child: _buildSearchableDropdown(
                                label: 'Unit of Measure',
                                value: _selectedUnitOfMeasure,
                                items: _unitsOfMeasure,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedUnitOfMeasure = value;
                                  });
                                },
                                required: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 2: Quantity, MRP, Price, Total
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quantity
                            Expanded(
                              child: _buildNumberField(
                                label: 'Qty',
                                onChanged: (value) {
                                  setState(() {
                                    _quantity = double.tryParse(value) ?? 0;
                                    _totalAmount = _quantity * _price;
                                  });
                                },
                                required: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // MRP
                            Expanded(
                              child: _buildNumberField(
                                label: 'MRP',
                                initialValue: _mrp.toString(),
                                enabled: false,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Price
                            Expanded(
                              child: _buildNumberField(
                                label: 'Price',
                                initialValue: _price.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _price = double.tryParse(value) ?? 0;
                                    _totalAmount = _quantity * _price;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Total Amount
                            Expanded(
                              child: _buildNumberField(
                                label: 'Total Amount',
                                initialValue: _totalAmount.toString(),
                                enabled: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Add Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _addItemToOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('ADD'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Items Table
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Items Table
                        _orderItems.isEmpty
                            ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No items added yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                            : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(const Color(0xFF2C5F2D).withOpacity(0.1)),
                            columns: const [
                              DataColumn(label: Text('S.N')),
                              DataColumn(label: Text('Item No.')),
                              DataColumn(label: Text('Unit of Measure')),
                              DataColumn(label: Text('Quantity')),
                              DataColumn(label: Text('MRP')),
                              DataColumn(label: Text('Unit Price')),
                              DataColumn(label: Text('Total Amt')),
                              DataColumn(label: Text('Action')),
                            ],
                            rows: List.generate(_orderItems.length, (index) {
                              final item = _orderItems[index];
                              return DataRow(
                                cells: [
                                  DataCell(Text('${index + 1}')),
                                  DataCell(Text(item['itemNo'])),
                                  DataCell(Text(item['unitOfMeasure'])),
                                  DataCell(Text(item['quantity'].toString())),
                                  DataCell(Text(item['mrp'].toString())),
                                  DataCell(Text(item['price'].toString())),
                                  DataCell(Text(item['totalAmount'].toString())),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _orderItems.removeAt(index);
                                          _calculateOrderTotal();
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),

                        // Total Amount
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                'Total Amount : ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₹${_orderTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C5F2D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C5F2D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
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

  Widget _buildNumberField({
    required String label,
    TextEditingController? controller,
    String? initialValue,
    bool enabled = true,
    bool required = false,
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
          initialValue: controller == null ? initialValue : null,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
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
          validator: required
              ? (value) => value == null || value.isEmpty ? 'This field is required' : null
              : null,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    bool required = false,
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
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildSearchableDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?)? onChanged,
    bool required = false,
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
        DropdownButtonFormField<String>(
          value: value,
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
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          validator: required
              ? (value) => value == null || value.isEmpty ? 'This field is required' : null
              : null,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 24,
          // Add searchable functionality in a production app
        ),
      ],
    );
  }

  void _addItemToOrder() {
    // Validate that required fields are filled
    if (_selectedItem == null || _selectedUnitOfMeasure == null || _quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required item fields')),
      );
      return;
    }

    // Add item to order
    setState(() {
      _orderItems.add({
        'itemNo': _selectedItem!,
        'unitOfMeasure': _selectedUnitOfMeasure!,
        'quantity': _quantity,
        'mrp': _mrp,
        'price': _price,
        'totalAmount': _totalAmount,
      });

      // Reset item form
      _selectedItem = null;
      _selectedUnitOfMeasure = null;
      _quantity = 0;
      _mrp = 0;
      _price = 0;
      _totalAmount = 0;

      // Recalculate order total
      _calculateOrderTotal();
    });
  }

  void _calculateOrderTotal() {
    double total = 0;
    for (var item in _orderItems) {
      total += item['totalAmount'] as double;
    }
    setState(() {
      _orderTotal = total;
    });
  }

  void _submitOrder() {
    if (_formKey.currentState!.validate()) {
      if (_orderItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item to the order')),
        );
        return;
      }

      // In a real app, this would send the order to the API
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order submitted successfully')),
      );

      // Navigate back to the orders screen
      Navigator.pop(context);
    }
  }
}