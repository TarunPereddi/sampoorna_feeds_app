// import 'package:flutter/material.dart';
// import '../../widgets/app_layout.dart';
// import 'customer_list_screen.dart';
// import '../generate_report_screen.dart';
// import 'login_screen.dart';

// class HomeScreen extends StatefulWidget {
//   final String personaType;

//   const HomeScreen({super.key, required this.personaType});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;

//   void _onTabChanged(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AppLayout(
//       currentIndex: _selectedIndex,
//       onTabChanged: _onTabChanged,
//       body: _buildBody(),
//     );
//   }

//   Widget _buildBody() {
//     switch (_selectedIndex) {
//       case 0:
//         return _buildHomeContent();
//       case 1:
//         return const Center(child: Text('Orders Screen'));
//       case 2:
//         return const Center(child: Text('Queries Screen'));
//       case 3:
//         return _buildProfileScreen();
//       default:
//         return const Center(child: Text('Home Screen'));
//     }
//   }

//   Widget _buildHomeContent() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Quick actions row (Customers, Generate Report)
//           Row(
//             children: [
//               Expanded(
//                 child: InkWell(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => const CustomerListScreen()),
//                     );
//                   },
//                   child: _buildActionCard(
//                     'Customers',
//                     '272',
//                     Icons.people,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: InkWell(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => const GenerateReportScreen()),
//                     );
//                   },
//                   child: _buildActionCard(
//                     'Generate Report',
//                     '',
//                     Icons.description,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           // Updates section
//           Row(
//             children: [
//               const Text(
//                 'Updates',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: Colors.green,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Text(
//                   '23',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           // Update cards
//           Expanded(
//             child: ListView.builder(
//               itemCount: 7,
//               itemBuilder: (context, index) {
//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 8),
//                   color: const Color(0xFFE8F5E9),
//                   child: Container(
//                     height: 60,
//                     width: double.infinity,
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileScreen() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           const CircleAvatar(
//             radius: 50,
//             backgroundColor: Color(0xFF008000),
//             child: Icon(
//               Icons.person,
//               size: 50,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'User Name',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Role: ${widget.personaType.toUpperCase()}',
//             style: const TextStyle(
//               fontSize: 16,
//               color: Colors.grey,
//             ),
//           ),
//           const SizedBox(height: 32),
//           // Profile options
//           _buildProfileOption(Icons.account_circle, 'My Account'),
//           _buildProfileOption(Icons.settings, 'Settings'),
//           _buildProfileOption(Icons.help_outline, 'Help & Support'),
//           _buildProfileOption(Icons.info_outline, 'About'),
//           const Divider(height: 32),
//           // Logout button
//           ElevatedButton.icon(
//             onPressed: () {
//               // Logout and return to login screen
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => const LoginScreen()),
//               );
//             },
//             icon: const Icon(Icons.logout, color: Colors.white),
//             label: const Text('Logout', style: TextStyle(color: Colors.white)),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Theme.of(context).primaryColor,
//               foregroundColor: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileOption(IconData icon, String title) {
//     return ListTile(
//       leading: Icon(icon, color: Theme.of(context).primaryColor),
//       title: Text(title),
//       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//       onTap: () {
//         // Handle option tap
//       },
//     );
//   }

//   Widget _buildActionCard(String title, String count, IconData icon) {
//     return Card(
//       color: const Color(0xFFE8F5E9),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               color: Theme.of(context).primaryColor,
//             ),
//             const SizedBox(width: 8),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 14,
//                   ),
//                 ),
//                 if (count.isNotEmpty)
//                   Text(
//                     count,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }