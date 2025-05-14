// In lib/screens/sales/orders/edit_order_screen.dart

import 'package:flutter/material.dart';

class EditOrderScreen extends StatefulWidget {
  final String orderNo;
  
  const EditOrderScreen({Key? key, required this.orderNo}) : super(key: key);
  
  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Edit Order',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF2C5F2D),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          // Remove elevation to make it look integrated with the bottom nav
          elevation: 0,
        ),
        // Use a safe area to ensure content doesn't overlap with bottom nav
        body: SafeArea(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Order Edit Screen',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Editing Order: ${widget.orderNo}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
        ),
        // Hardcoded bottom navigation bar to match SalesShell
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFFE8F5E9),
          selectedItemColor: const Color(0xFF2C5F2D),
          unselectedItemColor: Colors.grey,
          currentIndex: 1, // Orders tab is active
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            // If tapping on the Orders tab (index 1), go back since we're already in Orders
            
              Navigator.of(context).pop();
            
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
}