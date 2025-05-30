import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'order_detail_view.dart';

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
                  DataCell(_buildStatusChip(order['status'] as String)),
                  DataCell(_buildActionButtons(context, order)),
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

  // Build responsive action buttons for table view
  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> order) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Table view threshold is higher

    // Get buttons based on order status
    List<Widget> buttons = _getActionButtons(context, order, isSmallScreen);

    if (isSmallScreen) {
      // For small screens, use more compact layout
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: buttons,
      );
    } else {
      // For larger screens, use normal spacing
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: buttons,
      );
    }
  }

  // Get action buttons based on order status and screen size
  List<Widget> _getActionButtons(BuildContext context, Map<String, dynamic> order, bool isSmallScreen) {
    List<Widget> buttons = [];    // Send for Approval button (only for Open orders)
    if (order['status'] == 'Open') {
      buttons.add(        IconButton(
          onPressed: () => _showSendForApprovalDialog(context, order['id']),
          icon: Icon(Icons.check_circle, size: isSmallScreen ? 16 : 18),
          tooltip: 'Send for Approval',
          color: Colors.green,
          constraints: BoxConstraints(
            minWidth: isSmallScreen ? 32 : 36,
            minHeight: isSmallScreen ? 32 : 36
          ),
        ),
      );
    }

    // Reopen button (for Pending Approval or Released orders) - positioned near approval
    if (order['status'] == 'Pending Approval' || order['status'] == 'Released') {
      buttons.add(        IconButton(
          onPressed: () => _showReopenOrderDialog(context, order['id']),
          icon: Icon(Icons.refresh, size: isSmallScreen ? 16 : 18),
          tooltip: 'Reopen Order',
          color: Colors.purple,
          constraints: BoxConstraints(
            minWidth: isSmallScreen ? 32 : 36,
            minHeight: isSmallScreen ? 32 : 36
          ),
        ),
      );
    }

    // View button
    buttons.add(      IconButton(
        onPressed: () => _showViewOrderDialog(context, order),
        icon: Icon(Icons.visibility, size: isSmallScreen ? 16 : 18),
        tooltip: 'View Details',
        color: Colors.blue,
        constraints: BoxConstraints(
          minWidth: isSmallScreen ? 32 : 36,
          minHeight: isSmallScreen ? 32 : 36
        ),
      ),
    );

    // Edit button
    buttons.add(      IconButton(
        onPressed: () => _showEditOrderDialog(context, order),
        icon: Icon(Icons.edit, size: isSmallScreen ? 16 : 18),
        tooltip: 'Edit Order',
        color: Colors.orange,
        constraints: BoxConstraints(
          minWidth: isSmallScreen ? 32 : 36,
          minHeight: isSmallScreen ? 32 : 36
        ),
      ),);

    return buttons;
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
        content: SingleChildScrollView(
          child: Text(
            'Are you sure you want to send order $orderNo for approval? This action cannot be undone.',
          ),
        ),
        actionsAlignment: MainAxisAlignment.end, 
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjusted padding
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjusted padding
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              Navigator.pop(context); 
              _sendOrderForApproval(context, orderNo); 
            },
            child: const Text('Send for Approval'),
          ),
        ],
      ),
    );
  }

  // Process the API call to send order for approval
  Future<void> _sendOrderForApproval(BuildContext context, String orderNo) async {
    BuildContext? dialogContext; // For managing the loading dialog
    // CORRECTED: Capture ScaffoldMessengerState before await
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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
              Expanded(child: Text('Sending order $orderNo for approval...')), // Use Expanded for text
            ],
          ),
        );
      },
    );

    final apiService = ApiService();
    try {
      final result = await apiService.sendOrderForApproval(orderNo);
      if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
        Navigator.of(dialogContext!).pop(); // Close loading dialog
      }

      if (result['success'] == true) {
        // CORRECTED: Use captured scaffoldMessenger
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Order sent for approval successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        if (onRefresh != null) {
          onRefresh!(); // Trigger refresh
        }      } else {
        // CORRECTED: Use captured scaffoldMessenger
        String errorMessage = result['message'] ?? "Unknown error";
        
        // Extract message from JSON error and remove CorrelationId
        if (errorMessage.contains('"message"')) {
          try {
            final messageRegex = RegExp(r'"message"\s*:\s*"([^"]+)"');
            final match = messageRegex.firstMatch(errorMessage);
            if (match != null && match.groupCount >= 1) {
              errorMessage = match.group(1)!;
            }
          } catch (e) {
            // If parsing fails, use original message
          }
        }
        
        // Remove CorrelationId and everything after it
        if (errorMessage.contains('CorrelationId')) {
          errorMessage = errorMessage.split('CorrelationId')[0].trim();
          // Remove trailing period if present
          if (errorMessage.endsWith('.')) {
            errorMessage = errorMessage.substring(0, errorMessage.length - 1);
          }
        }
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage.isEmpty ? "Failed to send order for approval" : errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }    } catch (e) {
      if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
        Navigator.of(dialogContext!).pop(); // Close loading dialog on error
      }
      // CORRECTED: Use captured scaffoldMessenger
      String errorMessage = e.toString();
      
      // Extract message from JSON error and remove CorrelationId
      if (errorMessage.contains('"message"')) {
        try {
          final messageRegex = RegExp(r'"message"\s*:\s*"([^"]+)"');
          final match = messageRegex.firstMatch(errorMessage);
          if (match != null && match.groupCount >= 1) {
            errorMessage = match.group(1)!;
          }
        } catch (parseError) {
          // If parsing fails, use original message
        }
      }
      
      // Remove CorrelationId and everything after it
      if (errorMessage.contains('CorrelationId')) {
        errorMessage = errorMessage.split('CorrelationId')[0].trim();
        // Remove trailing period if present
        if (errorMessage.endsWith('.')) {
          errorMessage = errorMessage.substring(0, errorMessage.length - 1);
        }
      }
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage.isEmpty ? "An error occurred" : errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show reopen order confirmation dialog
  void _showReopenOrderDialog(BuildContext context, String orderNo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.refresh, color: Colors.purple),
            const SizedBox(width: 8),
            const Text('Reopen Order'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            'Are you sure you want to reopen order $orderNo? This will set its status back to Open.',
          ),
        ),
        actionsAlignment: MainAxisAlignment.end, 
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjusted padding
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjusted padding
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              Navigator.pop(context); 
              _reopenOrder(context, orderNo); 
            },
            child: const Text('Reopen'),
          ),
        ],
      ),
    );
  }

  // Process the API call to reopen order
  Future<void> _reopenOrder(BuildContext context, String orderNo) async {
    BuildContext? dialogContext; // For managing the loading dialog
    // CORRECTED: Capture ScaffoldMessengerState before await
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogContext = context;
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(color: Colors.purple),
              const SizedBox(width: 16),
              Expanded(child: Text('Reopening order $orderNo...')), // Use Expanded for text
            ],
          ),
        );
      },
    );

    final apiService = ApiService();
    try {
      await apiService.reopenSalesOrder(orderNo);
      if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
        Navigator.of(dialogContext!).pop(); // Close loading dialog
      }

      // CORRECTED: Use captured scaffoldMessenger
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Order reopened successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      if (onRefresh != null) {
        onRefresh!(); // Trigger refresh
      }    } catch (e) {
      if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
        Navigator.of(dialogContext!).pop(); // Close loading dialog on error
      }
      // CORRECTED: Use captured scaffoldMessenger
      String errorMessage = e.toString();
      
      // Extract message from JSON error and remove CorrelationId
      if (errorMessage.contains('"message"')) {
        try {
          final messageRegex = RegExp(r'"message"\s*:\s*"([^"]+)"');
          final match = messageRegex.firstMatch(errorMessage);
          if (match != null && match.groupCount >= 1) {
            errorMessage = match.group(1)!;
          }
        } catch (parseError) {
          // If parsing fails, use original message
        }
      }
      
      // Remove CorrelationId and everything after it
      if (errorMessage.contains('CorrelationId')) {
        errorMessage = errorMessage.split('CorrelationId')[0].trim();
        // Remove trailing period if present
        if (errorMessage.endsWith('.')) {
          errorMessage = errorMessage.substring(0, errorMessage.length - 1);
        }
      }
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage.isEmpty ? "Failed to reopen order" : errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}