// import 'package:flutter/material.dart';
// import '../../widgets/app_layout.dart';

// class CustomerDetailScreen extends StatefulWidget {
//   const CustomerDetailScreen({super.key});

//   @override
//   State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
// }

// class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
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

//   @override
//   Widget build(BuildContext context) {
//     return AppLayout(
//       currentIndex: _selectedIndex,
//       onTabChanged: _onTabChanged,
//       body: _buildCustomerDetailContent(),
//     );
//   }

//   Widget _buildCustomerDetailContent() {
//     return Column(
//       children: [
//         // Customer profile header
//         Container(
//           padding: const EdgeInsets.all(16),
//           color: const Color(0xFFE8F5E9),
//           child: Column(
//             children: [
//               // Avatar and name
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     width: 80,
//                     height: 80,
//                     decoration: const BoxDecoration(
//                       color: Colors.green,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               const Text(
//                 'Prajjawal Pandit',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const Text(
//                 'SAM1234',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey,
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // Quick action buttons
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _buildActionButton(context, Icons.shopping_cart, 'Orders'),
//                   _buildActionButton(context, Icons.question_answer, 'Query'),
//                   _buildActionButton(context, Icons.info, 'Info'),
//                 ],
//               ),
//             ],
//           ),
//         ),

//         // Contact information
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               _buildContactItem(Icons.email, 'Email', 'panditprajjawal@gmail.com'),
//               const SizedBox(height: 16),
//               _buildContactItem(Icons.phone, 'Phone', '9876543210'),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton(BuildContext context, IconData icon, String label) {
//     return Column(
//       children: [
//         Container(
//           width: 60,
//           height: 60,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Icon(
//             icon,
//             color: Theme.of(context).primaryColor,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 14,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildContactItem(IconData icon, String label, String value) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//       decoration: BoxDecoration(
//         color: const Color(0xFFE8F5E9),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             color: const Color(0xFF008000),
//             size: 20,
//           ),
//           const SizedBox(width: 12),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey,
//                 ),
//               ),
//               Text(
//                 value,
//                 style: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }