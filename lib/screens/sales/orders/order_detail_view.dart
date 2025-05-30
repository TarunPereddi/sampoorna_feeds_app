import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';
import 'package:intl/intl.dart';

class OrderDetailView extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback? onEdit;

  const OrderDetailView({
    super.key,
    required this.order,
    this.onEdit,
  });

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _orderLines = [];
  String? _error;

 // Indian Rupee currency formatter
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadOrderLines();
  }  Future<void> _loadOrderLines() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get the order ID/Number - it's stored as 'id' in the transformed data
      final orderId = widget.order['id'] as String;
      
      debugPrint('Loading order lines for document: $orderId');
      
      // Fetch the order lines from the API
      final lines = await _apiService.getSalesOrderLines(orderId);
      
      debugPrint('Received ${lines.length} order lines');
      if (lines.isNotEmpty) {
        debugPrint('Sample line item fields: ${lines.first.keys.join(', ')}');
      }
      
      setState(() {
        _orderLines = lines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load order items: $e';
        _isLoading = false;
      });
      debugPrint('Error loading order lines: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order ${widget.order['id']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),

        // Order status
        Center(child: _buildStatusChip(widget.order['status'] as String)),
        const SizedBox(height: 16),

        // Order details table
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(2),
          },
          children: [
            _buildTableRow('Customer', widget.order['customerName']),
            _buildTableRow('Date', widget.order['date']),
            _buildTableRow('Amount', _currencyFormat.format(widget.order['amount'])),
            // Add delivery address information if available in the order data
            if (widget.order['address'] != null)
              _buildTableRow('Address', widget.order['address']),
          ],
        ),

        const SizedBox(height: 24),

        // Order items section
        const Text(
          'Order Items',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Order items content
        _buildOrderItemsContent(),

        const SizedBox(height: 24),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (widget.onEdit != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onEdit?.call();
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderItemsContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrderLines,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_orderLines.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No items found for this order.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      );
    }    return Column(
      children: _orderLines.map((item) {
        // Log the available fields for debugging
        debugPrint('Item fields: ${item.keys.join(', ')}');
        
        // Extract required fields based on API response fields
        final description = item['Description'] ?? 'No Description';
        
        // Handle quantity field
        final quantityValue = item['Quantity'] ?? item['Outstanding_Quantity'] ?? 0.0;
        final quantity = (quantityValue is num) 
            ? quantityValue.toStringAsFixed(2) 
            : double.tryParse(quantityValue.toString())?.toStringAsFixed(2) ?? '0.00';
        
        // Get unit of measure
        final unitOfMeasure = item['Unit_of_Measure_Code'] ?? '';
        
        // Handle price values - SalesLine API returns these fields
        final unitPrice = item['Unit_Price'] ?? 0.0;
        final lineAmount = item['Line_Amount'] ?? 0.0;
        
        // Format price values
        final mrpPrice = _formatCurrency(unitPrice);
        final totalMrpPrice = _formatCurrency(lineAmount);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          child: ListTile(
            title: Text(
              description,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Quantity: $quantity $unitOfMeasure',
              style: TextStyle(color: Colors.grey[700]),
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Unit: $mrpPrice',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: $totalMrpPrice',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Helper method to format currency values
  String _formatCurrency(dynamic value) {
    if (value == null) return '₹0.00';
    
    // Convert to double if it's not already
    double numValue;
    if (value is int) {
      numValue = value.toDouble();
    } else if (value is double) {
      numValue = value;
    } else if (value is String) {
      numValue = double.tryParse(value) ?? 0.0;
    } else {
      numValue = 0.0;
    }
    
    // Format with rupee symbol and proper decimal places
    return '₹${numValue.toStringAsFixed(2)}';
  }

  // Helper to build table rows for order details
  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Status indicator chip with color coding
  Widget _buildStatusChip(String status) {
    Color chipColor;

    switch (status) {
      case 'Completed':
        chipColor = Colors.green;
        break;
      case 'Processing':
        chipColor = Colors.blue;
        break;
      case 'Pending':
        chipColor = Colors.orange;
        break;
      case 'Cancelled':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}