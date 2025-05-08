import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common_app_bar.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../models/sales_order.dart';
import '../orders/create_order_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _recentOrders = [];
  String? _errorMessage;

  // Summary metrics
  final summaryMetrics = [
    {'title': 'Total Orders', 'value': '0', 'icon': Icons.shopping_cart, 'color': Colors.blue},
    {'title': 'Active Customers', 'value': '0', 'icon': Icons.people, 'color': Colors.green},
    {'title': 'Revenue (MTD)', 'value': '₹0', 'icon': Icons.currency_rupee, 'color': Colors.orange},
    {'title': 'Pending Orders', 'value': '0', 'icon': Icons.pending_actions, 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentOrders();
  }

  Future<void> _loadRecentOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final salesPerson = authService.currentUser;
      
      if (salesPerson == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Load recent orders for the current sales person
      final orders = await _apiService.getRecentSalesOrders(
        salesPersonName: salesPerson.code,
        limit: 10,
      );

      setState(() {
        _recentOrders = orders;
        _isLoading = false;
        
        // Update summary metrics
        _updateSummaryMetrics(orders);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load orders: $e';
        _isLoading = false;
      });
    }
  }

  void _updateSummaryMetrics(List<dynamic> orders) {
    // Count total orders
    summaryMetrics[0]['value'] = orders.length.toString();
    
    // Count pending orders
    final pendingOrders = orders.where((order) => order['Status'] == 'Released').length;
    summaryMetrics[3]['value'] = pendingOrders.toString();
    
    // Calculate total revenue (approximate)
    double totalRevenue = 0;
    for (var order in orders) {
      if (order['Amt_to_Customer'] != null) {
        totalRevenue += order['Amt_to_Customer'] is double
            ? order['Amt_to_Customer']
            : double.tryParse(order['Amt_to_Customer'].toString()) ?? 0;
      }
    }
    
    // Format revenue in thousands/lakhs
    final formattedRevenue = _formatCurrency(totalRevenue);
    summaryMetrics[2]['value'] = formattedRevenue;
    
    // Count unique customers
    final uniqueCustomers = orders
        .map((order) => order['Sell_to_Customer_No'])
        .toSet()
        .length;
    summaryMetrics[1]['value'] = uniqueCustomers.toString();
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final authService = Provider.of<AuthService>(context);
    final salesPerson = authService.currentUser;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Sampoorna Feeds',
        actions: [
          // Add a user icon with the sales person's name
          if (salesPerson != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  salesPerson.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
          ).then((_) {
            // Refresh orders when returning from create screen
            _loadRecentOrders();
          });
        },
        backgroundColor: const Color(0xFF008000),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecentOrders,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome message with sales person's name
                          if (salesPerson != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                'Welcome, ${salesPerson.name}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

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
                                  ).then((_) {
                                    _loadRecentOrders();
                                  });
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

                          // Orders list or empty state
                          _recentOrders.isEmpty
                              ? _buildEmptyOrdersState()
                              : _buildOrdersList(isSmallScreen),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyOrdersState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No recent orders found',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new order by clicking the + button',
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

  Widget _buildOrdersList(bool isSmallScreen) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentOrders.length,
      itemBuilder: (context, index) {
        final order = _recentOrders[index];
        return _buildOrderCard(order, isSmallScreen);
      },
    );
  }

  Widget _buildOrderCard(dynamic order, bool isSmallScreen) {
    final String orderId = order['No'] ?? '';
    final String customerName = order['Sell_to_Customer_Name'] ?? '';
    final String orderDate = order['Order_Date'] != null 
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(order['Order_Date']))
        : '';
    final double amount = order['Amt_to_Customer'] != null 
        ? (order['Amt_to_Customer'] is double 
            ? order['Amt_to_Customer'] 
            : double.tryParse(order['Amt_to_Customer'].toString()) ?? 0)
        : 0;
    final String status = order['Status'] ?? '';

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
                  orderId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                _buildStatusChip(status),
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
                        customerName,
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
                        orderDate,
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
                        '₹${amount.toStringAsFixed(0)}',
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
                    _showOrderDetails(order);
                  },
                  tooltip: 'View Details',
                  color: Colors.blue,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    // Edit order - Not implemented yet
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit functionality coming soon')),
                    );
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
  }

  void _showOrderDetails(dynamic order) {
    // Show a modal bottom sheet with order details
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
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order ${order['No']}',
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
                    
                    // Status chip
                    Center(child: _buildStatusChip(order['Status'] ?? '')),
                    const SizedBox(height: 16),
                    
                    // Order details
                    _buildOrderDetailItem('Customer', order['Sell_to_Customer_Name'] ?? ''),
                    _buildOrderDetailItem('Order Date', order['Order_Date'] != null 
                        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(order['Order_Date']))
                        : ''),
                    _buildOrderDetailItem('Amount', '₹${order['Amt_to_Customer']?.toString() ?? '0'}'),
                    _buildOrderDetailItem('Location', order['Location_Code'] ?? ''),
                    
                    const Divider(height: 32),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // Functionality to be implemented
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Print functionality coming soon')),
                            );
                          },
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text('Print'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Functionality to be implemented
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit functionality coming soon')),
                            );
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
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
      },
    );
  }

  Widget _buildOrderDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
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
      case 'Released':
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
}