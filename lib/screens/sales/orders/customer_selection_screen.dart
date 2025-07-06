import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/customer.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_colors.dart';

class CustomerSelectionScreen extends StatefulWidget {
  final String? initialSearchText;
  final Customer? initialSelection;
  
  const CustomerSelectionScreen({
    Key? key,
    this.initialSearchText,
    this.initialSelection,
  }) : super(key: key);

  
  
  @override
  State<CustomerSelectionScreen> createState() => _CustomerSelectionScreenState();
}

class _CustomerSelectionScreenState extends State<CustomerSelectionScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Customer> _customers = [];
  String _salesPersonCode = '';
  bool _isLoading = false;
  bool _isSearching = false;
  
  // Sales person names cache
  Map<String, String> _salesPersonNames = {};
  
  // Pagination 
  int _currentPage = 1;
  int _totalItems = 0;
  int _itemsPerPage = 10;
  bool _hasMoreItems = true;
  bool _isLoadingMore = false;
  
    // Indian Rupee currency formatter
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );  

  
  @override
  void initState() {
    super.initState();
    
    // Set initial search text if provided
    if (widget.initialSearchText != null && widget.initialSearchText!.isNotEmpty) {
      _searchController.text = widget.initialSearchText!;
    }
    
    // Get sales person code
    final authService = Provider.of<AuthService>(context, listen: false);
    final salesPerson = authService.currentUser;
    if (salesPerson != null) {
      _salesPersonCode = salesPerson.code;
    }
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
    
    // Load initial data
    _loadCustomers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
    void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && !_isLoadingMore && _hasMoreItems) {
        _loadMoreCustomers();
      }
    }
  }
    Future<void> _loadCustomers({String? searchQuery}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _currentPage = 1; // Reset to first page for new searches
      _customers = []; // Clear current list for new searches
    });
      try {
      final result = await _apiService.getCustomersWithPagination(
        salesPersonCode: _salesPersonCode,
        searchQuery: searchQuery,
        page: _currentPage,
        pageSize: _itemsPerPage,
        blockFilter: null, // Show all customers, including blocked ones
      );
      
      setState(() {
        _customers = result.items;
        _totalItems = result.totalCount;
        _hasMoreItems = _customers.length < _totalItems;
        _isLoading = false;
      });
      
      // Fetch sales person names for the customers
      await _fetchSalesPersonNames();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading customers: $e')),
      );
    }
  }
    Future<void> _loadMoreCustomers() async {
    if (_isLoading || _isLoadingMore || !_hasMoreItems) return;
    
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    
    try {
      final result = await _apiService.getCustomersWithPagination(
        salesPersonCode: _salesPersonCode,
        searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
        page: _currentPage,
        pageSize: _itemsPerPage,
        blockFilter: null, // Show all customers, including blocked ones
      );
      
      setState(() {
        _customers.addAll(result.items);
        _hasMoreItems = _customers.length < _totalItems;
        _isLoadingMore = false;
      });
      
      // Fetch sales person names for the new customers
      await _fetchSalesPersonNames();
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--; // Revert page increment on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading more customers: $e')),
      );
    }
  }
  
  void _performSearch() {
    if (_isSearching) return;
    
    setState(() {
      _isSearching = true;
    });
    
    _loadCustomers(searchQuery: _searchController.text.isEmpty ? null : _searchController.text)
        .then((_) {
      setState(() {
        _isSearching = false;
      });
    });
  }
  
  // Fetch sales person names for the current customers
  Future<void> _fetchSalesPersonNames() async {
    try {
      // Extract unique salesperson codes from customers
      final salesPersonCodes = _customers
          .where((customer) => customer.salespersonCode != null && customer.salespersonCode!.isNotEmpty)
          .map((customer) => customer.salespersonCode!)
          .toSet()
          .toList();
      
      if (salesPersonCodes.isNotEmpty) {
        final salesPersonNames = await _apiService.getSalesPersonNames(salesPersonCodes);
        setState(() {
          _salesPersonNames.addAll(salesPersonNames);
        });
      }
    } catch (e) {
      debugPrint('Error fetching sales person names: $e');
      // Don't show error to user as this is not critical
    }
  }
    
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Customer', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primaryDark,
        iconTheme: const IconThemeData(color: AppColors.white),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search customers...',
                      hintStyle: TextStyle(color: AppColors.grey500),
                      prefixIcon: Icon(Icons.search, color: AppColors.grey600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.grey300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.grey300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      filled: true,
                      fillColor: AppColors.white,
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSearching ? null : _performSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.search, color: AppColors.white),
                ),
              ],
            ),
          ),
            // Results Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              border: Border(
                bottom: BorderSide(color: AppColors.grey300, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_alt_outlined, size: 18, color: AppColors.primaryDark),
                    const SizedBox(width: 8),
                    Text(
                      'Results: $_totalItems',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
            // Customer List
          Expanded(
            child: _isLoading && _customers.isEmpty
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 56, color: AppColors.grey400),
                            const SizedBox(height: 16),
                            Text(
                              'No customers found',
                              style: TextStyle(
                                color: AppColors.grey600,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try changing your search criteria',
                              style: TextStyle(color: AppColors.grey500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _customers.length + (_hasMoreItems ? 1 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          if (index == _customers.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            );
                          }
                            final customer = _customers[index];
                          final isSelected = widget.initialSelection != null && 
                                            widget.initialSelection!.no == customer.no;
                          final isBlocked = customer.blocked != null && customer.blocked!.trim().isNotEmpty;
                            return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected 
                                    ? AppColors.primary 
                                    : isBlocked 
                                        ? AppColors.error
                                        : AppColors.grey300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${customer.no} - ${customer.name}',
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isBlocked ? AppColors.error : AppColors.grey900,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (isBlocked)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'BLOCKED: ${customer.blocked!.toUpperCase()}',
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.account_balance_wallet, 
                                          size: 14, 
                                          color: customer.balanceLcy > 0 
                                  ? Colors.red.shade700 
                                  : customer.balanceLcy < 0 
                                      ? Colors.green.shade700 
                                      : Colors.black87,),
                                      const SizedBox(width: 4),
                                      Text(
                            'Balance: ${_currencyFormat.format(customer.balanceLcy)}',
                            style: TextStyle(
                              color: customer.balanceLcy > 0 
                                  ? Colors.red.shade700 
                                  : customer.balanceLcy < 0 
                                      ? Colors.green.shade700 
                                      : Colors.black87,
                              // fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                                    ],
                                  ),
                                  if (customer.responsibilityCenter != null && customer.responsibilityCenter!.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(Icons.business_center, 
                                            size: 14, 
                                            color: AppColors.grey600),
                                        const SizedBox(width: 4),
                                        Text(
                                          'RC: ${customer.responsibilityCenter}',
                                          style: TextStyle(
                                            color: AppColors.grey600,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  // Sales person field
                                  if (customer.salespersonCode != null && customer.salespersonCode!.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(Icons.person, 
                                            size: 14, 
                                            color: AppColors.grey600),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Sales Person: ${_salesPersonNames[customer.salespersonCode] ?? customer.salespersonCode}',
                                          style: TextStyle(
                                            color: AppColors.grey600,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              tileColor: isSelected 
                                  ? AppColors.primaryLight 
                                  : isBlocked 
                                      ? AppColors.errorLight
                                      : AppColors.primaryLight,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onTap: () {
                                // Prevent selecting blocked customers
                                if (isBlocked) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Cannot select blocked customer (${customer.blocked})',
                                        style: const TextStyle(color: AppColors.white),
                                      ),
                                      backgroundColor: AppColors.error,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(context, customer);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}