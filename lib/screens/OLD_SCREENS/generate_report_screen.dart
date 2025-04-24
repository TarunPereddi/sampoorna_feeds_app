// import 'package:flutter/material.dart';
// import '../widgets/app_layout.dart';

// class GenerateReportScreen extends StatefulWidget {
//   const GenerateReportScreen({super.key});

//   @override
//   State<GenerateReportScreen> createState() => _GenerateReportScreenState();
// }

// class _GenerateReportScreenState extends State<GenerateReportScreen> {
//   String? selectedCustomer;
//   String? selectedReportType;
//   DateTime? fromDate;
//   DateTime? toDate;

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
//       title: 'Generate Report',
//       body: _buildReportContent(),
//     );
//   }

//   Widget _buildReportContent() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Generate Report',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 24),

//           // Customer Dropdown
//           const Text(
//             'Customer',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             decoration: BoxDecoration(
//               color: const Color(0xFFE8F5E9),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: DropdownButtonFormField<String>(
//               value: selectedCustomer,
//               decoration: const InputDecoration(
//                 contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 border: InputBorder.none,
//                 hintText: 'Select Customer',
//               ),
//               icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF008000)),
//               onChanged: (value) {
//                 setState(() {
//                   selectedCustomer = value;
//                 });
//               },
//               items: ['Customer 1', 'Customer 2', 'Customer 3']
//                   .map((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//             ),
//           ),
//           const SizedBox(height: 16),

//           // Report Type Dropdown
//           const Text(
//             'Report Type',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             decoration: BoxDecoration(
//               color: const Color(0xFFE8F5E9),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: DropdownButtonFormField<String>(
//               value: selectedReportType,
//               decoration: const InputDecoration(
//                 contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 border: InputBorder.none,
//                 hintText: 'Select type',
//               ),
//               icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF008000)),
//               onChanged: (value) {
//                 setState(() {
//                   selectedReportType = value;
//                 });
//               },
//               items: ['Sales Report', 'Inventory Report', 'Financial Report']
//                   .map((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//             ),
//           ),
//           const SizedBox(height: 16),

//           // Date range pickers
//           Row(
//             children: [
//               // From date
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'From date',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     GestureDetector(
//                       onTap: () async {
//                         final DateTime? picked = await showDatePicker(
//                           context: context,
//                           initialDate: fromDate ?? DateTime.now(),
//                           firstDate: DateTime(2020),
//                           lastDate: DateTime(2025),
//                         );
//                         if (picked != null && picked != fromDate) {
//                           setState(() {
//                             fromDate = picked;
//                           });
//                         }
//                       },
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFE8F5E9),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               fromDate != null
//                                   ? '${fromDate!.day}/${fromDate!.month}/${fromDate!.year}'
//                                   : 'Choose date',
//                               style: TextStyle(
//                                 color: fromDate != null ? Colors.black : Colors.grey,
//                               ),
//                             ),
//                             const Icon(Icons.calendar_today, size: 16, color: Color(0xFF008000)),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 16),
//               // To date
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'To date',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     GestureDetector(
//                       onTap: () async {
//                         final DateTime? picked = await showDatePicker(
//                           context: context,
//                           initialDate: toDate ?? DateTime.now(),
//                           firstDate: DateTime(2020),
//                           lastDate: DateTime(2025),
//                         );
//                         if (picked != null && picked != toDate) {
//                           setState(() {
//                             toDate = picked;
//                           });
//                         }
//                       },
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFE8F5E9),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               toDate != null
//                                   ? '${toDate!.day}/${toDate!.month}/${toDate!.year}'
//                                   : 'Choose date',
//                               style: TextStyle(
//                                 color: toDate != null ? Colors.black : Colors.grey,
//                               ),
//                             ),
//                             const Icon(Icons.calendar_today, size: 16, color: Color(0xFF008000)),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 32),

//           // Generate Report Button
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton.icon(
//               onPressed: () {
//                 // Generate report functionality
//               },
//               icon: const Icon(Icons.download, color: Colors.white),
//               label: const Text(
//                 'Generate Report',
//                 style: TextStyle(color: Colors.white),
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF008000),
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }