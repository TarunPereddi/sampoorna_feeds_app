import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../screens/login/login_screen.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/navigation_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/error_dialog.dart';
import '../../../mixins/tab_refresh_mixin.dart';
import '../orders/create_order_screen.dart';
import '../orders/order_list_view.dart'; // Added import
import '../orders/order_table_view.dart'; // Added import
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin, TabRefreshMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _recentOrders = [];
  bool _dataLoaded = false; // Track if data has been loaded

  // Dashboard metrics
  Map<String, int> _dashboardMetrics = {
    'customers': 0,
    'pendingApproval': 0,
    'releasedOrders': 0,
    'openOrders': 0,
  };

  @override
  bool get wantKeepAlive => true; // Keep the state when switching tabs

  // TabRefreshMixin implementation
  @override
  int get tabIndex => 0; // Home tab index

  @override
  Future<void> performRefresh() async {
    debugPrint('HomeScreen: Performing refresh');
    await _loadDashboardData();
  }

  @override
  void initState() {
    super.initState();
    // We'll load data when the widget becomes visible
  }
    @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load data if this is the first time
    if (!_dataLoaded) {
      _loadDashboardData();
      _dataLoaded = true;
    }
  }
  Future<void> _loadDashboardData() async {    setState(() {
      _isLoading = true;
    });

    try {

      final authService = Provider.of<AuthService>(context, listen: false);
      final customer = authService.currentUser;
      if (customer == null) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ErrorDialog.showGenericError(
            context,
            message: 'User not authenticated',
          );
        }
        return;
      }

      final customerNo = customer.no;
      final customerName = customer.name;
      final customerState = customer.stateCode;

      // Load all data in parallel
      await Future.wait([
        _loadRecentOrders(customerNo, customerState),
        _loadDashboardMetrics(customerNo, customerName, customerState),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {      setState(() {
        _isLoading = false;
      });
        // Show error dialog instead of inline error
      if (mounted) {
        ErrorDialog.showGenericError(
          context,
          message: 'Failed to load dashboard data: ${e.toString()}',
          onOk: _loadDashboardData,
        );
      }
    }
  }

  Future<void> _loadRecentOrders(String customerNo, String customerState) async {
    try {
      // Get orders from last 48 hours
      final now = DateTime.now();
      final twoDaysAgo = now.subtract(const Duration(hours: 48));

      // For customer persona, only filter by customer number (not salesperson codes)
      final filter = "Sell_to_Customer_No eq '$customerNo'";
      final ordersData = await _apiService.getSalesOrders(
        searchFilter: filter,
        fromDate: twoDaysAgo,
        toDate: now,
        limit: 10,
      );

      // Ensure ordersData is a List before assigning
      if (ordersData is List) {
        _recentOrders = ordersData;
      } else if (ordersData is Map && ordersData.containsKey('value') && ordersData['value'] is List) {
        // Handle cases where API might return a map with 'value' key
        _recentOrders = ordersData['value'];
      } else {
        print('Unexpected format for recent orders: $ordersData');
        _recentOrders = []; // Default to empty list on unexpected format
      }
    } catch (e) {
      print('Error loading recent orders: $e');
      _recentOrders = [];
    }
  }

  Future<void> _loadDashboardMetrics(String customerNo, String customerName, String customerState) async {
    try {
      // Customers card not needed for customer persona, so skip loading customersCount

      // For customer persona, only filter by customer number (not salesperson codes)
      final baseFilter = "Sell_to_Customer_No eq '$customerNo'";

      // Load order counts by status with individual error handling
      int pendingCount = 0;
      int releasedCount = 0;
      int openCount = 0;

      try {
        final pendingResponse = await _apiService.getSalesOrders(
          searchFilter: baseFilter,
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
          searchFilter: baseFilter,
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
          searchFilter: baseFilter,
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
          // 'customers': customersCount, // Removed for customer persona
          'pendingApproval': pendingCount,
          'releasedOrders': releasedCount,
          'openOrders': openCount,
        };
      });
    } catch (e) {
      print('Error loading dashboard metrics: $e');
      setState(() {
        _dashboardMetrics = {
          // 'customers': 0, // Removed for customer persona
          'pendingApproval': 0,
          'releasedOrders': 0,
          'openOrders': 0,
        };
      });
    }
  }
  @override  
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final authService = Provider.of<AuthService>(context);
    final customer = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 30,
              width: 30,
            ),
            const SizedBox(width: 12),            const Text(
              'Sampoorna Feeds',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryDark,        actions: [          // Profile Avatar Dropdown
          if (customer != null)
            PopupMenuButton<String>(
              offset: const Offset(0, 50), // Position dropdown below the avatar
              onSelected: (value) {
                if (value == 'profile') {
                  // Navigate directly to ProfileScreen
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
                    backgroundColor: AppColors.white,
                    radius: 18,
                    child: Text(
                      customer.name != null && customer.name.isNotEmpty 
                          ? customer.name[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ),
            ),
        ],
      ),      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Use regular Navigator.push here since CreateOrderScreen is not a tab
          // and we want to return back to this screen afterwards
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
          ).then((_) {
            _loadDashboardData();
          });        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(
                  color: AppColors.primary,
                ))
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome message
                      if (customer != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Text(
                            'Welcome back, ${customer.name}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey900,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),

                      // Dashboard Cards
                      _buildDashboardCards(),

                      const SizedBox(height: 32),

                      // Recent Orders section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Recent Orders (48h)',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.grey900,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
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
                          : _buildOrdersList(), // Modified to call the new _buildOrdersList
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
                Navigator.of(context).pop();                authService.logout();
                // Navigate to login screen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }  Widget _buildDashboardCards() {
    // Calculate how many cards per row based on screen width
    // final screenWidth = MediaQuery.of(context).size.width;
    // Customers card is not shown for customer persona
    // Tab indexes: 0 = Home, 1 = Orders, 2 = (Customers, not used here)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - (2 * 8)) / 3;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // Pending Approval Card
              SizedBox(
                width: cardWidth,
                child: _buildCompactDashboardCard(
                  title: 'Pending Orders',
                  count: _dashboardMetrics['pendingApproval']!,
                  icon: Icons.pending_actions,
                  color: AppColors.statusPending,
                  onTap: () {
                    NavigationService.navigateToTab(
                      context,
                      1, // Orders tab
                      arguments: {'initialStatus': 'Pending Approval'}
                    );
                  },
                ),
              ),
              // Released Orders Card
              SizedBox(
                width: cardWidth,
                child: _buildCompactDashboardCard(
                  title: 'Released Orders',
                  count: _dashboardMetrics['releasedOrders']!,
                  icon: Icons.check_circle,
                  color: AppColors.statusReleased,
                  onTap: () {
                    NavigationService.navigateToTab(
                      context,
                      1, // Orders tab
                      arguments: {'initialStatus': 'Approved'}
                    );
                  },
                ),
              ),
              // Open Orders Card
              SizedBox(
                width: cardWidth,
                child: _buildCompactDashboardCard(
                  title: 'Open Orders',
                  count: _dashboardMetrics['openOrders']! ,
                  icon: Icons.receipt,
                  color: AppColors.statusOpen,
                  onTap: () {
                    NavigationService.navigateToTab(
                      context,
                      1, // Orders tab
                      arguments: {'initialStatus': 'Open'}
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // A more compact card design optimized for displaying in a row
  Widget _buildCompactDashboardCard({
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Method removed - now using direct navigation to SalesShell tabs
  Widget _buildEmptyOrdersState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'No recent orders found',
              style: TextStyle(
                color: AppColors.grey700,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Orders from the last 48 hours will appear here',
                style: TextStyle(
                  color: AppColors.grey500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to convert order data to the format expected by view widgets
  List<Map<String, dynamic>> _convertOrdersToViewFormat(List<dynamic> orders) {
    return orders.map((order) {
      // Parse the amount properly
      double amount = 0;
      if (order['Amt_to_Customer'] != null) {
        amount = order['Amt_to_Customer'] is double
            ? order['Amt_to_Customer']
            : double.tryParse(order['Amt_to_Customer'].toString()) ?? 0;
      }
      
      // Parse dates
      String dateStr = order['Order_Date'] != null 
          ? DateFormat('dd/MM/yyyy').format(DateTime.parse(order['Order_Date']))
          : '';
      
      return {
        'id': order['No'] as String? ?? 'N/A',
        'customerName': order['Sell_to_Customer_Name'] ?? order['Sell_to_Customer_No'] ?? 'Unknown',
        'date': dateStr,
        'amount': '₹${amount.toStringAsFixed(0)}',
        'status': order['Status'] as String? ?? 'Unknown',
      };
    }).toList();
  }

  Widget _buildOrdersList() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    final viewOrders = _convertOrdersToViewFormat(_recentOrders);

    VoidCallback? refreshCallback = () => _loadDashboardData();

    if (isSmallScreen) {
      return OrderListView(
        orders: viewOrders,
        scrollController: ScrollController(), 
        onRefresh: refreshCallback,
        isNestedInScrollView: true, 
      );
    } else {
      return OrderTableView(
        orders: viewOrders,
        scrollController: ScrollController(), 
        onRefresh: refreshCallback,
      );
    }
  }
}