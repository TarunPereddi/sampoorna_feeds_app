import 'package:flutter/material.dart';
import '../../widgets/comming_soon_screen.dart';

/// Shell for the Customer persona that displays "Coming Soon" screens.
class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home Tab - Coming Soon
          ComingSoonScreen(
            title: 'Customer Home',
            icon: Icons.home,
            message: 'Customer Portal Coming Soon',
          ),

          // Orders Tab - Coming Soon
          ComingSoonScreen(
            title: 'Customer Orders',
            icon: Icons.shopping_cart,
            message: 'Order Management Coming Soon',
          ),

          // Queries Tab - Coming Soon
          ComingSoonScreen(
            title: 'Customer Queries',
            icon: Icons.question_answer,
            message: 'Query System Coming Soon',
          ),

          // Profile Tab - Coming Soon
          ComingSoonScreen(
            title: 'Customer Profile',
            icon: Icons.person,
            message: 'Profile Management Coming Soon',
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
          setState(() {
            _selectedIndex = index;
          });
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
    );
  }
}