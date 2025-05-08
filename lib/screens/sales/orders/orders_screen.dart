import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common_app_bar.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/sales_order.dart';
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

  // API and data
  final ApiService _apiService = ApiService();
  List<dynamic> _allOrders = [];

  // For handling pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _hasMoreOrders = true;

  // Status filter options
  final List<String> _statusOptions = [
    'All',
    'Released',
    'Open',
    'Completed',
    'Archived',
  ];

  // Search controller
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.text = _searchQuery;

    // Add scroll listener for infinite scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (!_isLoading && _hasMoreOrders) {
          _loadMoreOrders();
        }
      }
    });

    // Initial load of orders
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Load orders from API
  Future<void> _loadOrders() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isInitialLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final salesPerson = authService.currentUser;
      
      if (salesPerson == null) {
        throw Exception('User not authenticated');
      }

      final orders = await _apiService.getSalesOrders(
        salesPersonName: salesPerson.name,
        searchQuery: _searchQuery,
        status: _selectedStatus != 'All' ? _selectedStatus : null,
        fromDate: _fromDate,
        toDate: _toDate,
        limit: _itemsPerPage,
        offset: 0,
      );

      setState(() {
        _allOrders = orders;
        _isLoading = false;
        _isInitialLoading = false;
        _currentPage = 1;
        _hasMoreOrders = orders.length == _itemsPerPage;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isInitialLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading orders: $e')),
        );
      }
    }
  }

  // Load more orders when scrolling to bottom (for pagination)
  Future<void> _loadMoreOrders() async {
    if (_isLoading || !_hasMoreOrders) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final salesPerson = authService.currentUser;
      
      if (salesPerson == null) {
        throw Exception('User not authenticated');
      }

      final offset = _currentPage * _itemsPerPage;
      
      final moreOrders = await _apiService.getSalesOrders(
        salesPersonName: salesPerson.code,
        searchQuery: _searchQuery,
        status: _selectedStatus != 'All' ? _selectedStatus : null,
        fromDate: _fromDate,
        toDate: _toDate,
        limit: _itemsPerPage,
        offset: offset,
      );

      setState(() {
        if (moreOrders.isNotEmpty) {
          _allOrders.addAll(moreOrders);
          _currentPage++;
        }
        _hasMoreOrders = moreOrders.length == _itemsPerPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more orders: $e')),
        );
      }
    }
  }

  // Refresh orders (e.g., on pull-to-refresh)
  Future<void> _refreshOrders() async {
    await _loadOrders();
  }

  // Apply search and filters
  void _applyFilters() {
    _loadOrders();
  }

  // Reset all filters
  void _resetFilters() {
    setState(() {
      _selectedStatus = 'All';
      _searchController.text = '';
      _searchQuery = '';
      _fromDate = null;
      _toDate = null;
    });
    
    _loadOrders();
  }

  // Convert order data to format expected by the list/table views
  List<Map<String, dynamic>> _convertOrdersToViewFormat(List<dynamic> orders) {
    return orders.map((order) {
      // Parse the amount properly
      double amount = 0;
      if (order['Amt_to_Customer'] != null) {
        amount = order['Amt_to_Customer'] is double
            ? order['Amt_to_Customer']
            : double.tryParse(order['Amt_to_Customer'].toString()) ?? 0;
      }
      
      // Parse dates
      String dateStr = order['Order_Date'] != null 
          ? DateFormat('dd/MM/yyyy').format(DateTime.parse(order['Order_Date']))
          : '';
      
      return {
        'id': order['No'] as String,
        'customerName': order['Sell_to_Customer_Name'] ?? order['Sell_to_Customer_No'] ?? 'Unknown',
        'date': dateStr,
        'amount': '₹${amount.toStringAsFixed(0)}',
        'status': order['Status'] as String? ?? 'Unknown',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    // Convert orders to view format
    final viewOrders = _convertOrdersToViewFormat(_allOrders);

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
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _refreshOrders,
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(),

            // Advanced filters section
            _buildAdvancedFilters(isSmallScreen),

            // Orders list or empty state
            Expanded(
              child: _allOrders.isEmpty
                  ? _buildEmptyState()
                  : Padding(
                padding: const EdgeInsets.all(16),
                child: isSmallScreen
                    ? OrderListView(
                  orders: viewOrders,
                  scrollController: _scrollController,
                )
                    : OrderTableView(
                  orders: viewOrders,
                  scrollController: _scrollController,
                ),
              ),
            ),

            // Loading indicator for pagination
            if (_isLoading && !_isInitialLoading)
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
                    _applyFilters();
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
              onSubmitted: (_) => _applyFilters(),
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
          onPressed: _resetFilters,
          child: const Text('Reset'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _applyFilters,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF008000),
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply Filters'),
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
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }
}