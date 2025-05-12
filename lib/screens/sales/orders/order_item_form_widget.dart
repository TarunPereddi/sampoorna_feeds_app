import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/item.dart';
import '../../../models/item_unit_of_measure.dart'; // Import the new model
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import 'searchable_dropdown.dart';

class OrderItemFormWidget extends StatefulWidget {
  final bool isSmallScreen;
  final Function(Map<String, dynamic>) onAddItem;
  final String? locationCode;
  final String? customerPriceGroup; // Add this parameter

  const OrderItemFormWidget({
    super.key,
    required this.isSmallScreen,
    required this.onAddItem,
    this.locationCode,
    this.customerPriceGroup, // Add to constructor
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
  final TextEditingController _itemSearchController = TextEditingController();

  // API Service
  final ApiService _apiService = ApiService();

  // Selected values
  Item? _selectedItem;
  String? _selectedUnitOfMeasure;

  // Item values
  double _quantity = 0;
  double _mrp = 0;
  double _price = 0;
  double _totalAmount = 0;

  // Loading states
  bool _isLoadingItems = false;
  bool _isLoadingUoM = false;
  bool _isLoadingPrice = false; // New loading state for price fetching
  
  // Fallback units of measure for when API doesn't return any units
  final List<String> _fallbackUnitsOfMeasure = [
    'Bag',
    'Kg',
    'Box',
    '50 KG BAG',
    'Ton',
    'Packet',
    'Carton',
    'Drum',
    'Pallet',
  ];

  // Items list
  List<Item> _items = [];

  // Units of measure
  List<ItemUnitOfMeasure> _itemUnitsOfMeasure = [];
  
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

    // Fetch items if location is provided
    if (widget.locationCode != null && widget.locationCode!.isNotEmpty) {
      _fetchItems(widget.locationCode!);
    }

    // Add listener for item search
    _itemSearchController.addListener(() {
      if (_itemSearchController.text.length >= 3 && widget.locationCode != null) {
        _searchItems(_itemSearchController.text, widget.locationCode!);
      }
    });
  }

  @override
  void didUpdateWidget(OrderItemFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Fetch items if location changed
    if (widget.locationCode != oldWidget.locationCode && 
        widget.locationCode != null && 
        widget.locationCode!.isNotEmpty) {
      _fetchItems(widget.locationCode!);
    }
  }

  Future<void> _fetchItems(String locationCode) async {
    setState(() {
      _isLoadingItems = true;
    });

    try {
      final itemsData = await _apiService.getItems(locationCode: locationCode);
      setState(() {
        _items = itemsData.map((json) => Item.fromJson(json)).toList();
        _isLoadingItems = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingItems = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
      }
    }
  }

  Future<void> _searchItems(String query, String locationCode) async {
    setState(() {
      _isLoadingItems = true;
    });

    try {
      // In a real app, you might want to add a specific search endpoint in your API service
      // For now, we'll simulate filtering on the client side
      final itemsData = await _apiService.getItems(locationCode: locationCode);
      
      final filteredItems = itemsData.where((item) {
        final description = item['Description'] as String? ?? '';
        final itemNo = item['No'] as String? ?? '';
        
        return description.toLowerCase().contains(query.toLowerCase()) || 
               itemNo.toLowerCase().contains(query.toLowerCase());
      }).toList();
      
      setState(() {
        _items = filteredItems.map((json) => Item.fromJson(json)).toList();
        _isLoadingItems = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingItems = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching items: $e')),
        );
      }
    }
  }

  // New method to fetch units of measure for a specific item
  Future<void> _fetchUnitsOfMeasure(String itemNo) async {
    if (itemNo.isEmpty) return;
    
    setState(() {
      _isLoadingUoM = true;
      _itemUnitsOfMeasure = []; // Clear previous units
    });
    
    try {
      final uomData = await _apiService.getItemUnitsOfMeasure(itemNo);
      setState(() {
        _itemUnitsOfMeasure = uomData.map((json) => ItemUnitOfMeasure.fromJson(json)).toList();
        _isLoadingUoM = false;
        
        // If no UoM data returned from API, use the fallback list
        if (_itemUnitsOfMeasure.isEmpty) {
          return;
        }
        
        // If no UoM selected yet but we have units, set the default one
        if (_selectedUnitOfMeasure == null && _itemUnitsOfMeasure.isNotEmpty) {
          // Prefer to use the Sales Unit of Measure if it exists in the list
          if (_selectedItem != null && _selectedItem!.salesUnitOfMeasure != null) {
            final defaultUoMIndex = _itemUnitsOfMeasure.indexWhere(
              (uom) => uom.code == _selectedItem!.salesUnitOfMeasure,
            );
            
            if (defaultUoMIndex >= 0) {
              _selectedUnitOfMeasure = _itemUnitsOfMeasure[defaultUoMIndex].code;
            } else {
              _selectedUnitOfMeasure = _itemUnitsOfMeasure.first.code;
            }
          } else {
            _selectedUnitOfMeasure = _itemUnitsOfMeasure.first.code;
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingUoM = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading units of measure: $e')),
        );
      }
    }
  }
  
  // Method to handle item selection
  void _handleItemSelected(Item? item) {
    setState(() {
      _selectedItem = item;
      if (item != null) {
        // Set MRP value from the item
        _mrp = item.unitPrice;
        _mrpController.text = _mrp.toString();

        // Set default price as MRP initially
        _price = _mrp;
        _priceController.text = _price.toString();

        // Set default Unit of Measure from the item's sales unit of measure if available
        if (item.salesUnitOfMeasure != null) {
          _selectedUnitOfMeasure = item.salesUnitOfMeasure;
        } else if (item.description.contains('KG BAG')) {
          _selectedUnitOfMeasure = '50 KG BAG';
        } else {
          _selectedUnitOfMeasure = 'Kg';
        }
        
        // Calculate total if quantity is set
        _calculateItemTotal();
        
        // Fetch available Units of Measure
        _fetchUnitsOfMeasure(item.no);

        // Fetch sales price if we have all the required information
        if (_selectedUnitOfMeasure != null && 
            widget.locationCode != null && 
            widget.locationCode!.isNotEmpty &&
            widget.customerPriceGroup != null && 
            widget.customerPriceGroup!.isNotEmpty) {
          _fetchSalesPrice();
        }
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _mrpController.dispose();
    _priceController.dispose();
    _totalAmountController.dispose();
    _itemSearchController.dispose();
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
      _itemSearchController.clear();
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
    
    // Price validation removed - allowing any price including zero

    final Map<String, dynamic> newItem = {
      'itemNo': _selectedItem!.no,
      'itemDescription': _selectedItem!.description,
      'unitOfMeasure': _selectedUnitOfMeasure!,
      'quantity': _quantity,
      'mrp': _mrp,
      'price': _price,
      'totalAmount': _totalAmount,
    };

    widget.onAddItem(newItem);
    _resetItemForm();
  }

  // Fetch sales price based on customer price group, location, and UOM
  Future<void> _fetchSalesPrice() async {
    if (!mounted) return; // Check if widget is still mounted
    
    if (_selectedItem == null || _selectedUnitOfMeasure == null || 
        widget.locationCode == null || widget.locationCode!.isEmpty ||
        widget.customerPriceGroup == null || widget.customerPriceGroup!.isEmpty) {
      return;
    }
    
    setState(() {
      _isLoadingPrice = true; // Start loading
    });
    
    try {
      print('Fetching price for: Item=${_selectedItem!.no}, UoM=$_selectedUnitOfMeasure, Location=${widget.locationCode}, PriceGroup=${widget.customerPriceGroup}');
      
      final priceData = await _apiService.getSalesPrice(
        itemNo: _selectedItem!.no,
        customerPriceGroup: widget.customerPriceGroup!,
        locationCode: widget.locationCode!,
        unitOfMeasure: _selectedUnitOfMeasure!,
      );
      
      if (!mounted) return; // Check again after async operation
      
      if (priceData != null && priceData.containsKey('Unit_Price')) {
        setState(() {
          // Get the price from the API response
          if (priceData['Unit_Price'] != null) {
            _price = priceData['Unit_Price'] is int
                ? (priceData['Unit_Price'] as int).toDouble()
                : priceData['Unit_Price'] as double;
            _priceController.text = _price.toString();
          }
          
          // Get the MRP from the API response
          if (priceData['MRP'] != null) {
            _mrp = priceData['MRP'] is int
                ? (priceData['MRP'] as int).toDouble()
                : priceData['MRP'] as double;
            _mrpController.text = _mrp.toString();
          }
          
          // Recalculate total amount
          _calculateItemTotal();
          _isLoadingPrice = false;
        });
      } else {
        if (!mounted) return; // Check again
        
        setState(() {
          _isLoadingPrice = false;
        });
        
        // Show error message if price data is not found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot get price. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return; // Check again
      
      print('Error fetching sales price: $e');
      
      setState(() {
        _isLoadingPrice = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot get price: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Set default price when sales price API doesn't return valid data
  void _setDefaultPrice() {
    // If we have an MRP, use that
    if (_mrp > 0) {
      _price = _mrp;
    } else {
      // Otherwise use a default value
      _price = 1000.0; // Default price as specified
    }
    _priceController.text = _price.toString();
    _calculateItemTotal();
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

              // Check if location is selected
              if (widget.locationCode == null || widget.locationCode!.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Please select a location in the order form to view available items',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              if (widget.locationCode != null && widget.locationCode!.isNotEmpty)
                // Layout based on screen size
                widget.isSmallScreen
                    ? _buildSmallScreenLayout()
                    : _buildLargeScreenLayout(),

              const SizedBox(height: 16),

              // Add Button
              if (widget.locationCode != null && widget.locationCode!.isNotEmpty)
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
        _isLoadingItems
            ? const Center(child: CircularProgressIndicator())
            : SearchableDropdown<Item>(
                label: 'Item',
                items: _items,
                selectedItem: _selectedItem,
                onChanged: _handleItemSelected,
                required: true,
                displayStringForItem: (Item item) => '${item.no} - ${item.description}',
                searchController: _itemSearchController,
                onSearchTextChanged: (String query) {
                  // Search handled by listener in initState
                },
              ),
        const SizedBox(height: 16),

        // Unit of Measure
        _buildUnitOfMeasureDropdown(),
        const SizedBox(height: 16),

        // Quantity
        _buildNumberField(
          label: 'Quantity',
          controller: _quantityController,
          required: true,
        ),
        const SizedBox(height: 16),

        // MRP - now non-editable with loading state
        _buildNumberField(
          label: 'MRP',
          controller: _mrpController,
          enabled: false,
          isLoading: _isLoadingPrice,
        ),
        const SizedBox(height: 16),

        // Unit Price - now non-editable with loading state
        _buildNumberField(
          label: 'Unit Price',
          controller: _priceController,
          enabled: false,
          isLoading: _isLoadingPrice,
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
              child: _isLoadingItems
                  ? const Center(child: CircularProgressIndicator())
                  : SearchableDropdown<Item>(
                      label: 'Item',
                      items: _items,
                      selectedItem: _selectedItem,
                      onChanged: _handleItemSelected,
                      required: true,
                      displayStringForItem: (Item item) => '${item.no} - ${item.description}',
                      searchController: _itemSearchController,
                      onSearchTextChanged: (String query) {
                        // Search handled by listener in initState
                      },
                    ),
            ),
            const SizedBox(width: 16),
            // Unit of Measure
            Expanded(
              flex: 1,
              child: _buildUnitOfMeasureDropdown(),
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
            // MRP - now non-editable with loading state
            Expanded(
              child: _buildNumberField(
                label: 'MRP',
                controller: _mrpController,
                enabled: false,
                isLoading: _isLoadingPrice,
              ),
            ),
            const SizedBox(width: 16),
            // Unit Price - now non-editable with loading state
            Expanded(
              child: _buildNumberField(
                label: 'Unit Price',
                controller: _priceController,
                enabled: false,
                isLoading: _isLoadingPrice,
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
    bool isLoading = false,
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
        Stack(
          children: [
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
                prefixText: label == 'Total Amount' || label == 'MRP' || label == 'Unit Price' ? '₹' : null,
              ),
              validator: required
                  ? (value) => value == null || value.isEmpty ? 'This field is required' : null
                  : null,
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.7),
                  child: const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
            SizedBox(height: 12),
            Text('Note: Items are filtered based on the selected location.'),
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
  
  // Helper method to build UoM dropdown
  Widget _buildUnitOfMeasureDropdown() {
    // Show loading indicator if fetching UoM
    if (_isLoadingUoM) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unit of Measure*',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    
    // If we have UoM data from the API, use it
    if (_itemUnitsOfMeasure.isNotEmpty) {
      final uomCodes = _itemUnitsOfMeasure.map((uom) => uom.code).toList();
      return SearchableDropdown<String>(
        label: 'Unit of Measure',
        items: uomCodes,
        selectedItem: _selectedUnitOfMeasure,
        onChanged: (value) {
          if (value != null && value != _selectedUnitOfMeasure) {
            setState(() {
              _selectedUnitOfMeasure = value;
              
              // Clear price/MRP info for the new UoM until we fetch it
              _priceController.text = "Fetching...";
              _mrpController.text = "Fetching...";
              
              // Fetch sales price when UoM changes
              if (_selectedItem != null) {
                _fetchSalesPrice();
              }
            });
          }
        },
        required: true,
        displayStringForItem: (String uom) => uom,
      );
    }
    
    // Otherwise use the fallback list
    return SearchableDropdown<String>(
      label: 'Unit of Measure',
      items: _fallbackUnitsOfMeasure,
      selectedItem: _selectedUnitOfMeasure,
      onChanged: (value) {
        if (value != null && value != _selectedUnitOfMeasure) {
          setState(() {
            _selectedUnitOfMeasure = value;
            
            // Clear price/MRP info for the new UoM until we fetch it
            _priceController.text = "Fetching...";
            _mrpController.text = "Fetching...";
            
            // Fetch sales price when UoM changes
            if (_selectedItem != null) {
              _fetchSalesPrice();
            }
          });
        }
      },
      required: true,
      displayStringForItem: (String uom) => uom,
    );
  }
}