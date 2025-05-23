import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'order_detail_view.dart';
import 'edit_order_screen.dart';

class OrderTableView extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final ScrollController scrollController;
  final VoidCallback? onRefresh;

  const OrderTableView({
    super.key,
    required this.orders,
    required this.scrollController,
    this.onRefresh,
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
                        // Add Send for Approval button only for Open orders
                        if (order['status'] == 'Open')
                          IconButton(
                            icon: const Icon(Icons.check_circle, size: 20),
                            onPressed: () {
                              // Show send for approval confirmation
                              _showSendForApprovalDialog(context, order['id']);
                            },
                            tooltip: 'Send for Approval',
                            color: Colors.green,
                          ),
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
// Process reopening and then navigate to edit screen
Future<void> _reopenOrderAndNavigateToEdit(BuildContext context, Map<String, dynamic> order) async {
  // Store dialog context to ensure it can be closed even if parent context is disposed
  BuildContext? dialogContext;
  
  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      dialogContext = context;
      return AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: Colors.orange),
            const SizedBox(width: 16),
            Text('Reopening order ${order['id']}...'),
          ],
        ),
      );
    },
  );
  
  final apiService = ApiService();
  
  try {
    // Call the API to reopen the order
    final result = await apiService.reopenSalesOrder(order['id']);
    
    // Make sure to close the dialog
    if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
      Navigator.of(dialogContext!).pop();
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order reopened successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navigate to edit screen
    _navigateToEditScreen(context, order);
    
    // Refresh the orders list if callback is provided
    if (onRefresh != null) {
      onRefresh!();
    }
  } catch (e) {
    // Make sure to close the dialog
    if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
      Navigator.of(dialogContext!).pop();
    }
    
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to reopen order: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Navigate to edit screen
void _navigateToEditScreen(BuildContext context, Map<String, dynamic> order) {
  // Navigate to the edit screen passing only the order number
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditOrderScreen(orderNo: order['id']),
    ),
  ).then((_) {
    // Refresh the orders list when returning from edit screen
    if (onRefresh != null) {
      onRefresh!();
    }
  });
}
// Show edit order dialog with reopening confirmation


// Show edit order dialog
// Show edit order dialog with reopening confirmation
// Show edit order dialog with confirmation
// In order_list_view.dart and order_table_view.dart

void _showEditOrderDialog(BuildContext context, Map<String, dynamic> order) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit, color: Colors.orange),
          const SizedBox(width: 8),
          const Text('Edit Order'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Are you sure you want to edit? Editing will reopen the order.',
          ),
          const SizedBox(height: 12),
          Text(
            'Order ID: ${order['id']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            
            // Navigate using the named route
            Navigator.of(context).pushNamed(
              '/edit_order',
              arguments: order['id'],
            ).then((_) {
              // Refresh the orders list when returning
              if (onRefresh != null) {
                onRefresh!();
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Edit'),
        ),
      ],
    ),
  );
}
// Show send for approval confirmation dialog
  void _showSendForApprovalDialog(BuildContext context, String orderNo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Send for Approval'),
          ],
        ),
        content: Text(
          'Are you sure you want to send order $orderNo for approval? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendOrderForApproval(context, orderNo);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send for Approval'),
          ),
        ],
      ),
    );
  }  // Process the API call to send order for approval
  Future<void> _sendOrderForApproval(BuildContext context, String orderNo) async {
    // Store dialog context to ensure it can be closed even if parent context is disposed
    BuildContext? dialogContext;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogContext = context;
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(color: Colors.green),
              const SizedBox(width: 16),
              Text('Sending order $orderNo for approval...'),
            ],
          ),
        );
      },
    );
    
    final apiService = ApiService();
    
    // Call the API - the sendOrderForApproval method now returns a structured response
    final result = await apiService.sendOrderForApproval(orderNo);
    
    // Make sure to close the dialog - if dialogContext is null use normal context
    if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
      Navigator.of(dialogContext!).pop();
    } else if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Handle the result
    if (result['success'] == true) {
      // Show success message with API response message if available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Order sent for approval successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh the orders list if callback is provided
      if (onRefresh != null) {
        onRefresh!();
      }
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send order for approval: ${result['message'] ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}