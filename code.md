# Sampoorna Feeds App Documentation

## Project Structure (lib folder)

```
lib/
├── main.dart
├── widgets/
│   ├── app_layout.dart
│   └── comming_soon_screen.dart
├── screens/
│   ├── customer/
│   │   └── customer_shell.dart
│   ├── login/
│   │   └── login_screen.dart
│   ├── OLD_SCREENS/
│   │   ├── customer_detail_screen.dart
│   │   ├── customer_list_screen.dart
│   │   ├── generate_report_screen.dart
│   │   ├── home_screen.dart
│   │   └── login_screen.dart
│   ├── sales/
│   │   └── sales_shell.dart
│   └── vendor/
│       ├── vendor_shell.dart
│       ├── home/
│       │   └── vendor_home_screen.dart
│       ├── orders/
│       │   ├── vendor_orders_screen.dart
│       │   └── vendor_order_detail_screen.dart
│       ├── queries/
│       │   ├── vendor_queries_screen.dart
│       │   └── vendor_query_detail_screen.dart
│       └── profile/
│           └── vendor_profile_screen.dart
├── api/
│   └── endpoints/        # Empty folder for API endpoints
├── config/              # Empty folder for app configuration
├── models/             # Empty folder for data models
├── navigation/         # Empty folder for navigation logic
├── services/          # Empty folder for services
└── utils/            # Empty folder for utilities
```

## Code Files

### Main Application File

**main.dart**
```dart
import 'package:flutter/material.dart';
import 'screens/login/login_screen.dart';
import 'screens/customer/customer_shell.dart';
import 'screens/vendor/vendor_shell.dart';
import 'screens/sales/sales_shell.dart';

void main() {
  runApp(const SampoornaFeedsApp());
}

class SampoornaFeedsApp extends StatelessWidget {
  const SampoornaFeedsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sampoorna Feeds',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF008000),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008000),
          primary: const Color(0xFF008000),
          background: Colors.white,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/customer': (context) => const CustomerShell(),
        '/vendor': (context) => const VendorShell(),
        '/sales': (context) => const SalesShell(),
      },
    );
  }
}
```

### Widget Files

#### app_layout.dart
```dart
import 'package:flutter/material.dart';

class AppLayout extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onTabChanged;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppLayout({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTabChanged,
    this.title,
    this.actions,
    this.floatingActionButton,
  });

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
            Text(
              title ?? 'Sampoorna Feeds',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: actions ?? [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFE8F5E9),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: onTabChanged,
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
      floatingActionButton: floatingActionButton,
    );
  }
}
```

#### comming_soon_screen.dart
```dart
import 'package:flutter/material.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.icon,
    this.message = 'This feature is coming soon!',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'We are working hard to bring you this feature.\nCheck back soon!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

### Screen Files

#### Login Screen

**login_screen.dart**
```dart
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedPersona = 'customer'; // Default selection

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and app name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 50,
                        width: 50,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sampoorna Feeds',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Login form
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              prefixIcon: const Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              prefixIcon: const Icon(Icons.lock),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Role Selection
                          const Text(
                            'Select Your Role',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                _buildPersonaSegment('Customer', 'customer', Icons.people),
                                _buildPersonaSegment('Vendor', 'vendor', Icons.store),
                                _buildPersonaSegment('Sales', 'sales', Icons.business_center),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/$_selectedPersona',
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonaSegment(String title, String value, IconData icon) {
    bool isSelected = _selectedPersona == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPersona = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

#### Customer Shell

**customer_shell.dart**
```dart
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
```

#### Sales Shell

**sales_shell.dart**
```dart
import 'package:flutter/material.dart';
import '../../widgets/comming_soon_screen.dart';

/// Shell for the Sales persona that displays "Coming Soon" screens.
class SalesShell extends StatefulWidget {
  const SalesShell({super.key});

  @override
  State<SalesShell> createState() => _SalesShellState();
}

class _SalesShellState extends State<SalesShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home Tab - Coming Soon
          ComingSoonScreen(
            title: 'Sales Dashboard',
            icon: Icons.home,
            message: 'Sales Dashboard Coming Soon',
          ),

          // Orders Tab - Coming Soon
          ComingSoonScreen(
            title: 'Sales Orders',
            icon: Icons.shopping_cart,
            message: 'Order Management Coming Soon',
          ),

          // Queries Tab - Coming Soon
          ComingSoonScreen(
            title: 'Sales Queries',
            icon: Icons.question_answer,
            message: 'Query System Coming Soon',
          ),

          // Profile Tab - Coming Soon
          ComingSoonScreen(
            title: 'Sales Profile',
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
```

### Vendor Screens

#### Vendor Shell

**vendor_shell.dart**
```dart
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
```

#### Vendor Home Screen

**vendor_home_screen.dart**
```dart
import 'package:flutter/material.dart';

class VendorHomeScreen extends StatelessWidget {
  const VendorHomeScreen({super.key});

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
              'Vendor Dashboard',
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
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Show notifications
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment summary card
            _buildPaymentSummaryCard(context),

            const SizedBox(height: 24),

            // Latest Orders Section
            Row(
              children: [
                const Text(
                  'Latest Orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Order cards
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return _buildOrderCard(
                    context,
                    orderNo: 'PO-123${index + 1}',
                    date: '15 Apr 2025',
                    amount: '₹${(index + 1) * 10000}',
                    status: index == 0 ? 'Pending Confirmation' : 'In Progress',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryCard(BuildContext context) {
    return Card(
      color: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Payment Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '₹1,75,000',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Total Outstanding',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('Next Payment', '₹50,000'),
                _buildInfoItem('Due Date', '30 Apr 2025'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(
    BuildContext context, {
    required String orderNo,
    required String date,
    required String amount,
    required String status,
  }) {
    final isPending = status == 'Pending Confirmation';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFFE8F5E9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    color: isPending ? Colors.orange : Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
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
                        orderNo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        date,
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
                      amount,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPending ? Colors.orange : Theme.of(context).primaryColor,
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
            if (isPending)
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
    );
  }
}
```

#### Vendor Order Detail Screen

**vendor_order_detail_screen.dart**
```dart
import 'package:flutter/material.dart';

class VendorOrderDetailScreen extends StatelessWidget {
  final String orderId;

  const VendorOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> orderDetails = {
      'id': orderId,
      'date': '15 Apr 2025',
      'customer': 'Sampoorna Feeds',
      'status': 'Pending',
      'amount': '₹25,000',
      'deliveryDate': '25 Apr 2025',
      'items': [
        {
          'name': 'Chicken Feed Type A',
          'quantity': '500 kg',
          'price': '₹12,500',
        },
        {
          'name': 'Protein Supplement',
          'quantity': '250 kg',
          'price': '₹7,500',
        },
        {
          'name': 'Mineral Mix',
          'quantity': '100 kg',
          'price': '₹5,000',
        },
      ],
      'billingAddress': 'Sampoorna Feeds, Main Road, Industrial Area, Delhi',
      'shippingAddress': 'Sampoorna Feeds Warehouse, Sector 5, Delhi',
      'paymentTerms': 'Net 30 days',
    };

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
              'Order Details',
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
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: () {
              // Print order details
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(context, orderDetails),
            const SizedBox(height: 24),
            // ... Order items section
            const Text(
              'Order Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildOrderItems(orderDetails['items']),
            // ... Addresses and payment sections
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildAddressCard(
                    'Billing Address',
                    orderDetails['billingAddress'],
                    Icons.business,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAddressCard(
                    'Shipping Address',
                    orderDetails['shippingAddress'],
                    Icons.local_shipping,
                  ),
                ),
              ],
            ),
            // ... Payment information and action buttons
          ],
        ),
      ),
    );
  }

  // Helper methods for building different sections of the screen
  Widget _buildOrderHeader(BuildContext context, Map<String, dynamic> details) {
    // ... Header building logic
  }

  Widget _buildInfoRow(String label, String value) {
    // ... Info row building logic
  }

  Widget _buildOrderItems(List<dynamic> items) {
    // ... Order items list building logic
  }

  Widget _buildAddressCard(String title, String address, IconData icon) {
    // ... Address card building logic
  }

  Widget _buildPaymentDetails(Map<String, dynamic> details) {
    // ... Payment details building logic
  }

  void _showAcceptDialog(BuildContext context) {
    // ... Accept order dialog logic
  }

  void _showDeclineDialog(BuildContext context) {
    // ... Decline order dialog logic
  }
}
```

#### Vendor Queries Screen

**vendor_queries_screen.dart**
```dart
import 'package:flutter/material.dart';
import 'vendor_query_detail_screen.dart';

class VendorQueriesScreen extends StatefulWidget {
  const VendorQueriesScreen({super.key});

  @override
  State<VendorQueriesScreen> createState() => _VendorQueriesScreenState();
}

class _VendorQueriesScreenState extends State<VendorQueriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
              'Queries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search queries...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQueriesList('Active'),
                _buildQueriesList('Resolved'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          _showNewQueryDialog(context);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Helper methods for building different sections of the screen
  Widget _buildQueriesList(String status) {
    final String searchText = _searchController.text.toLowerCase();
    final List<Map<String, dynamic>> allQueries = _generateMockQueries(status);
    final List<Map<String, dynamic>> filteredQueries = allQueries
        .where((query) {
          return query['subject'].toLowerCase().contains(searchText) ||
              query['id'].toLowerCase().contains(searchText);
        })
        .toList();

    return filteredQueries.isEmpty
        ? _buildEmptyState(status)
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredQueries.length,
            itemBuilder: (context, index) {
              final query = filteredQueries[index];
              return _buildQueryCard(context, query, status);
            },
          );
  }

  // ... Helper methods for building UI components and managing state ...
  Widget _buildEmptyState(String status) {
    // ... Empty state UI logic
  }

  Widget _buildQueryCard(BuildContext context, Map<String, dynamic> query, String status) {
    // ... Query card UI logic
  }

  Color _getPriorityColor(String priority) {
    // ... Priority color logic
  }

  List<Map<String, dynamic>> _generateMockQueries(String status) {
    // ... Mock data generation logic
  }

  void _showNewQueryDialog(BuildContext context) {
    // ... New query dialog logic
  }
}
```

#### Vendor Query Detail Screen

**vendor_query_detail_screen.dart**
```dart
import 'package:flutter/material.dart';

class VendorQueryDetailScreen extends StatefulWidget {
  final String queryId;

  const VendorQueryDetailScreen({
    super.key,
    required this.queryId,
  });

  @override
  State<VendorQueryDetailScreen> createState() => _VendorQueryDetailScreenState();
}

class _VendorQueryDetailScreenState extends State<VendorQueryDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  late Map<String, dynamic> _queryDetails;
  late List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();
    _loadQueryDetails();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _loadQueryDetails() {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call to fetch query details
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _queryDetails = _getMockQueryDetails();
        _messages = _getMockMessages();
        _isLoading = false;
      });
    });
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
              'Query Details',
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
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildQueryDetailsCard(),
                Expanded(
                  child: _buildMessagesList(),
                ),
                if (_queryDetails['status'] == 'Active')
                  _buildMessageInput(),
              ],
            ),
    );
  }

  // Helper methods for building different sections of the screen
  Widget _buildQueryDetailsCard() {
    // ... Query details card building logic
  }

  Widget _buildMessagesList() {
    // ... Messages list building logic
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isFromMe) {
    // ... Message bubble building logic
  }

  Widget _buildMessageInput() {
    // ... Message input building logic
  }

  void _sendMessage() {
    // ... Message sending logic
  }

  void _showOptionsMenu(BuildContext context) {
    // ... Options menu logic
  }

  void _markAsResolved() {
    // ... Mark as resolved logic
  }

  void _reopenQuery() {
    // ... Reopen query logic
  }

  Color _getPriorityColor(String priority) {
    // ... Priority color logic
  }

  Map<String, dynamic> _getMockQueryDetails() {
    // ... Mock query details generation logic
  }

  List<Map<String, dynamic>> _getMockMessages() {
    // ... Mock messages generation logic
  }
}
```

#### Vendor Profile Screen

**vendor_profile_screen.dart**
```dart
import 'package:flutter/material.dart';
import '../../../screens/login/login_screen.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final Map<String, dynamic> _vendorData = {
    'name': 'Agrotech Supplies Pvt Ltd',
    'code': 'VEN00123',
    'email': 'contact@agrotechsupplies.com',
    'phone': '+91 9876543210',
    'gst': 'GST29384756HSD873',
    'pan': 'ABCDE1234F',
    'address': {
      'street': '42, Industrial Area, Phase 2',
      'city': 'Bangalore',
      'state': 'Karnataka',
      'pincode': '560058',
    },
    'bankDetails': {
      'accountName': 'Agrotech Supplies Pvt Ltd',
      'accountNumber': 'XXXX XXXX 5678',
      'ifsc': 'HDFC0001234',
      'branch': 'Bangalore Main Branch',
    },
    'joinedDate': '10 Jan 2022',
    'status': 'Active',
    'rating': 4.5,
  };

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
              'Profile',
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
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              _showEditProfileDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business Information
                  _buildSectionTitle('Business Information'),
                  _buildInfoCard([
                    _buildInfoItem('Business Name', _vendorData['name']),
                    _buildInfoItem('Vendor Code', _vendorData['code']),
                    _buildInfoItem('GSTIN', _vendorData['gst']),
                    _buildInfoItem('PAN', _vendorData['pan']),
                    _buildInfoItem('Joined On', _vendorData['joinedDate']),
                  ]),

                  const SizedBox(height: 24),

                  // Contact Information
                  _buildSectionTitle('Contact Information'),
                  _buildInfoCard([
                    _buildInfoItem('Email', _vendorData['email']),
                    _buildInfoItem('Phone', _vendorData['phone']),
                    _buildInfoItem('Address',
                        '${_vendorData['address']['street']}, ${_vendorData['address']['city']}, '
                        '${_vendorData['address']['state']} - ${_vendorData['address']['pincode']}'),
                  ]),

                  const SizedBox(height: 24),

                  // Bank Details
                  _buildSectionTitle('Bank Details'),
                  _buildInfoCard([
                    _buildInfoItem('Account Name', _vendorData['bankDetails']['accountName']),
                    _buildInfoItem('Account Number', _vendorData['bankDetails']['accountNumber']),
                    _buildInfoItem('IFSC Code', _vendorData['bankDetails']['ifsc']),
                    _buildInfoItem('Branch', _vendorData['bankDetails']['branch']),
                  ]),

                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showLogoutDialog(context);
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('Logout', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for building different sections of the screen
  Widget _buildProfileHeader() {
    // ... Profile header building logic
  }

  Widget _buildSectionTitle(String title) {
    // ... Section title building logic
  }

  Widget _buildInfoCard(List<Widget> children) {
    // ... Info card building logic
  }

  Widget _buildInfoItem(String label, String value) {
    // ... Info item building logic
  }

  void _showEditProfileDialog(BuildContext context) {
    // ... Edit profile dialog logic
  }

  void _showLogoutDialog(BuildContext context) {
    // ... Logout dialog logic
  }
}
```

### Deprecated Screens (OLD_SCREENS)

These screens are from a previous version of the app and are kept for reference.

#### Customer Detail Screen
```dart
// Old implementation of customer detail screen
// Shows customer profile with quick action buttons for orders, queries, and info
// Includes contact information display
```

#### Customer List Screen
```dart
// Old implementation of customer list screen
// Features:
// - Filter functionality
// - List of customers with active status indicators
// - Navigation to customer details
```

#### Generate Report Screen
```dart
// Old implementation of report generation
// Features:
// - Customer selection
// - Report type selection (Sales, Inventory, Financial)
// - Date range picker
// - Report generation functionality
```

#### Home Screen
```dart
// Old implementation of main home screen
// Features:
// - Quick actions (Customers, Generate Report)
// - Updates section with notification count
// - Profile screen with user info and settings
```

#### Login Screen (Old Version)
```dart
// Old implementation of login screen
// Features:
// - Username/password authentication
// - Role selection (Customer, Vendor, Sales)
// - Persona-based navigation
```

The OLD_SCREENS folder contains previous implementations that have been replaced by the new modular approach with separate shells for each user type (customer, vendor, sales). These files are kept for reference and show the evolution of the app's architecture from a single-flow application to a role-based, modular structure.