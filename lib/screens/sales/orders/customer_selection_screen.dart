import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../models/customer.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

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
  
  // Pagination 
  int _currentPage = 1;
  int _totalItems = 0;
  int _itemsPerPage = 10;
  bool _hasMoreItems = true;
  
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
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMoreItems) {
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
      );
      
      setState(() {
        _customers = result.items;
        _totalItems = result.totalCount;
        _hasMoreItems = _customers.length < _totalItems;
        _isLoading = false;
      });
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
    if (_isLoading || !_hasMoreItems) return;
    
    setState(() {
      _isLoading = true;
      _currentPage++;
    });
    
    try {
      final result = await _apiService.getCustomersWithPagination(
        salesPersonCode: _salesPersonCode,
        searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
        page: _currentPage,
        pageSize: _itemsPerPage,
      );
      
      setState(() {
        _customers.addAll(result.items);
        _hasMoreItems = _customers.length < _totalItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Customer'),
        backgroundColor: const Color(0xFF008000),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search customers...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSearching ? null : _performSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008000),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Results: $_totalItems',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_totalItems > 0)
                  Text(
                    'Page $_currentPage of ${(_totalItems / _itemsPerPage).ceil()}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
              ],
            ),
          ),
          
          // Customer List
          Expanded(
            child: _isLoading && _customers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? Center(
                        child: Text(
                          'No customers found',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _customers.length + (_hasMoreItems ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _customers.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                            final customer = _customers[index];
                          final isSelected = widget.initialSelection != null && 
                                            widget.initialSelection!.no == customer.no;
                          final isBlocked = customer.blocked != null && customer.blocked!.trim().isNotEmpty;
                          
                          return ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${customer.no} - ${customer.name}',
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isBlocked ? Colors.red.shade700 : Colors.black,
                                    ),
                                  ),
                                ),                                if (isBlocked)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade600,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'BLOCKED: ${customer.blocked!.toUpperCase()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),                            subtitle: Text(
                              'Balance: ₹${customer.balanceLcy.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isBlocked ? Colors.red.shade600 : Colors.grey.shade600,
                              ),
                            ),                            tileColor: isSelected 
                                ? Colors.green.withOpacity(0.1) 
                                : isBlocked 
                                    ? Colors.red.withOpacity(0.05) 
                                    : Colors.lightGreen.shade50,
                            onTap: () {
                              Navigator.pop(context, customer);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}