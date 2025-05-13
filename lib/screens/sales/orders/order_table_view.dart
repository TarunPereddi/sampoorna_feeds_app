import 'package:flutter/material.dart';
import 'order_detail_view.dart';

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
                  DataCell(_buildStatusChip(order['status'] as String)),                  DataCell(
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
          child: SingleChildScrollView(
            child: OrderDetailView(
              order: order,
              onEdit: () {
                Navigator.pop(context);
                _showEditOrderDialog(context, order);
              },
            ),
          ),
        ),
      ),
    );
  }
  // This method is no longer needed since we're using OrderDetailView

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
  // Print dialog removed as per requirements
}