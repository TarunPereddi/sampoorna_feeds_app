import 'package:flutter/material.dart';
import '../../../widgets/common_app_bar.dart';
import 'create_order_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // Filter state
  String _selectedStatus = 'All';
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  // Mock data for orders
  final List<Map<String, dynamic>> _allOrders = [
    {
      'id': 'ORD-2025-001',
      'customerName': 'B.K. Enterprises',
      'date': '14/04/2025',
      'amount': '₹23,500',
      'status': 'Pending',
    },
    {
      'id': 'ORD-2025-002',
      'customerName': 'Prajjawal Enterprises',
      'date': '13/04/2025',
      'amount': '₹18,750',
      'status': 'Completed',
    },
    {
      'id': 'ORD-2025-003',
      'customerName': 'Agro Suppliers Ltd',
      'date': '12/04/2025',
      'amount': '₹31,200',
      'status': 'Processing',
    },
    {
      'id': 'ORD-2025-004',
      'customerName': 'Farm Solutions Inc',
      'date': '11/04/2025',
      'amount': '₹15,800',
      'status': 'Completed',
    },
    {
      'id': 'ORD-2025-005',
      'customerName': 'Green Agro Ltd',
      'date': '10/04/2025',
      'amount': '₹27,350',
      'status': 'Completed',
    },
    {
      'id': 'ORD-2025-006',
      'customerName': 'B.K. Enterprises',
      'date': '09/04/2025',
      'amount': '₹12,800',
      'status': 'Cancelled',
    },
    {
      'id': 'ORD-2025-007',
      'customerName': 'Agro Suppliers Ltd',
      'date': '08/04/2025',
      'amount': '₹45,200',
      'status': 'Processing',
    },
    {
      'id': 'ORD-2025-008',
      'customerName': 'Farm Solutions Inc',
      'date': '07/04/2025',
      'amount': '₹19,600',
      'status': 'Pending',
    },
    {
      'id': 'ORD-2025-009',
      'customerName': 'Prajjawal Enterprises',
      'date': '06/04/2025',
      'amount': '₹33,750',
      'status': 'Completed',
    },
    {
      'id': 'ORD-2025-010',
      'customerName': 'Green Agro Ltd',
      'date': '05/04/2025',
      'amount': '₹29,100',
      'status': 'Completed',
    },
  ];

  // Status filter options
  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Processing',
    'Completed',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    // Apply filters to orders
    List<Map<String, dynamic>> filteredOrders = _allOrders.where((order) {
      // Apply status filter
      if (_selectedStatus != 'All' && order['status'] != _selectedStatus) {
        return false;
      }

      // Apply search filter (case insensitive)
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final idLower = order['id'].toLowerCase();
        final customerLower = order['customerName'].toLowerCase();

        if (!idLower.contains(searchLower) && !customerLower.contains(searchLower)) {
          return false;
        }
      }

      // Apply date filters if set
      if (_fromDate != null || _toDate != null) {
        // Parse the date string (format: dd/MM/yyyy)
        final parts = order['date'].split('/');
        final orderDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );

        if (_fromDate != null && orderDate.isBefore(_fromDate!)) {
          return false;
        }

        if (_toDate != null && orderDate.isAfter(_toDate!)) {
          return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Orders',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // Refresh order data (would fetch from API in a real app)
              setState(() {
                // Reset filters
                _selectedStatus = 'All';
                _searchQuery = '';
                _fromDate = null;
                _toDate = null;
              });
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
          ).then((_) {
            // Refresh orders when returning from create screen
            setState(() {});
          });
        },
        backgroundColor: const Color(0xFF008000),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filters Section
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search and Status Filter Row
                  Row(
                    children: [
                      // Search Field
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by Order ID or Customer',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Status Dropdown
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          items: _statusOptions.map((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date Filter Row
                  Row(
                    children: [
                      // From Date
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _fromDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );

                            if (pickedDate != null) {
                              setState(() {
                                _fromDate = pickedDate;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _fromDate != null
                                      ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}'
                                      : 'From Date',
                                  style: TextStyle(
                                    color: _fromDate != null ? Colors.black : Colors.grey.shade600,
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // To Date
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _toDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );

                            if (pickedDate != null) {
                              setState(() {
                                _toDate = pickedDate;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _toDate != null
                                      ? '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'
                                      : 'To Date',
                                  style: TextStyle(
                                    color: _toDate != null ? Colors.black : Colors.grey.shade600,
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Clear Filters Button
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedStatus = 'All';
                            _searchQuery = '';
                            _fromDate = null;
                            _toDate = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Orders Table
          Expanded(
            child: filteredOrders.isEmpty
                ? const Center(child: Text('No orders found matching your filters'))
                : Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Card(
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(const Color(0xFFE8F5E9)),
                    columns: const [
                      DataColumn(label: Text('Order ID')),
                      DataColumn(label: Text('Customer')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: filteredOrders.map((order) {
                      return DataRow(
                        cells: [
                          DataCell(Text(order['id'] as String)),
                          DataCell(Text(order['customerName'] as String)),
                          DataCell(Text(order['date'] as String)),
                          DataCell(Text(order['amount'] as String)),
                          DataCell(_buildStatusChip(order['status'] as String)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, size: 20),
                                  onPressed: () {
                                    // View order details
                                  },
                                  tooltip: 'View Details',
                                  color: Colors.blue,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () {
                                    // Edit order
                                  },
                                  tooltip: 'Edit Order',
                                  color: Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;

    switch (status) {
      case 'Completed':
        chipColor = Colors.green;
        break;
      case 'Processing':
        chipColor = Colors.blue;
        break;
      case 'Pending':
        chipColor = Colors.orange;
        break;
      case 'Cancelled':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}