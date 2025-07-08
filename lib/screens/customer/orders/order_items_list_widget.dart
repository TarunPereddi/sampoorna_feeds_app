import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderItemsListWidget extends StatelessWidget {  final List<Map<String, dynamic>> items;
  final bool isSmallScreen;
  final Function(int) onRemoveItem;
  final Function(int)? onEditItem;
  final VoidCallback onClearAll;
  final double totalAmount;

  const OrderItemsListWidget({
    super.key,
    required this.items,
    required this.isSmallScreen,
    required this.onRemoveItem,
    this.onEditItem,
    required this.onClearAll,
    required this.totalAmount,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (items.isNotEmpty)
                  TextButton.icon(
                    onPressed: onClearAll,
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    label: const Text('Clear All', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Items List
            items.isEmpty
                ? _buildEmptyState()
                : isSmallScreen
                ? _buildItemsCards()
                : _buildItemsTable(),

            // Total Amount
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Total Amount: ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatCurrency(totalAmount),
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
    );
  }

  // Helper method to format currency values
  String _formatCurrency(double value) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return currencyFormat.format(value);
  }

  // Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No items added yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items from the form above',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cards layout for small screens
  Widget _buildItemsCards() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];        // Check if the item cannot be deleted
        final bool cannotDelete = item['cannotDelete'] == true;
        final String? errorReason = cannotDelete ? _extractErrorReason(item['itemDescription']) : null;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: cannotDelete ? Colors.red.shade50 : Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: cannotDelete ? Colors.red.shade200 : Colors.grey.shade200,
              width: cannotDelete ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['itemNo'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: cannotDelete ? Colors.red.shade800 : null,
                            ),
                          ),
                          Text(
                            item['itemDescription'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: cannotDelete ? Colors.red.shade600 : Colors.grey.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    cannotDelete
                      ? Tooltip(
                          message: 'Cannot delete: $errorReason',
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit button for existing items (items with lineNo)
                            if (onEditItem != null && item.containsKey('lineNo') && item['lineNo'] != null && item['lineNo'] > 0)
                              InkWell(
                                onTap: () => onEditItem!(index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit, color: Colors.blue.shade700, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              onPressed: () => onRemoveItem(index),
                            ),
                          ],
                        ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text('${item['quantity']} ${item['unitOfMeasure']}'),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Unit Price',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(_formatCurrency(item['price'] as double)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MRP',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(_formatCurrency(item['mrp'] as double)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),                        Text(
                          _formatCurrency(item['totalAmount'] as double),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // Table layout for larger screens
  Widget _buildItemsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(const Color(0xFF2C5F2D).withOpacity(0.1)),
        columns: const [
          DataColumn(label: Text('S.N')),
          DataColumn(label: Text('Item No.')),
          DataColumn(label: Text('Unit')),
          DataColumn(label: Text('Quantity')),
          DataColumn(label: Text('MRP')),
          DataColumn(label: Text('Unit Price')),
          DataColumn(label: Text('Total Amt')),
          DataColumn(label: Text('Action')),
        ],
        rows: List.generate(items.length, (index) {
          final item = items[index];
          return DataRow(
            cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text('${item['itemNo']} - ${item['itemDescription']}')),
              DataCell(Text(item['unitOfMeasure'] as String)),
              DataCell(Text(item['quantity'].toString())),              DataCell(Text(_formatCurrency(item['mrp'] as double))),
              DataCell(Text(_formatCurrency(item['price'] as double))),
              DataCell(Text(_formatCurrency(item['totalAmount'] as double))),
              DataCell(
                item['cannotDelete'] == true
                ? Tooltip(
                    message: 'Cannot delete: ${_extractErrorReason(item['itemDescription'])}',
                    child: Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit button for existing items (items with lineNo)
                      if (onEditItem != null && item.containsKey('lineNo') && item['lineNo'] != null && item['lineNo'] > 0)
                        InkWell(
                          onTap: () => onEditItem!(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, color: Colors.blue.shade700, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => onRemoveItem(index),
                      ),
                    ],
                  ),
              ),
            ],
          );
        }),
      ),
    );
  }
  
  // Extract error reason from item description
  String _extractErrorReason(String description) {
    final RegExp regex = RegExp(r'\((.*?)\)$');
    final match = regex.firstMatch(description);
    return match?.group(1) ?? 'Cannot Delete';
  }
}