import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../widgets/common_app_bar.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/customer.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebouncer;  
  List<Customer> _customers = [];
  String _salesPersonCode = '';
  bool _isLoading = false;
  bool _isSearching = false;
  bool _dataLoaded = false;
  
  // Pagination 
  int _currentPage = 1;
  int _totalItems = 0;
  int _itemsPerPage = 10;
  int _totalPages = 1;
  
  // Filters
  bool _showBlockedOnly = false;
  bool _hideBlocked = false;  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Get sales person code
    final authService = Provider.of<AuthService>(context, listen: false);
    final salesPerson = authService.currentUser;
    if (salesPerson != null) {
      _salesPersonCode = salesPerson.code;
    }
    
    // Add search listener with debouncing
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Only load data if this is the first time
    if (!_dataLoaded) {
      _loadCustomers();
      _dataLoaded = true;
    }
  }
    @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebouncer?.cancel();
    super.dispose();
  }

  // Helper method to format currency values
  String _formatCurrency(double value) {
    final currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');
    return '₹${currencyFormat.format(value)}';
  }

  // Handle search input changes with debouncing
  void _onSearchChanged() {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _performSearch();
      }
    });
  }  // Get filter parameter for API call based on selected filter
  String? _getFilterParameter() {
    if (_showBlockedOnly) {
      return "Blocked ne ''"; // Find customers where blocked field is not empty
    } else if (_hideBlocked) {
      return "Blocked eq ''"; // Find customers where blocked field is empty
    }
    
    return null; // No filter for "All" option
  }

  // Navigate to previous page
  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadCustomers();
    }
  }

  // Navigate to next page
  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadCustomers();
    }
  }  // Load customers from API
  Future<void> _loadCustomers({bool resetPage = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (resetPage) {
        _currentPage = 1;
      }
    });
    
    try {
      final searchQuery = _searchController.text.trim();
      final blockFilter = _getFilterParameter();
      
      final result = await _apiService.getCustomersWithPagination(
        salesPersonCode: _salesPersonCode,
        searchQuery: searchQuery.isEmpty ? null : searchQuery,
        page: _currentPage,
        pageSize: _itemsPerPage,
        blockFilter: blockFilter,
      );      
      setState(() {
        _customers = result.items; // API filters for us
        _totalItems = result.totalCount;
        _totalPages = (_totalItems / _itemsPerPage).ceil();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading customers: $e')),
        );
      }
    }
  }
  
  // Perform search
  void _performSearch() {
    if (_isSearching) return;
    
    setState(() {
      _isSearching = true;
    });
    
    _loadCustomers(resetPage: true).then((_) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  // Clear search
  void _clearSearch() {
    _searchController.clear();
    _performSearch();
  }  // Set filter state and reload data from API
  void _setFilter({required bool showBlockedOnly, required bool hideBlocked}) {
    setState(() {
      _showBlockedOnly = showBlockedOnly;
      _hideBlocked = hideBlocked;
    });
    
    // Reset to page 1 when changing filters
    setState(() {
      _currentPage = 1;
    });
    
    // Load new data with filter applied
    _loadCustomers();
  }

  // Refresh data
  Future<void> _refreshData() async {
    setState(() {
      _currentPage = 1;
    });
    await _loadCustomers();
  }  
  // Navigate to customer detail
  void _navigateToCustomerDetail(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(customerNo: customer.no),
      ),
    );
  }

  // Build pagination controls
  Widget _buildPaginationControls() {
    if (_totalItems == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Total items info
          Text(
            '$_totalItems customers',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Navigation controls
          Row(
            children: [
              // Previous page button
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? _previousPage : null,
                tooltip: 'Previous Page',
                iconSize: 24,
                color: _currentPage > 1 ? const Color(0xFF2C5F2D) : Colors.grey.shade400,
              ),
              
              // Page indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              
              // Next page button
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages ? _nextPage : null,
                tooltip: 'Next Page',
                iconSize: 24,
                color: _currentPage < _totalPages ? const Color(0xFF2C5F2D) : Colors.grey.shade400,
              ),
            ],
          ),
        ],
      ),
    );
  }  
  // Make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone call to $phoneNumber')),
        );
      }
    }
  }

  // Send an email
  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch email to $email')),
        );
      }
    }
  }  // Build filter buttons
  Widget _buildFilterButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // All customers button
          FilterChip(
            label: const Text('All'),
            selected: !_showBlockedOnly && !_hideBlocked,
            onSelected: (_) => _setFilter(showBlockedOnly: false, hideBlocked: false),
            backgroundColor: Colors.grey.shade100,
            selectedColor: const Color(0xFF2C5F2D).withOpacity(0.2),
            checkmarkColor: const Color(0xFF2C5F2D),
            tooltip: 'Show all customers',
          ),
          const SizedBox(width: 8),
          
          // Hide blocked button
          FilterChip(
            label: const Text('Active Only'),
            selected: _hideBlocked,
            onSelected: (_) => _setFilter(showBlockedOnly: false, hideBlocked: true),
            backgroundColor: Colors.grey.shade100,
            selectedColor: Colors.green.shade100,
            checkmarkColor: Colors.green.shade700,
            tooltip: 'Show only active customers',
          ),
          const SizedBox(width: 8),
          
          // Show blocked only button
          FilterChip(
            label: const Text('Blocked Only'),
            selected: _showBlockedOnly,
            onSelected: (_) => _setFilter(showBlockedOnly: true, hideBlocked: false),
            backgroundColor: Colors.grey.shade100,
            selectedColor: Colors.red.shade100,
            checkmarkColor: Colors.red.shade700,
            tooltip: 'Show only blocked customers',
          ),
        ],
      ),
    );
  }
  // Build customer card widget
  Widget _buildCustomerCard(Customer customer, bool isBlocked) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isBlocked ? Colors.red.shade300 : Colors.grey.shade200,
          width: isBlocked ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToCustomerDetail(customer),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isBlocked ? Colors.red.shade50 : Color(0xFF2C5F2D).withOpacity(0.05),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with avatar, name, and status
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isBlocked 
                        ? Colors.red.shade100 
                        : const Color(0xFF2C5F2D).withOpacity(0.1),
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : "?",
                      style: TextStyle(
                        color: isBlocked ? Colors.red.shade700 : const Color(0xFF2C5F2D),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Name and details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isBlocked ? Colors.red.shade800 : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer.no,
                          style: TextStyle(
                            color: isBlocked ? Colors.red.shade600 : Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),                        if (customer.balanceLcy != 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Balance: ${_formatCurrency(customer.balanceLcy)}',
                            style: TextStyle(
                              color: customer.balanceLcy > 0 
                                  ? Colors.red.shade700 
                                  : customer.balanceLcy < 0 
                                      ? Colors.green.shade700 
                                      : Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Status and navigation
                  Column(
                    children: [
                      if (isBlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'BLOCKED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isBlocked ? Colors.red.shade600 : Colors.grey.shade600,
                      ),
                    ],
                  ),
                ],
              ),
              
              // Contact information
              if (customer.phone != null || customer.emailId != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Phone
                    if (customer.phone != null && customer.phone!.isNotEmpty)
                      Expanded(
                        child: InkWell(
                          onTap: () => _makePhoneCall(customer.phone!),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: (isBlocked ? Colors.red.shade50 : const Color(0xFF2C5F2D).withOpacity(0.05)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isBlocked ? Colors.red.shade300 : const Color(0xFF2C5F2D).withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: isBlocked ? Colors.red.shade600 : const Color(0xFF2C5F2D),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    customer.phone!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isBlocked ? Colors.red.shade700 : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    if (customer.phone != null && customer.phone!.isNotEmpty && 
                        customer.emailId != null && customer.emailId!.isNotEmpty)
                      const SizedBox(width: 8),
                    
                    // Email
                    if (customer.emailId != null && customer.emailId!.isNotEmpty)
                      Expanded(
                        child: InkWell(
                          onTap: () => _sendEmail(customer.emailId!),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: (isBlocked ? Colors.red.shade50 : const Color(0xFF2C5F2D).withOpacity(0.05)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isBlocked ? Colors.red.shade300 : const Color(0xFF2C5F2D).withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.email,
                                  size: 16,
                                  color: isBlocked ? Colors.red.shade600 : const Color(0xFF2C5F2D),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    customer.emailId!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isBlocked ? Colors.red.shade700 : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside of input fields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CommonAppBar(
        title: 'Customers',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _refreshData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.grey.shade50,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search customers by name or number...',
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade600),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, size: 18, color: Colors.grey.shade600),
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                if (_isSearching) ...[
                  const SizedBox(width: 16),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C5F2D)),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Filter Buttons
          _buildFilterButtons(),          // Results Summary
          if (_totalItems > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${_customers.length} of $_totalItems customers',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_totalPages > 1)
                    Text(
                      'Page $_currentPage of $_totalPages',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

          // Customer List
          Expanded(
            child: _isLoading && _customers.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C5F2D)),
                        ),
                        SizedBox(height: 16),
                        Text('Loading customers...'),
                      ],
                    ),
                  )
                : _customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No customers found',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Try adjusting your search or filters'
                                  : 'No customers available',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _clearSearch,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2C5F2D),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Clear Search'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : GestureDetector(
                        onPanEnd: (details) {
                          // Improved swipe detection
                          const double threshold = 100.0;
                          const double velocityThreshold = 300.0;
                          
                          final double velocity = details.velocity.pixelsPerSecond.dx;
                          
                          if (velocity.abs() > velocityThreshold) {
                            if (velocity > threshold && _currentPage > 1) {
                              // Swipe right - go to previous page
                              _previousPage();
                            } else if (velocity < -threshold && _currentPage < _totalPages) {
                              // Swipe left - go to next page
                              _nextPage();
                            }
                          }
                        },
                        child: RefreshIndicator(
                          onRefresh: _refreshData,
                          color: const Color(0xFF2C5F2D),
                          child: ListView.builder(
                            itemCount: _customers.length,
                            padding: const EdgeInsets.only(bottom: 16, top: 8),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final customer = _customers[index];
                              final isBlocked = customer.blocked != null && customer.blocked!.trim().isNotEmpty;
                              
                              return _buildCustomerCard(customer, isBlocked);
                            },
                          ),
                        ),
                      ),
          ),          // Pagination controls
          if (_totalPages > 1) _buildPaginationControls(),
        ],
      ),
    ));
  }
}
