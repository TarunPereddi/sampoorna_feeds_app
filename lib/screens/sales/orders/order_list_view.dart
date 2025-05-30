import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'order_detail_view.dart';
import 'edit_order_screen.dart';
 
class OrderListView extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final ScrollController scrollController;
  final VoidCallback? onRefresh;
  final bool isNestedInScrollView; // New parameter

  const OrderListView({
    super.key,
    required this.orders,
    required this.scrollController,
    this.onRefresh,
    this.isNestedInScrollView = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty && isNestedInScrollView) {
        // Avoid rendering an empty ListView with shrinkWrap that might take up some default space or cause issues.
        // Render nothing or a placeholder if it's nested and empty.
        return const SizedBox.shrink(); 
    }
    if (orders.isEmpty) {
        // If not nested and empty, it might be the primary view, show a message.
        return const Center(child: Text("No orders to display."));
    }
    
    return ListView.builder(
      controller: isNestedInScrollView ? null : scrollController,
      physics: isNestedInScrollView ? const ClampingScrollPhysics() : null, // Use ClampingScrollPhysics when nested
      shrinkWrap: isNestedInScrollView,
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
                    Expanded(
                      child: Text(
                        order['id'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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
                _buildActionButtons(context, order),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build responsive action buttons
  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> order) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    // Get buttons based on order status
    List<Widget> buttons = _getActionButtons(context, order, isSmallScreen);
      if (isSmallScreen) {
      // For very small screens, use a more compact layout with better spacing and alignment
      return Wrap(
        alignment: WrapAlignment.center, // Changed from .end to .center
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: buttons,
      );
    } else {
      // For larger screens, use a single row
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Changed from .end to .center
          children: buttons,
        ),
      );
    }
  }

  // Get action buttons based on order status and screen size
  List<Widget> _getActionButtons(BuildContext context, Map<String, dynamic> order, bool isSmallScreen) {
    List<Widget> buttons = [];
    const smallScreenIconSize = 18.0;
    const smallScreenFontSize = 12.0;
    const smallScreenPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 4);
    final smallScreenTapTargetSize = MaterialTapTargetSize.shrinkWrap;

      // Send for Approval button (only for Open orders)
    if (order['status'] == 'Open') {
      buttons.add(
        isSmallScreen
          ? TextButton.icon(
              onPressed: () => _showSendForApprovalDialog(context, order['id']),
              icon: const Icon(Icons.check_circle, size: smallScreenIconSize),
              label: const Text('Approve', style: TextStyle(fontSize: smallScreenFontSize), textAlign: TextAlign.center),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
                padding: smallScreenPadding,
                tapTargetSize: smallScreenTapTargetSize,
              ),
            )
          : TextButton.icon(
              onPressed: () => _showSendForApprovalDialog(context, order['id']),
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('Approve', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
      );
      if (!isSmallScreen && buttons.isNotEmpty) buttons.add(const SizedBox(width: 4));
    }

    // Reopen button (for Pending Approval or Released orders) - positioned near approval
    if (order['status'] == 'Pending Approval' || order['status'] == 'Released') {
      buttons.add(
        isSmallScreen
          ? TextButton.icon(
              onPressed: () => _showReopenOrderDialog(context, order['id']),
              icon: const Icon(Icons.refresh, size: smallScreenIconSize),
              label: const Text('Reopen', style: TextStyle(fontSize: smallScreenFontSize), textAlign: TextAlign.center),
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple,
                padding: smallScreenPadding,
                tapTargetSize: smallScreenTapTargetSize,
              ),
            )
          : TextButton.icon(
              onPressed: () => _showReopenOrderDialog(context, order['id']),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reopen', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
      );
      if (!isSmallScreen && buttons.isNotEmpty) buttons.add(const SizedBox(width: 8)); 
    }
    
    // View button
    buttons.add(
      isSmallScreen
        ? TextButton.icon(
            onPressed: () => _showViewOrderDetails(context, order),
            icon: const Icon(Icons.visibility, size: smallScreenIconSize),
            label: const Text('View', style: TextStyle(fontSize: smallScreenFontSize), textAlign: TextAlign.center),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              padding: smallScreenPadding,
              tapTargetSize: smallScreenTapTargetSize,
            ),
          )
        : TextButton.icon(
            onPressed: () => _showViewOrderDetails(context, order),
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('View', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
    );
    
    if (!isSmallScreen && buttons.isNotEmpty) buttons.add(const SizedBox(width: 4));
    
    // Edit button
    buttons.add(
      isSmallScreen
        ? TextButton.icon(
            onPressed: () => _showEditOrderDialog(context, order),
            icon: const Icon(Icons.edit, size: smallScreenIconSize),
            label: const Text('Edit', style: TextStyle(fontSize: smallScreenFontSize), textAlign: TextAlign.center),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: smallScreenPadding,
              tapTargetSize: smallScreenTapTargetSize,
            ),
          )
        : TextButton.icon(
            onPressed: () => _showEditOrderDialog(context, order),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
    );
    
    // Add spacing between buttons for larger screens if using Row
    if (!isSmallScreen && buttons.length > 1) {
      List<Widget> spacedButtons = [];
      for (int i = 0; i < buttons.length; i++) {
        spacedButtons.add(buttons[i]);
        if (i < buttons.length - 1) {
          // Use the specific spacing logic that was present before, or a default
          // The original code added SizedBox(width: 4) or SizedBox(width: 8) conditionally
          // For simplicity here, I'll add a consistent small spacing, 
          // but this might need to revert to the more complex conditional spacing if that was important.
          // Re-evaluating the original spacing logic:
          // - After Approve: width: 4
          // - After Reopen: width: 8
          // - After View: width: 4
          // This logic was already present and handled by the `if (!isSmallScreen) buttons.add(const SizedBox(width: X));` lines
          // The current refactoring for `_getActionButtons` has moved the SizedBox additions.
          // Let's ensure the SizedBox logic is correctly maintained or simplified.
        }
      }
      // The existing SizedBox additions within the if blocks for each button type on large screens
      // already handle the spacing. The loop above is not needed and might misinterpret the spacing.
      // The current structure of adding SizedBox after each button (for non-small screens) is fine,
      // as Row will just place them.
    }

    return buttons;
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
      ),    );
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
              Expanded(child: Text('Sending order $orderNo for approval...')),
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
        }
      } else {
        // CORRECTED: Use captured scaffoldMessenger
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to send order for approval: ${result['message'] ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
        Navigator.of(dialogContext!).pop(); // Close loading dialog on error
      }
      // CORRECTED: Use captured scaffoldMessenger
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
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
            Expanded(child: Text('Reopening order $orderNo...')),
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
    }
  } catch (e) {
    if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
      Navigator.of(dialogContext!).pop(); // Close loading dialog on error
    }
    // CORRECTED: Use captured scaffoldMessenger
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Failed to reopen order: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Show edit order dialog

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
        ),        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            
            // Use direct navigation since named routes are causing issues
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditOrderScreen(orderNo: order['id']),
              ),
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

}