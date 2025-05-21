import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common_app_bar.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../orders/create_order_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import '../../login/login_screen.dart';
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

  // Dashboard metrics
  Map<String, int> _dashboardMetrics = {
    'customers': 0,
    'pendingApproval': 0,
    'releasedOrders': 0,
    'openOrders': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
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

      // Load all data in parallel
      await Future.wait([
        _loadRecentOrders(salesPerson.name),
        _loadDashboardMetrics(salesPerson.code, salesPerson.name),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load dashboard data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecentOrders(String salesPersonName) async {
    try {
      // Get orders from last 48 hours
      final now = DateTime.now();
      final twoDaysAgo = now.subtract(const Duration(hours: 48));
      
      final orders = await _apiService.getSalesOrders(
        salesPersonName: salesPersonName,
        fromDate: twoDaysAgo,
        toDate: now,
        limit: 10,
      );
      
      _recentOrders = orders;
    } catch (e) {
      print('Error loading recent orders: $e');
      _recentOrders = [];
    }
  }

  Future<void> _loadDashboardMetrics(String salesPersonCode, String salesPersonName) async {
    try {
      // Load customers count - use a safer approach with error handling
      int customersCount = 0;
      try {
        final customersResult = await _apiService.getCustomersWithPagination(
          salesPersonCode: salesPersonCode,
          page: 1,
          pageSize: 1, // We only need the count
        );
        customersCount = customersResult.totalCount;
      } catch (e) {
        print('Error loading customers count: $e');
        // Try alternative approach or set to 0
        customersCount = 0;
      }
      
      // Load order counts by status with individual error handling
      int pendingCount = 0;
      int releasedCount = 0;
      int openCount = 0;
      
      try {
        final pendingResponse = await _apiService.getSalesOrders(
          salesPersonName: salesPersonName,
          status: 'Pending Approval',
          limit: 1,
          includeCount: true,
        );
        pendingCount = pendingResponse['@odata.count'] ?? 0;
      } catch (e) {
        print('Error loading pending orders count: $e');
      }
      
      try {
        final releasedResponse = await _apiService.getSalesOrders(
          salesPersonName: salesPersonName,
          status: 'Released',
          limit: 1,
          includeCount: true,
        );
        releasedCount = releasedResponse['@odata.count'] ?? 0;
      } catch (e) {
        print('Error loading released orders count: $e');
      }
      
      try {
        final openResponse = await _apiService.getSalesOrders(
          salesPersonName: salesPersonName,
          status: 'Open',
          limit: 1,
          includeCount: true,
        );
        openCount = openResponse['@odata.count'] ?? 0;
      } catch (e) {
        print('Error loading open orders count: $e');
      }

      setState(() {
        _dashboardMetrics = {
          'customers': customersCount,
          'pendingApproval': pendingCount,
          'releasedOrders': releasedCount,
          'openOrders': openCount,
        };
      });
    } catch (e) {
      print('Error loading dashboard metrics: $e');
      // Set all to 0 if there's a general error
      setState(() {
        _dashboardMetrics = {
          'customers': 0,
          'pendingApproval': 0,
          'releasedOrders': 0,
          'openOrders': 0,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final authService = Provider.of<AuthService>(context);
    final salesPerson = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 30,
              width: 30,
            ),
            const SizedBox(width: 12),
            const Text(
              'Sampoorna Feeds',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2C5F2D),
        actions: [
          // Profile Avatar Dropdown
          if (salesPerson != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'profile') {
                  // Navigate to profile screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                } else if (value == 'logout') {
                  _showLogoutDialog(context, authService);
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'profile',
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Profile'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              child: Container(
                margin: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 18,
                  child: Text(
                    salesPerson.name.isNotEmpty 
                        ? salesPerson.name[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      color: Color(0xFF2C5F2D),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
            _loadDashboardData();
          });
        },
        backgroundColor: const Color(0xFF008000),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_errorMessage!),
                          ElevatedButton(
                            onPressed: _loadDashboardData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome message
                          if (salesPerson != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: Text(
                                'Welcome back, ${salesPerson.name}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          // Dashboard Cards
                          _buildDashboardCards(),

                          const SizedBox(height: 32),

                          // Recent Orders section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Orders (48h)',
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
                                    _loadDashboardData();
                                  });
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('New Order'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF008000),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Orders list or empty state
                          _recentOrders.isEmpty
                              ? _buildEmptyOrdersState()
                              : _buildOrdersList(),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                authService.logout();
                // Navigate to login screen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008000),
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardCards() {
    return Column(
      children: [
        // Customers Card
        _buildDashboardCard(
          title: 'My Customers',
          count: _dashboardMetrics['customers']!,
          icon: Icons.people,
          color: Colors.blue,
          onTap: () {
            // TODO: Navigate to customers screen when implemented
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Customers screen coming soon')),
            );
          },
        ),
        const SizedBox(height: 16),
        
        // Orders Row
        Row(
          children: [
            Expanded(
              child: _buildDashboardCard(
                title: 'Pending Approval',
                count: _dashboardMetrics['pendingApproval']!,
                icon: Icons.pending_actions,
                color: Colors.orange,
                onTap: () => _navigateToOrdersByStatus('Pending Approval'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDashboardCard(
                title: 'Released Orders',
                count: _dashboardMetrics['releasedOrders']!,
                icon: Icons.check_circle,
                color: Colors.green,
                onTap: () => _navigateToOrdersByStatus('Released Orders'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Open Orders Card
        _buildDashboardCard(
          title: 'Open Orders',
          count: _dashboardMetrics['openOrders']!,
          icon: Icons.receipt,
          color: Colors.purple,
          onTap: () => _navigateToOrdersByStatus('Open Orders'),
        ),
      ],
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToOrdersByStatus(String status) {
    // Map status to correct filter values for orders screen
    String? filterStatus;
    switch (status) {
      case 'Open Orders':
        filterStatus = 'Open';
        break;
      case 'Released Orders':
        filterStatus = 'Approved'; // Maps to "Approved" tab in orders screen
        break;
      case 'Pending Approval':
        filterStatus = 'Pending Approval';
        break;
      default:
        filterStatus = status;
    }
    
    // Navigate to orders screen with specific status filter
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrdersScreen(),
        settings: RouteSettings(arguments: {'initialStatus': filterStatus}),
      ),
    );
  }

  Widget _buildEmptyOrdersState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
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
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders from the last 48 hours will appear here',
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

  Widget _buildOrdersList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentOrders.length,
      itemBuilder: (context, index) {
        final order = _recentOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(dynamic order) {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    fontSize: 16,
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        orderDate,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _showOrderDetails(order);
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
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
      case 'Pending Approval':
        chipColor = Colors.orange;
        break;
      case 'Open':
        chipColor = Colors.purple;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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

  void _showOrderDetails(dynamic order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                padding: const EdgeInsets.all(20.0),
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Status chip
                    Center(child: _buildStatusChip(order['Status'] ?? '')),
                    const SizedBox(height: 20),
                    
                    // Order details
                    _buildOrderDetailItem('Customer', order['Sell_to_Customer_Name'] ?? ''),
                    _buildOrderDetailItem('Order Date', order['Order_Date'] != null 
                        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(order['Order_Date']))
                        : ''),
                    _buildOrderDetailItem('Amount', '₹${order['Amt_to_Customer']?.toString() ?? '0'}'),
                    _buildOrderDetailItem('Location', order['Location_Code'] ?? ''),
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const OrdersScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.list, size: 18),
                            label: const Text('View All Orders'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF008000),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
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
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 