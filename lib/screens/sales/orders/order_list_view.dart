import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'order_detail_view.dart';

class OrderListView extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final ScrollController scrollController;
  final VoidCallback? onRefresh;

  const OrderListView({
    super.key,
    required this.orders,
    required this.scrollController,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order['id'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _buildStatusChip(order['status'] as String),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            order['customerName'] as String,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            order['date'] as String,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          order['amount'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Add Send for Approval button only for Open orders
                    if (order['status'] == 'Open')
                      TextButton.icon(
                        onPressed: () {
                          // Show send for approval confirmation
                          _showSendForApprovalDialog(context, order['id']);
                        },
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Send for Approval'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    if (order['status'] == 'Open')
                      const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        // View order details
                        _showViewOrderDetails(context, order);
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('View'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        // Edit order
                        _showEditOrderDialog(context, order);
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
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

  // Show order details dialog
  void _showViewOrderDetails(BuildContext context, Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                controller: scrollController,
                children: [
                  OrderDetailView(
                    order: order,
                    onEdit: () => _showEditOrderDialog(context, order),
                  ),
                ],
              ),
            );
          },
        );
      },
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

  // In OrderListView and OrderTableView

// Show edit order dialog
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
            'Edit functionality is coming soon!',
          ),
          const SizedBox(height: 12),
          Text(
            'Order ID: ${order['id']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Just close the dialog
            
            // Show a message about the feature being under development
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Edit functionality is under development'),
                backgroundColor: Colors.blue,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

}