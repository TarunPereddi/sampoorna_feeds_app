import 'package:flutter/material.dart';
import '../../../widgets/common_app_bar.dart';
import '../orders/create_order_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mock data for recent orders
  final recentOrders = [
    {
      'orderId': 'ORD-2025-001',
      'customerName': 'B.K. Enterprises',
      'date': '14/04/2025',
      'amount': '₹23,500',
      'status': 'Pending',
    },
    {
      'orderId': 'ORD-2025-002',
      'customerName': 'Prajjawal Enterprises',
      'date': '13/04/2025',
      'amount': '₹18,750',
      'status': 'Completed',
    },
    {
      'orderId': 'ORD-2025-003',
      'customerName': 'Agro Suppliers Ltd',
      'date': '12/04/2025',
      'amount': '₹31,200',
      'status': 'Processing',
    },
    {
      'orderId': 'ORD-2025-004',
      'customerName': 'Farm Solutions Inc',
      'date': '11/04/2025',
      'amount': '₹15,800',
      'status': 'Completed',
    },
    {
      'orderId': 'ORD-2025-005',
      'customerName': 'Green Agro Ltd',
      'date': '10/04/2025',
      'amount': '₹27,350',
      'status': 'Completed',
    },
  ];

  // Summary metrics
  final summaryMetrics = [
    {'title': 'Total Orders', 'value': '145', 'icon': Icons.shopping_cart, 'color': Colors.blue},
    {'title': 'Active Customers', 'value': '78', 'icon': Icons.people, 'color': Colors.green},
    {'title': 'Revenue (MTD)', 'value': '₹4.3L', 'icon': Icons.currency_rupee, 'color': Colors.orange},
    {'title': 'Pending Orders', 'value': '12', 'icon': Icons.pending_actions, 'color': Colors.red},
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Sampoorna Feeds',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
          );
        },
        backgroundColor: const Color(0xFF008000),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // This will be replaced with actual API call when integrated
          await Future.delayed(const Duration(milliseconds: 800));
          setState(() {
            // Refresh data
          });
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards - Horizontally scrollable
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: summaryMetrics.length,
                    itemBuilder: (context, index) {
                      final metric = summaryMetrics[index];
                      return _buildSummaryCard(
                        title: metric['title'] as String,
                        value: metric['value'] as String,
                        icon: metric['icon'] as IconData,
                        color: metric['color'] as Color,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Recent Orders section with Create Order button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Orders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008000),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16,
                            vertical: isSmallScreen ? 8 : 12
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Orders table or cards based on screen size
                isSmallScreen
                    ? _buildOrderCardsList()
                    : _buildOrdersTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCardsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentOrders.length,
      itemBuilder: (context, index) {
        final order = recentOrders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order['orderId'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    _buildStatusChip(order['status'] as String),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Expanded(
                      child: Column(
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
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 20),
                      onPressed: () {
                        // View order details
                      },
                      tooltip: 'View Details',
                      color: Colors.blue,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        // Edit order
                      },
                      tooltip: 'Edit Order',
                      color: Colors.orange,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
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

  Widget _buildOrdersTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
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
              rows: recentOrders.map((order) {
                return DataRow(
                  cells: [
                    DataCell(Text(order['orderId'] as String)),
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
                            },
                            tooltip: 'View Details',
                            color: Colors.blue,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () {
                              // Edit order
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
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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