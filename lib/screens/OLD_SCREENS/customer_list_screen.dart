// import 'package:flutter/material.dart';
// import '../../widgets/app_layout.dart';
// import 'customer_detail_screen.dart';

// class CustomerListScreen extends StatefulWidget {
//   const CustomerListScreen({super.key});

//   @override
//   State<CustomerListScreen> createState() => _CustomerListScreenState();
// }

// class _CustomerListScreenState extends State<CustomerListScreen> {
//   // For handling bottom navigation
//   int _selectedIndex = 0;

//   void _onTabChanged(int index) {
//     if (index != 0) {
//       // If not on the home tab, navigate back to home screen
//       Navigator.pop(context);
//       // Note: In a real app with proper navigation, you'd navigate directly
//       // to the appropriate tab instead of just popping
//     } else {
//       setState(() {
//         _selectedIndex = index;
//       });
//     }
//   }

//   // Mock data for customer list
//   final List<Map<String, dynamic>> customers = [
//     {
//       'name': 'B.K. Enterprises',
//       'id': 'SMSM39724',
//       'isActive': true,
//     },
//     {
//       'name': 'B.K. Enterprises',
//       'id': 'SMSM39724',
//       'isActive': false,
//     },
//     {
//       'name': 'Prajjawal Pandit Enterprises Pvt...',
//       'id': 'SMSM39724',
//       'isActive': false,
//     },
//     {
//       'name': 'Prajjawal Pandit Enterprises Pvt...',
//       'id': 'SMSM39724',
//       'isActive': false,
//     },
//     {
//       'name': 'Prajjawal Pandit Enterprises Pvt...',
//       'id': 'SMSM39724',
//       'isActive': false,
//     },
//     {
//       'name': 'Prajjawal Pandit Enterprises Pvt...',
//       'id': 'SMSM39724',
//       'isActive': false,
//     },
//     {
//       'name': 'Prajjawal Pandit Enterprises Pvt...',
//       'id': 'SMSM39724',
//       'isActive': false,
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return AppLayout(
//       currentIndex: _selectedIndex,
//       onTabChanged: _onTabChanged,
//       body: _buildCustomerListContent(),
//     );
//   }

//   Widget _buildCustomerListContent() {
//     return Column(
//       children: [
//         // Filters section
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Filters',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Container(
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFE8F5E9),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: IconButton(
//                   icon: const Icon(Icons.add, color: Color(0xFF008000)),
//                   onPressed: () {
//                     // Add filter functionality
//                   },
//                   iconSize: 18,
//                   padding: EdgeInsets.zero,
//                   constraints: const BoxConstraints(
//                     minWidth: 24,
//                     minHeight: 24,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         // Customer list
//         Expanded(
//           child: ListView.builder(
//             itemCount: customers.length,
//             itemBuilder: (context, index) {
//               final customer = customers[index];
//               final isActive = customer['isActive'] as bool;

//               return InkWell(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const CustomerDetailScreen(),
//                     ),
//                   );
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: isActive ? const Color(0xFFE8F5E9) : Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       // Avatar circle
//                       Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: isActive ? const Color(0xFF008000) : Colors.grey.shade300,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       // Customer info
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               customer['name'] as String,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             Text(
//                               customer['id'] as String,
//                               style: TextStyle(
//                                 color: Colors.grey.shade600,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }