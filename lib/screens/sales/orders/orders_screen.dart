import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common_app_bar.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import 'create_order_screen.dart';
import 'order_list_view.dart';
import 'order_table_view.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  // Tab controller for status tabs
  late TabController _tabController;
  
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
  int _totalPages = 1;
  int _totalRecords = 0;
  final int _itemsPerPage = 10;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  // Status filter options - matching with tabs
  final List<String> _statusTabs = [
    'All',
    'Open', 
    'Pending Approval',
    'Approved',
  ];

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = _searchQuery;
    
    // Initialize tab controller with tabs
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    
    // Add listener to tab controller to reload data when tab changes
    _tabController.addListener(_onTabChanged);

    // Initial load of orders
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }
  
  // Handler for tab changes
  void _onTabChanged() {
    if (_tabController.indexIsChanging || _tabController.index != _statusTabs.indexOf(_selectedStatus)) {
      setState(() {
        _selectedStatus = _statusTabs[_tabController.index];
        // Reset pagination
        _currentPage = 1;
        _allOrders = [];
      });
      // Reload orders with new status filter
      _loadOrders();
    }
  }  // Convert tab index to API status value
  String? _getApiStatusValue(String tabStatus) {
    // Return null for "All" to not filter by status
    if (tabStatus == 'All') return null;
    
    // Map the tab names to actual API status values
    switch (tabStatus) {
      case 'Open': return 'Open';
      case 'Pending Approval': return 'Pending Approval'; // Changed to match exact API value
      case 'Approved': return 'Released'; // Changed to match exact API value
      default: return null;
    }
  }

  // Load orders from API with pagination
  Future<void> _loadOrders() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (_currentPage == 1) {
        _isInitialLoading = true;
      }
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final salesPerson = authService.currentUser;
      
      if (salesPerson == null) {
        throw Exception('User not authenticated');
      }      // Use the updated getSalesOrders method with includeCount=true
      final response = await _apiService.getSalesOrders(
        salesPersonName: salesPerson.name,
        searchQuery: _searchQuery,
        status: _getApiStatusValue(_selectedStatus),
        fromDate: _fromDate,
        toDate: _toDate,
        limit: _itemsPerPage,
        offset: (_currentPage - 1) * _itemsPerPage,
        includeCount: true,
      );
      
      // Extract total count from @odata.count
      final totalCount = response['@odata.count'] as int? ?? 0;
      
      setState(() {
        _allOrders = response['value'] as List;
        _totalRecords = totalCount;
        _totalPages = (totalCount / _itemsPerPage).ceil();
        _isLoading = false;
        _isInitialLoading = false;
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

  // Navigate to previous page
  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadOrders();
    }
  }

  // Navigate to next page
  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadOrders();
    }
  }

  // Refresh orders
  Future<void> _refreshOrders() async {
    setState(() {
      _currentPage = 1;
    });
    await _loadOrders();
  }

  // Apply search and filters
  void _applyFilters() {
    setState(() {
      _currentPage = 1;
      _searchQuery = _searchController.text;
    });
    _loadOrders();
  }

  // Reset all filters
  void _resetFilters() {
    setState(() {
      _searchController.text = '';
      _searchQuery = '';
      _fromDate = null;
      _toDate = null;
      _currentPage = 1;
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
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),          // Status Tabs (below search bar, like in query screen)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorColor: const Color(0xFF008000),
              labelColor: const Color(0xFF008000),
              unselectedLabelColor: Colors.grey.shade700,
              tabs: _statusTabs.map((status) => Tab(text: status)).toList(),
            ),
          ),

          // Advanced filters section
          _buildAdvancedFilters(isSmallScreen),          // Orders list or empty state
          _isInitialLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _statusTabs.map((tabStatus) {
                      // The content will be the same for each tab
                      // TabController handles the switching and state management
                      return RefreshIndicator(
                        onRefresh: _refreshOrders,
                        child: Column(
                          children: [
                            Expanded(
                              child: _allOrders.isEmpty
                                ? _buildEmptyState()
                                : Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: isSmallScreen
                                      ? OrderListView(
                                          orders: viewOrders,
                                          scrollController: ScrollController(),
                                        )
                                      : OrderTableView(
                                          orders: viewOrders,
                                          scrollController: ScrollController(),
                                        ),
                                  ),
                            ),
                            
                            // Pagination controls
                            if (_totalRecords > 0)
                              _buildPaginationControls(),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }
  // Build pagination controls
  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // Changed to start alignment
        children: [
          // Previous page button
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? _previousPage : null,
            tooltip: 'Previous Page',
            iconSize: 24,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          
          // Page indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Page $_currentPage of $_totalPages',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          
          // Next page button
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages ? _nextPage : null,
            tooltip: 'Next Page',
            iconSize: 24,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          
          // Records count - placed after navigation controls
          const SizedBox(width: 12),
          Text(
            '($_totalRecords items)',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
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
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                    _applyFilters();
                  },
                )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          // Trigger search on icon press
                          _applyFilters();
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: (_fromDate != null || _toDate != null) ? const Color(0xFF008000) : Colors.grey,
            ),            onPressed: () {
              // Show filter popup instead of expanding
              _showFilterPopup(context);
            },
            tooltip: 'Filters',
          ),
        ],
      ),
    );
  }
  
  // Show filter popup dialog
  void _showFilterPopup(BuildContext context) {
    // Create temporary date holders for the popup
    DateTime? tempFromDate = _fromDate;
    DateTime? tempToDate = _toDate;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.filter_list, color: Color(0xFF008000)),
                  const SizedBox(width: 8),
                  const Text('Order Filters'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // From Date
                    const Text(
                      'From Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: tempFromDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );

                        if (pickedDate != null) {
                          setState(() {
                            tempFromDate = pickedDate;
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
                            Text(
                              tempFromDate != null
                                  ? DateFormat('dd/MM/yyyy').format(tempFromDate!)
                                  : 'Select From Date',
                              style: TextStyle(
                                color: tempFromDate != null ? Colors.black : Colors.grey.shade600,
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // To Date
                    const Text(
                      'To Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: tempToDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );

                        if (pickedDate != null) {
                          setState(() {
                            tempToDate = pickedDate;
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
                            Text(
                              tempToDate != null
                                  ? DateFormat('dd/MM/yyyy').format(tempToDate!)
                                  : 'Select To Date',
                              style: TextStyle(
                                color: tempToDate != null ? Colors.black : Colors.grey.shade600,
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Reset filters
                    Navigator.pop(context);
                    this.setState(() {
                      _fromDate = null;
                      _toDate = null;
                    });
                    _resetFilters();
                  },
                  child: const Text('Reset'),
                ),
                TextButton(
                  onPressed: () {
                    // Cancel without applying
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Apply filters and close popup
                    Navigator.pop(context);
                    this.setState(() {
                      _fromDate = tempFromDate;
                      _toDate = tempToDate;
                    });
                    _applyFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008000),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Build the advanced filters section
  Widget _buildAdvancedFilters(bool isSmallScreen) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isFilterExpanded ? (isSmallScreen ? 180 : 120) : 0,
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

                  // Date Filter Row(s)
                  if (isSmallScreen)
                  // Small screen - stack vertically
                    Column(
                      children: [
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
                            // Date Range Pickers
                            Expanded(
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
            'No ${_selectedStatus.toLowerCase()} orders found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          if (_searchQuery.isNotEmpty || _fromDate != null || _toDate != null)
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