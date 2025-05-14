import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/item.dart';
import '../../../models/item_unit_of_measure.dart'; // Import the new model
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import 'searchable_dropdown.dart';
import 'item_selection_screen.dart';
import 'uom_selection_screen.dart';

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
  bool _isLoadingPrice = false;
  
  // Control flags to prevent stack overflow
  bool _isUomDialogOpen = false;
  bool _skipPriceUpdate = false;

  bool _isPriceAvailable = false;

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
  
  // Reset form if location changed
  if (widget.locationCode != oldWidget.locationCode) {
    _resetItemForm(); // Add this line to reset the form
    
    // Fetch items if location changed and not empty
    if (widget.locationCode != null && widget.locationCode!.isNotEmpty) {
      _fetchItems(widget.locationCode!);
    }
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
      
      List<ItemUnitOfMeasure> loadedUnits = uomData.map((json) => ItemUnitOfMeasure.fromJson(json)).toList();
      String? newUnitOfMeasure;
      
      // Determine the default UoM without immediately setting state
      if (loadedUnits.isNotEmpty) {
        // Prefer to use the Sales Unit of Measure if it exists in the list
        if (_selectedItem != null && _selectedItem!.salesUnitOfMeasure != null) {
          final defaultUoMIndex = loadedUnits.indexWhere(
            (uom) => uom.code == _selectedItem!.salesUnitOfMeasure,
          );
          
          if (defaultUoMIndex >= 0) {
            newUnitOfMeasure = loadedUnits[defaultUoMIndex].code;
          } else {
            newUnitOfMeasure = loadedUnits.first.code;
          }
        } else {
          newUnitOfMeasure = loadedUnits.first.code;
        }
      }
      
      // Set state once with all changes
      setState(() {
        _itemUnitsOfMeasure = loadedUnits;
        _isLoadingUoM = false;
        if (newUnitOfMeasure != null && _selectedUnitOfMeasure == null) {
          _selectedUnitOfMeasure = newUnitOfMeasure;
        }
      });
      
      // Only fetch price AFTER setState is complete, and if we have all required info
      if (_selectedUnitOfMeasure != null && 
          widget.locationCode != null && 
          widget.locationCode!.isNotEmpty &&
          widget.customerPriceGroup != null && 
          widget.customerPriceGroup!.isNotEmpty) {
        await _fetchSalesPrice();
      }
      
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
    if (item == null) return;
    
    // Store the previous item to check if we're selecting a new item
    Item? previousItem = _selectedItem;
    String? previousUoM = _selectedUnitOfMeasure;
    
    setState(() {
      _selectedItem = item;
      
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

      _isPriceAvailable = false;
    });
    
    // Calculate total if quantity is set
    _calculateItemTotal();
    
    // Fetch UoM only if the item changed to avoid recursion
    if (previousItem == null || previousItem.no != item.no) {
      _fetchUnitsOfMeasure(item.no);
    } 
    // If only the UoM changed but we have the same item, fetch price directly
    else if (_selectedUnitOfMeasure != previousUoM) {
      _fetchSalesPrice();
    }
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
    double quantity = 0;
    double price = 0;
    
    // Safely parse quantity
    try {
      if (_quantityController.text.isNotEmpty) {
        quantity = double.tryParse(_quantityController.text) ?? 0;
      }
    } catch (e) {
      quantity = 0;
    }
    
    // Safely parse price
    try {
      if (_priceController.text.isNotEmpty && _priceController.text != "Fetching...") {
        price = double.tryParse(_priceController.text) ?? 0;
      }
    } catch (e) {
      price = 0;
    }
    
    setState(() {
      _quantity = quantity;
      _price = price;
      _totalAmount = _quantity * _price;
      _totalAmountController.text = _totalAmount.toStringAsFixed(2);
    });
    
    debugPrint('Calculated total: $_totalAmount from quantity: $_quantity and price: $_price');
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
    
    // Add this check for price availability
  if (!_isPriceAvailable || _price <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Price not available for this item. Please select another item.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

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
      _isPriceAvailable = false;
    });
    
    try {
      debugPrint('Fetching price for: Item=${_selectedItem!.no}, UoM=$_selectedUnitOfMeasure, Location=${widget.locationCode}, PriceGroup=${widget.customerPriceGroup}');
      
      final priceData = await _apiService.getSalesPrice(
        itemNo: _selectedItem!.no,
        customerPriceGroup: widget.customerPriceGroup!,
        locationCode: widget.locationCode!,
        unitOfMeasure: _selectedUnitOfMeasure!,
      );
      
      if (!mounted) return; // Check again after async operation
      
      if (priceData != null && priceData.isNotEmpty && priceData.containsKey('Unit_Price')) {
        // Get the price from the API response
        double newPrice = 0;
        if (priceData['Unit_Price'] != null) {
          newPrice = priceData['Unit_Price'] is int
              ? (priceData['Unit_Price'] as int).toDouble()
              : priceData['Unit_Price'] as double;
        }
        
        // Get the MRP from the API response
        double newMrp = 0;
        if (priceData['MRP'] != null) {
          newMrp = priceData['MRP'] is int
              ? (priceData['MRP'] as int).toDouble()
              : priceData['MRP'] as double;
        }
        
        setState(() {
          _price = newPrice;
          _priceController.text = _price.toString();
          
          _mrp = newMrp;
          _mrpController.text = _mrp.toString();
          
          _isLoadingPrice = false;
                  _isPriceAvailable = true; // Set price as available

        });
        
        // Always recalculate after price changes, outside of setState
        _calculateItemTotal();
        
      } else {
         setState(() {
        _isLoadingPrice = false;
        _isPriceAvailable = false;
        _price = 0;
        _priceController.text = '0.0';
        _mrp = 0;
        _mrpController.text = '0.0';
      });
        
        // Recalculate with default prices
        _calculateItemTotal();
        
        // Show message about using default price
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
             content: Text('Price not available for this item. Please select another item.'),
          backgroundColor: Colors.red,
          ),
        );
        setState(() {
        _selectedItem = null;
        _selectedUnitOfMeasure = null;
        _itemSearchController.clear();
      });
      }
    } catch (e) {
      if (!mounted) return; // Check again
      
      debugPrint('Error fetching sales price: $e');
      
      setState(() {
        _selectedItem = null;
      _selectedUnitOfMeasure = null;
      _itemSearchController.clear();
      _isPriceAvailable = false;
      });
      
      // Recalculate with default prices
      _calculateItemTotal();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Price fetch error. Using default: $e'),
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

  // Add this helper method to show UoM selection directly in a dialog
  Future<String?> _showUomSelectionDialog(List<String> uoms, String? currentUom) async {
    String? selectedValue = currentUom;
    String filterText = '';
    List<String> filteredUoms = List.from(uoms);
    
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void filterUoms(String query) {
              setState(() {
                if (query.isEmpty) {
                  filteredUoms = List.from(uoms);
                } else {
                  filteredUoms = uoms.where(
                    (uom) => uom.toLowerCase().contains(query.toLowerCase())
                  ).toList();
                }
              });
            }
            
            return AlertDialog(
              title: const Text('Select Unit of Measure'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search field
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search units...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                      onChanged: filterUoms,
                    ),
                    const SizedBox(height: 8),
                    
                    // UoM list
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredUoms.length,
                        itemBuilder: (context, index) {
                          final uom = filteredUoms[index];
                          final isSelected = uom == selectedValue;
                          
                          return ListTile(
                            title: Text(uom),
                            tileColor: isSelected ? Colors.green.withOpacity(0.1) : null,
                            onTap: () {
                              Navigator.of(context).pop(uom);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
              ],
              contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            );
          },
        );
      },
    );
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
              if (widget.locationCode == null || widget.locationCode!.isEmpty || 
                widget.customerPriceGroup == null || widget.customerPriceGroup!.isEmpty)
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
                        'Please select a customer and location in the order form to view available items',
                        style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              if (widget.locationCode != null && widget.locationCode!.isNotEmpty &&
                widget.customerPriceGroup != null && widget.customerPriceGroup!.isNotEmpty)
              // Layout based on screen size
              widget.isSmallScreen
                    ? _buildSmallScreenLayout()
                    : _buildLargeScreenLayout(),

              const SizedBox(height: 16),

              // Add Button
              if (widget.locationCode != null && widget.locationCode!.isNotEmpty &&
                widget.customerPriceGroup != null && widget.customerPriceGroup!.isNotEmpty)
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
            : _buildItemSelection(),
        const SizedBox(height: 16),

        // Unit of Measure
        _buildUomSelection(),
        const SizedBox(height: 16),

        // Quantity
        _buildNumberField(
          label: 'Quantity',
          controller: _quantityController,
          required: true,
        ),
        const SizedBox(height: 16),

        // MRP - now non-editable with loading state
        _buildReadOnlyField(
          label: 'MRP',
          value: _mrpController.text,
          isLoading: _isLoadingPrice,
        ),
        const SizedBox(height: 16),

        // Unit Price - now non-editable with loading state
        _buildReadOnlyField(
          label: 'Unit Price',
          value: _priceController.text,
          isLoading: _isLoadingPrice,
        ),
        const SizedBox(height: 16),

        // Total Amount
        _buildReadOnlyField(
          label: 'Total Amount',
          value: _totalAmountController.text,
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
                  : _buildItemSelection(),
            ),
            const SizedBox(width: 16),
            // Unit of Measure
            Expanded(
              flex: 1,
              child: _buildUomSelection(),
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
              child: _buildReadOnlyField(
                label: 'MRP',
                value: _mrpController.text,
                isLoading: _isLoadingPrice,
              ),
            ),
            const SizedBox(width: 16),
            // Unit Price - now non-editable with loading state
            Expanded(
              child: _buildReadOnlyField(
                label: 'Unit Price',
                value: _priceController.text,
                isLoading: _isLoadingPrice,
              ),
            ),
            const SizedBox(width: 16),
            // Total Amount
            Expanded(
              child: _buildReadOnlyField(
                label: 'Total Amount',
                value: _totalAmountController.text,
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

  // Build a read-only field for displaying prices and amounts
  Widget _buildReadOnlyField({
    required String label,
    required String value,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label.contains('Price') || label.contains('MRP') || label.contains('Amount') 
                    ? '₹$value' 
                    : value,
              ),
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
  
  // Build UoM selection widget
  Widget _buildUomSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unit of Measure*',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            // Prevent stack overflow by blocking multiple operations
            if (_isUomDialogOpen || _isLoadingPrice) {
              return;
            }
            
            if (_selectedItem == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select an item first')),
              );
              return;
            }
            
            // Set flag to indicate dialog is open
            _isUomDialogOpen = true;
            
            // Prepare the list of UoMs to show
            final List<String> uomList;
            if (_itemUnitsOfMeasure.isNotEmpty) {
              // Use API data if available
              uomList = _itemUnitsOfMeasure.map((uom) => uom.code).toList();
            } else {
              // Fall back to default list if API didn't return any
              uomList = _fallbackUnitsOfMeasure;
            }
            
            // Show dialog instead of navigating to a screen
            final selectedUom = await _showUomSelectionDialog(uomList, _selectedUnitOfMeasure);
            
            // Reset dialog flag
            _isUomDialogOpen = false;
            
            if (selectedUom != null && selectedUom != _selectedUnitOfMeasure) {
              setState(() {
                _selectedUnitOfMeasure = selectedUom;
                
                // Mark fields as loading
                _mrpController.text = "Fetching...";
                _priceController.text = "Fetching...";
              });
              
              // Important: Call async method outside setState
              if (_selectedItem != null) {
                await _fetchSalesPrice();
              }
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _selectedUnitOfMeasure != null
                      ? Text(_selectedUnitOfMeasure!)
                      : Text(
                          'Select unit...',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Build Item selection widget
  Widget _buildItemSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item*',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            if (widget.locationCode == null || widget.locationCode!.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a location first')),
              );
              return;
            }
            
            final selectedItem = await Navigator.push<Item>(
              context,
              MaterialPageRoute(
                builder: (context) => ItemSelectionScreen(
                  locationCode: widget.locationCode!,
                  initialSelection: _selectedItem,
                  initialSearchText: _itemSearchController.text,
                ),
              ),
            );
            
            if (selectedItem != null) {
              _handleItemSelected(selectedItem);
              // Update the search controller for future reference
              _itemSearchController.text = selectedItem.description;
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _selectedItem != null
                      ? Text('${_selectedItem!.no} - ${_selectedItem!.description}')
                      : Text(
                          'Select item...',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }
}