import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/common_app_bar.dart';
import 'create_order_screen.dart';
import 'order_list_view.dart';
import 'order_table_view.dart';

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
  bool _isFilterExpanded = false;

  // For handling pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _isLoading = false;

  // Status filter options
  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Processing',
    'Completed',
    'Cancelled',
  ];

  // Search controller
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Mock data for orders - will be replaced with API data
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

  @override
  void initState() {
    super.initState();
    _searchController.text = _searchQuery;

    // Add scroll listener for infinite scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _loadMoreOrders();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Load more orders when scrolling to bottom (for pagination)
  Future<void> _loadMoreOrders() async {
    // This would be an API call in a real app
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _currentPage++;
        _isLoading = false;
      });
    }
  }

  // Refresh orders (e.g., on pull-to-refresh)
  Future<void> _refreshOrders() async {
    // This would be an API call in a real app
    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _currentPage = 1;
      _isLoading = false;
    });
  }

  // Apply filters to orders list
  List<Map<String, dynamic>> _getFilteredOrders() {
    return _allOrders.where((order) {
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
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
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
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    // Get filtered orders based on applied filters
    final filteredOrders = _getFilteredOrders();

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Orders',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshOrders,
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
            _refreshOrders();
          });
        },
        backgroundColor: const Color(0xFF008000),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(),

            // Advanced filters section
            _buildAdvancedFilters(isSmallScreen),

            // Orders list or empty state
            Expanded(
              child: filteredOrders.isEmpty
                  ? _buildEmptyState()
                  : Padding(
                padding: const EdgeInsets.all(16),
                child: isSmallScreen
                    ? OrderListView(
                  orders: filteredOrders,
                  scrollController: _scrollController,
                )
                    : OrderTableView(
                  orders: filteredOrders,
                  scrollController: _scrollController,
                ),
              ),
            ),

            // Loading indicator for pagination
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
  // Build the search bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Order ID or Customer',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
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
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
              color: _isFilterExpanded ? const Color(0xFF008000) : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
              });
            },
            tooltip: 'Toggle Filters',
          ),
        ],
      ),
    );
  }

  // Build the advanced filters section
  Widget _buildAdvancedFilters(bool isSmallScreen) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isFilterExpanded ? (isSmallScreen ? 270 : 180) : 0,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Advanced Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status and Date Filter Row(s)
                  if (isSmallScreen)
                  // Small screen - stack vertically
                    Column(
                      children: [
                        // Status Dropdown
                        _buildStatusDropdown(),
                        const SizedBox(height: 16),
                        // Date Range Pickers
                        _buildDateRangePickers(),
                        const SizedBox(height: 16),
                        // Filter Actions
                        _buildFilterActions(),
                      ],
                    )
                  else
                  // Larger screen - place side by side
                    Column(
                      children: [
                        Row(
                          children: [
                            // Status Dropdown
                            Expanded(child: _buildStatusDropdown()),
                            const SizedBox(width: 16),
                            // Date Range Pickers
                            Expanded(
                              flex: 2,
                              child: _buildDateRangePickers(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Filter Actions
                        _buildFilterActions(),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build the status dropdown filter
  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
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
    );
  }

  // Build the date range pickers
  Widget _buildDateRangePickers() {
    return Row(
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _fromDate != null
                          ? DateFormat('dd/MM/yyyy').format(_fromDate!)
                          : 'From Date',
                      style: TextStyle(
                        color: _fromDate != null ? Colors.black : Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.calendar_today, size: 16),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _toDate != null
                          ? DateFormat('dd/MM/yyyy').format(_toDate!)
                          : 'To Date',
                      style: TextStyle(
                        color: _toDate != null ? Colors.black : Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.calendar_today, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build the filter action buttons
  Widget _buildFilterActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedStatus = 'All';
              _fromDate = null;
              _toDate = null;
            });
          },
          child: const Text('Reset'),
        ),
      ],
    );
  }

  // Build the empty state when no orders match filters
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 70,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found matching your filters',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedStatus = 'All';
                _searchController.clear();
                _searchQuery = '';
                _fromDate = null;
                _toDate = null;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }
}