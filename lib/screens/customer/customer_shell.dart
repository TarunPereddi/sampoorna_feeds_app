import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import 'home/home_screen.dart';
import 'orders/orders_screen.dart';  // Using our optimized screen
// import 'customers/customers_screen.dart'; // Commented out - customers tab removed
// import 'queries/queries_screen.dart'; // Commented out - queries tab removed
// import 'profile/profile_screen.dart';
import 'delivery/delivery_screen.dart';
import 'orders/edit_order_screen.dart';
import '../../services/auth_service.dart';
import '../../providers/tab_refresh_provider.dart';
import '../../models/customer.dart';
import 'customers/customer_detail_screen.dart';

class CustomerShell extends StatefulWidget {
  final int initialTabIndex;

  const CustomerShell({super.key, this.initialTabIndex = 0});
  
  /// Static method to switch tabs from anywhere
  /// This can be used by NavigationService
  static void switchTab(BuildContext context, int tabIndex, {Map<String, dynamic>? arguments}) {
    // Find the nearest CustomerShell state and call its switchTab method
    final state = context.findAncestorStateOfType<_CustomerShellState>();
    if (state != null) {
      state.switchTab(tabIndex, arguments: arguments);
    }
  }

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  late int _selectedIndex;
    // Maintain separate navigation keys for each tab to enable
  // independent navigation stacks
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // Home
    GlobalKey<NavigatorState>(), // Orders
    GlobalKey<NavigatorState>(), // Transactions
    GlobalKey<NavigatorState>(), // Delivery
  ];

  /// Allows external widgets to switch tabs programmatically
  void switchTab(int index, {Map<String, dynamic>? arguments}) {
    setState(() {
      _selectedIndex = index;
    });
    
    // If arguments are provided, handle them appropriately
    if (arguments != null && _navigatorKeys[index].currentState != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Reset to first route with arguments
        _navigatorKeys[index].currentState!.pushReplacementNamed(
          '/',
          arguments: arguments,
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    // Set preferred orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // Allow all orientations when widget is disposed
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // If not authenticated, redirect to login
        if (!authService.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return WillPopScope(
          // Handle back button presses to navigate within the current tab
          onWillPop: () async {
            final currentNavigatorState = _navigatorKeys[_selectedIndex].currentState;
            if (currentNavigatorState!.canPop()) {
              currentNavigatorState.pop();
              return false;
            }
            return true;
          },          child: Scaffold(            body: Stack(
              children: [
                // Home Tab
                Offstage(
                  offstage: _selectedIndex != 0,
                  child: RepaintBoundary(
                    child: _navigatorKeys[0].currentState == null && _selectedIndex != 0
                        ? Container()
                        : _buildTabNavigator(
                            0,
                            (context) => const HomeScreen(),
                          ),
                  ),
                ),
                // Orders Tab
                Offstage(
                  offstage: _selectedIndex != 1,
                  child: RepaintBoundary(
                    child: _navigatorKeys[1].currentState == null && _selectedIndex != 1
                        ? Container()
                        : _buildTabNavigator(
                            1,
                            (context) {
                              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                              final initialStatus = args?['initialStatus'] as String?;
                              return OrdersScreenFixed(initialStatus: initialStatus);
                            },
                          ),
                  ),
                ),
                // Transactions Tab (directly show detailed customer view)
                Offstage(
                  offstage: _selectedIndex != 2,
                  child: RepaintBoundary(
                    child: _navigatorKeys[2].currentState == null && _selectedIndex != 2
                        ? Container()
                        : _buildTabNavigator(
                            2,
                            (context) {
                              final authService = Provider.of<AuthService>(context, listen: false);
                              final customer = authService.currentUser;
                              if (customer == null || customer is! Customer) {
                                return const Center(child: Text('No customer details available'));
                              }
                              return CustomerDetailScreen(customerNo: customer.no);
                            },
                          ),
                  ),
                ),
                // Delivery Tab
                Offstage(
                  offstage: _selectedIndex != 3,
                  child: RepaintBoundary(
                    child: _navigatorKeys[3].currentState == null && _selectedIndex != 3
                        ? Container()
                        : _buildTabNavigator(
                            3,
                            (BuildContext context) => const DeliveryScreen(),
                          ),
                  ),
                ),
              ],
            ),            bottomNavigationBar: Consumer<TabRefreshProvider>(
              builder: (context, tabRefreshProvider, child) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 360;
                    
                    return BottomNavigationBar(
                      backgroundColor: AppColors.primaryLight,
                      selectedItemColor: AppColors.primaryDark,
                      unselectedItemColor: AppColors.grey600,
                      currentIndex: _selectedIndex,
                      type: BottomNavigationBarType.fixed,
                      selectedFontSize: isSmallScreen ? 11 : 12,
                      unselectedFontSize: isSmallScreen ? 10 : 11,
                      iconSize: isSmallScreen ? 20 : 24,
                      onTap: (index) {
                        // If tapping on the already selected tab and can pop,
                        // pop to the root of that tab
                        if (index == _selectedIndex &&
                            _navigatorKeys[index].currentState?.canPop() == true) {
                          _navigatorKeys[index].currentState!.popUntil((route) => route.isFirst);
                        } else {
                          // Notify the provider about tab change
                          tabRefreshProvider.onTabChanged(index);
                          
                          setState(() {
                            _selectedIndex = index;
                          });
                        }
                      },
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.home),
                          label: 'Home',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.shopping_cart),
                          label: 'Orders',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.receipt_long),
                          label: 'Transactions',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.local_shipping),
                          label: 'Delivery',
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Helper method to build a Navigator for each tab
  Widget _buildTabNavigator(int index, WidgetBuilder rootScreenBuilder) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (RouteSettings settings) {
        // For the root route of each tab
        if (settings.name == '/' || settings.name == null) {
          return MaterialPageRoute(
            settings: settings,
            builder: rootScreenBuilder,
          );
        }
        
        // Special handling for edit order in the orders tab (index 1)
        if (settings.name == '/edit_order' && index == 1) {
          final orderNo = settings.arguments as String;
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => EditOrderScreen(orderNo: orderNo),
          );
        }
        
        return null;
      },
    );
  }
}