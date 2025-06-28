import 'package:flutter/material.dart';
import 'home/vendor_home_screen.dart';
import 'orders/vendor_orders_screen.dart';
import 'queries/vendor_queries_screen.dart';
import 'profile/vendor_profile_screen.dart';

/// Shell for the Vendor persona that handles bottom navigation
/// and maintains state across tabs.
class VendorShell extends StatefulWidget {
  const VendorShell({super.key});

  @override
  State<VendorShell> createState() => _VendorShellState();
}

class _VendorShellState extends State<VendorShell> {
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
  Widget build(BuildContext context) {
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
                  (context) => const VendorHomeScreen(),
            ),

            // Orders Tab
            _buildTabNavigator(
              1,
                  (context) => const VendorOrdersScreen(),
            ),

            // Queries Tab
            _buildTabNavigator(
              2,
                  (context) => const VendorQueriesScreen(),
            ),

            // Profile Tab
            _buildTabNavigator(
              3,
                  (context) => const VendorProfileScreen(),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFFE8F5E9),
          selectedItemColor: Theme.of(context).primaryColor,
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
  }

  // Helper method to build a Navigator for each tab
  Widget _buildTabNavigator(int index, WidgetBuilder rootScreenBuilder) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: rootScreenBuilder,
        );
      },
    );
  }
}