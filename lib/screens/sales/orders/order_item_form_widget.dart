import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'searchable_dropdown.dart';

class OrderItemFormWidget extends StatefulWidget {
  final bool isSmallScreen;
  final Function(Map<String, dynamic>) onAddItem;

  const OrderItemFormWidget({
    super.key,
    required this.isSmallScreen,
    required this.onAddItem,
  });

  @override
  State<OrderItemFormWidget> createState() => _OrderItemFormWidgetState();
}

class _OrderItemFormWidgetState extends State<OrderItemFormWidget> {
  // Form key for validation
  final _itemFormKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _mrpController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();

  // Selected values
  String? _selectedItem;
  String? _selectedUnitOfMeasure;

  // Item values
  double _quantity = 0;
  double _mrp = 0;
  double _price = 0;
  double _totalAmount = 0;

  // Mock data for dropdowns
  final List<String> _items = [
    'Item 1 - Feed Type A',
    'Item 2 - Protein Supplement',
    'Item 3 - Mineral Mix',
    'Item 4 - Growth Booster',
    'Item 5 - Layer Feed Premium',
    'Item 6 - Broiler Starter Mix',
    'Item 7 - Fish Feed Pellets',
    'Item 8 - Cattle Feed Mix',
    'Item 9 - Organic Supplement',
    'Item 10 - Vitamin Boost',
    'Item 11 - Herbal Supplement',
    'Item 12 - Goat Feed Mix',
  ];

  final List<String> _unitsOfMeasure = [
    'Bag',
    'Kg',
    'Box',
    'Set',
    'Ton',
    'Packet',
    'Carton',
    'Drum',
    'Pallet',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with default values
    _mrpController.text = '0.0';
    _priceController.text = '0.0';
    _totalAmountController.text = '0.0';

    // Add listeners to recalculate total amount
    _quantityController.addListener(_calculateItemTotal);
    _priceController.addListener(_calculateItemTotal);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _mrpController.dispose();
    _priceController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  // Calculate total for the current item
  void _calculateItemTotal() {
    if (_quantityController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      final double quantity = double.tryParse(_quantityController.text) ?? 0;
      final double price = double.tryParse(_priceController.text) ?? 0;
      setState(() {
        _quantity = quantity;
        _price = price;
        _totalAmount = _quantity * _price;
        _totalAmountController.text = _totalAmount.toStringAsFixed(2);
      });
    }
  }

  // Reset the item form
  void _resetItemForm() {
    setState(() {
      _selectedItem = null;
      _selectedUnitOfMeasure = null;
      _quantityController.text = '';
      _mrpController.text = '0.0';
      _priceController.text = '0.0';
      _totalAmountController.text = '0.0';
      _quantity = 0;
      _mrp = 0;
      _price = 0;
      _totalAmount = 0;
    });
  }

  // Add the current item to the order
  void _addItemToOrder() {
    if (!_itemFormKey.currentState!.validate()) {
      return;
    }

    if (_selectedItem == null || _selectedUnitOfMeasure == null || _quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required item fields')),
      );
      return;
    }

    final Map<String, dynamic> newItem = {
      'itemNo': _selectedItem!,
      'unitOfMeasure': _selectedUnitOfMeasure!,
      'quantity': _quantity,
      'mrp': _mrp,
      'price': _price,
      'totalAmount': _totalAmount,
    };

    widget.onAddItem(newItem);
    _resetItemForm();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _itemFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    tooltip: 'Item Information',
                    onPressed: () {
                      _showItemInfoDialog();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Layout based on screen size
              widget.isSmallScreen
                  ? _buildSmallScreenLayout()
                  : _buildLargeScreenLayout(),

              const SizedBox(height: 16),

              // Add Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _addItemToOrder,
                  icon: const Icon(Icons.add),
                  label: const Text('ADD ITEM'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Layout for small screens
  Widget _buildSmallScreenLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item Selection
        SearchableDropdown(
          label: 'Item No',
          items: _items,
          selectedItem: _selectedItem,
          onChanged: (value) {
            setState(() {
              _selectedItem = value;
              if (value != null) {
                // Set mock MRP value - would be replaced with API data
                _mrp = 100.0;
                _mrpController.text = _mrp.toString();

                // Set default price as MRP
                _price = _mrp;
                _priceController.text = _price.toString();

                // Calculate total if quantity is set
                _calculateItemTotal();
              }
            });
          },
          required: true,
        ),
        const SizedBox(height: 16),

        // Unit of Measure
        SearchableDropdown(
          label: 'Unit of Measure',
          items: _unitsOfMeasure,
          selectedItem: _selectedUnitOfMeasure,
          onChanged: (value) {
            setState(() {
              _selectedUnitOfMeasure = value;
            });
          },
          required: true,
        ),
        const SizedBox(height: 16),

        // Quantity
        _buildNumberField(
          label: 'Quantity',
          controller: _quantityController,
          required: true,
        ),
        const SizedBox(height: 16),

        // MRP
        _buildNumberField(
          label: 'MRP',
          controller: _mrpController,
          enabled: false,
        ),
        const SizedBox(height: 16),

        // Price
        _buildNumberField(
          label: 'Price',
          controller: _priceController,
        ),
        const SizedBox(height: 16),

        // Total Amount
        _buildNumberField(
          label: 'Total Amount',
          controller: _totalAmountController,
          enabled: false,
        ),
      ],
    );
  }

  // Layout for larger screens
  Widget _buildLargeScreenLayout() {
    return Column(
      children: [
        // Row 1: Item and Unit of Measure
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item No
            Expanded(
              flex: 2,
              child: SearchableDropdown(
                label: 'Item No',
                items: _items,
                selectedItem: _selectedItem,
                onChanged: (value) {
                  setState(() {
                    _selectedItem = value;
                    if (value != null) {
                      // Set mock MRP value - would be replaced with API data
                      _mrp = 100.0;
                      _mrpController.text = _mrp.toString();

                      // Set default price as MRP
                      _price = _mrp;
                      _priceController.text = _price.toString();

                      // Calculate total if quantity is set
                      _calculateItemTotal();
                    }
                  });
                },
                required: true,
              ),
            ),
            const SizedBox(width: 16),
            // Unit of Measure
            Expanded(
              flex: 1,
              child: SearchableDropdown(
                label: 'Unit of Measure',
                items: _unitsOfMeasure,
                selectedItem: _selectedUnitOfMeasure,
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
                label: 'Quantity',
                controller: _quantityController,
                required: true,
              ),
            ),
            const SizedBox(width: 16),
            // MRP
            Expanded(
              child: _buildNumberField(
                label: 'MRP',
                controller: _mrpController,
                enabled: false,
              ),
            ),
            const SizedBox(width: 16),
            // Price
            Expanded(
              child: _buildNumberField(
                label: 'Price',
                controller: _priceController,
              ),
            ),
            const SizedBox(width: 16),
            // Total Amount
            Expanded(
              child: _buildNumberField(
                label: 'Total Amount',
                controller: _totalAmountController,
                enabled: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build a number input field
  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
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
        ),
      ],
    );
  }

  // Show item information dialog
  void _showItemInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Select an item from the dropdown list.'),
            Text('• Specify quantity and unit of measure.'),
            Text('• MRP is auto-filled based on the selected item.'),
            Text('• You can adjust the price if different from MRP.'),
            Text('• Total amount is automatically calculated.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}