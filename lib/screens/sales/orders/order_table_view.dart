import 'package:flutter/material.dart';

class OrderTableView extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final ScrollController scrollController;

  const OrderTableView({
    super.key,
    required this.orders,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView(
        controller: scrollController,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFE8F5E9)),
            columns: const [
              DataColumn(label: Text('Order ID')),
              DataColumn(label: Text('Customer')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: orders.map((order) {
              return DataRow(
                cells: [
                  DataCell(Text(order['id'] as String)),
                  DataCell(Text(order['customerName'] as String)),
                  DataCell(Text(order['date'] as String)),
                  DataCell(Text(order['amount'] as String)),
                  DataCell(_buildStatusChip(order['status'] as String)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 20),
                          onPressed: () {
                            // View order details
                            _showViewOrderDialog(context, order);
                          },
                          tooltip: 'View Details',
                          color: Colors.blue,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            // Edit order
                            _showEditOrderDialog(context, order);
                          },
                          tooltip: 'Edit Order',
                          color: Colors.orange,
                        ),
                        IconButton(
                          icon: const Icon(Icons.print, size: 20),
                          onPressed: () {
                            // Print order
                            _showPrintDialog(context, order);
                          },
                          tooltip: 'Print Order',
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
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

  // Show view order dialog
  void _showViewOrderDialog(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Details: ${order['id']}',
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
              const SizedBox(height: 12),

              // Status
              Row(
                children: [
                  const Text(
                    'Status: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildStatusChip(order['status'] as String),
                ],
              ),
              const SizedBox(height: 16),

              // Order Info Table
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(2),
                },
                border: TableBorder.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                children: [
                  _buildTableRow('Customer', order['customerName']),
                  _buildTableRow('Date', order['date']),
                  _buildTableRow('Amount', order['amount']),
                  _buildTableRow('Delivery', 'Scheduled for delivery'),
                  _buildTableRow('Payment', 'Completed'),
                ],
              ),

              const SizedBox(height: 24),

              // Mock Order Items
              const Text(
                'Order Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('Item')),
                      DataColumn(label: Text('Qty')),
                      DataColumn(label: Text('Price')),
                      DataColumn(label: Text('Total')),
                    ],
                    rows: [
                      DataRow(cells: [
                        const DataCell(Text('Protein Supplement')),
                        const DataCell(Text('2')),
                        const DataCell(Text('₹4,000')),
                        const DataCell(Text('₹8,000')),
                      ]),
                      DataRow(cells: [
                        const DataCell(Text('Chicken Feed Type A')),
                        const DataCell(Text('5')),
                        const DataCell(Text('₹3,100')),
                        const DataCell(Text('₹15,500')),
                      ]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showPrintDialog(context, order);
                    },
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build table rows for order details
  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value),
        ),
      ],
    );
  }

  // Show edit order dialog
  void _showEditOrderDialog(BuildContext context, Map<String, dynamic> order) {
    // This would be implemented to edit the order
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Order'),
        content: const Text(
            'Order editing functionality will be implemented with API integration.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Show print dialog
  void _showPrintDialog(BuildContext context, Map<String, dynamic> order) {
    // This would be implemented to print the order
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Print Order'),
        content: const Text(
            'Printing functionality will be implemented with API integration.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}