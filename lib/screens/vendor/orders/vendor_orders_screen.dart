import 'package:flutter/material.dart';
import 'vendor_order_detail_screen.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF008000),
        title: Row(
          children: [
            Image.asset(
              'assets/app_logo.png',
              height: 30,
              width: 30,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            const Text(
              'Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              // Show filter options
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList('Pending'),
          _buildOrdersList('In Progress'),
          _buildOrdersList('Completed'),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String status) {
    // Generate mock data based on status
    final List<Map<String, dynamic>> orders = _generateMockOrders(status);

    return orders.isEmpty
        ? _buildEmptyState(status)
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(context, order, status);
      },
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;

    switch (status) {
      case 'Pending':
        message = 'No pending orders to confirm';
        icon = Icons.pending_actions;
        break;
      case 'In Progress':
        message = 'No orders in progress';
        icon = Icons.hourglass_empty;
        break;
      case 'Completed':
        message = 'No completed orders yet';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'No orders found';
        icon = Icons.inventory_2;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order, String status) {
    final Color statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFFE8F5E9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorOrderDetailScreen(orderId: order['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['id'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          order['date'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        order['amount'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Action buttons for pending orders
              if (status == 'Pending')
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          // Decline order
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Decline'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          // Accept order
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return const Color(0xFF008000);
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _generateMockOrders(String status) {
    final List<Map<String, dynamic>> orders = [];

    if (status == 'Pending') {
      orders.addAll([
        {
          'id': 'PO-1234',
          'date': '15 Apr 2025',
          'amount': '₹25,000',
          'customer': 'Sampoorna Feeds',
        },
        {
          'id': 'PO-1235',
          'date': '14 Apr 2025',
          'amount': '₹18,500',
          'customer': 'Sampoorna Feeds',
        },
      ]);
    } else if (status == 'In Progress') {
      orders.addAll([
        {
          'id': 'PO-1230',
          'date': '10 Apr 2025',
          'amount': '₹32,000',
          'customer': 'Sampoorna Feeds',
        },
        {
          'id': 'PO-1229',
          'date': '08 Apr 2025',
          'amount': '₹15,000',
          'customer': 'Sampoorna Feeds',
        },
        {
          'id': 'PO-1228',
          'date': '05 Apr 2025',
          'amount': '₹27,500',
          'customer': 'Sampoorna Feeds',
        },
      ]);
    } else if (status == 'Completed') {
      orders.addAll([
        {
          'id': 'PO-1220',
          'date': '28 Mar 2025',
          'amount': '₹45,000',
          'customer': 'Sampoorna Feeds',
        },
        {
          'id': 'PO-1218',
          'date': '25 Mar 2025',
          'amount': '₹18,000',
          'customer': 'Sampoorna Feeds',
        },
      ]);
    }

    return orders;
  }
}