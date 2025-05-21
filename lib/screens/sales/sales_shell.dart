import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'home/home_screen.dart';
import 'orders/orders_screen.dart';
import 'queries/queries_screen.dart';
import 'profile/profile_screen.dart';
import 'orders/edit_order_screen.dart';
import '../../services/auth_service.dart';

class SalesShell extends StatefulWidget {
  const SalesShell({super.key});

  @override
  State<SalesShell> createState() => _SalesShellState();
}

class _SalesShellState extends State<SalesShell> {
  int _selectedIndex = 0;

  // Maintain separate navigation keys for each tab to enable
  // independent navigation stacks
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
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
          },
          child: Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                // Home Tab
                _buildTabNavigator(
                  0,
                  (context) => const HomeScreen(),
                ),

                // Orders Tab
                _buildTabNavigator(
                  1,
                  (context) => const OrdersScreen(),
                ),

                // Queries Tab
                _buildTabNavigator(
                  2,
                  (context) => const QueriesScreen(),
                ),

                // Profile Tab
                _buildTabNavigator(
                  3,
                  (context) => const ProfileScreen(),
                ),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              backgroundColor: const Color(0xFFE8F5E9),
              selectedItemColor: const Color(0xFF2C5F2D),
              unselectedItemColor: Colors.grey,
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              onTap: (index) {
                // If tapping on the already selected tab and can pop,
                // pop to the root of that tab
                if (index == _selectedIndex &&
                    _navigatorKeys[index].currentState!.canPop()) {
                  _navigatorKeys[index].currentState!.popUntil((route) => route.isFirst);
                } else {
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
                  icon: Icon(Icons.question_answer),
                  label: 'Queries',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
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