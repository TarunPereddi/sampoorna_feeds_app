import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
  
  List<Customer> _customers = [];
  String _salesPersonCode = '';
  bool _isLoading = false;
  bool _isSearching = false;
  bool _dataLoaded = false; // Track if data has been loaded
  
  // Pagination 
  int _currentPage = 1;
  int _totalItems = 0;
  int _itemsPerPage = 8; // Changed to 8 items per page
  int _totalPages = 1;
  
  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs
    @override
  void initState() {
    super.initState();
    
    // Get sales person code
    final authService = Provider.of<AuthService>(context, listen: false);
    final salesPerson = authService.currentUser;
    if (salesPerson != null) {
      _salesPersonCode = salesPerson.code;
    }
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
    _searchController.dispose();
    super.dispose();
  }
  
  // Navigate to previous page
  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadCustomers(searchQuery: _searchController.text.isEmpty ? null : _searchController.text);
    }
  }

  // Navigate to next page
  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadCustomers(searchQuery: _searchController.text.isEmpty ? null : _searchController.text);
    }
  }
  Future<void> _loadCustomers({String? searchQuery}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (searchQuery != null) {
        _currentPage = 1; // Reset to first page for new searches
      }
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
        _totalPages = (_totalItems / _itemsPerPage).ceil();
        _isLoading = false;
      });
      
      // After loading basic customer data, fetch detailed information if we have customers
      if (_customers.isNotEmpty) {
        // Use a small delay to let the UI update before fetching details
        Future.delayed(const Duration(milliseconds: 300), () {
          _fetchCustomerDetails();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading customers: $e')),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page info
          Text(
            '$_totalItems customers',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
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
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: _currentPage > 1 ? const Color(0xFF2C5F2D) : Colors.grey.shade400,
              ),
              
              // Page indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              
              // Next page button
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages ? _nextPage : null,
                tooltip: 'Next Page',
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: _currentPage < _totalPages ? const Color(0xFF2C5F2D) : Colors.grey.shade400,
              ),
            ],
          ),
        ],
      ),
    );
  }  Future<void> _fetchCustomerDetails() async {
    if (_customers.isEmpty) return;
    
    try {
      // Get all customer numbers
      final customerNos = _customers.map((c) => c.no).toList();
      
      // Fetch only email fields for customers
      final detailedCustomers = await _apiService.getCustomerEmails(customerNos);
      
      // Create a map for quick lookup
      final customerEmailMap = {
        for (var customer in detailedCustomers) 
          customer['No'] as String: customer['E_Mail']
      };
      
      // Update customers with email information
      final updatedCustomers = _customers.map((customer) {
        if (customerEmailMap.containsKey(customer.no)) {
          final email = customerEmailMap[customer.no];
          return Customer(
            no: customer.no,
            name: customer.name,
            phone: customer.phone,
            address: customer.address,
            emailId: email != null && email.toString().trim().isNotEmpty ? email.toString() : null,
            city: customer.city,
            stateCode: customer.stateCode,
            gstNo: customer.gstNo,
            panNo: customer.panNo,
            customerPriceGroup: customer.customerPriceGroup,
            balanceLcy: customer.balanceLcy,
          );
        }
        return customer;
      }).toList();
      
      setState(() {
        _customers = updatedCustomers;
      });
    } catch (e) {
      debugPrint('Error updating customer emails: $e');
      // Silently handle error without showing snackbar
    }
  }
    // Make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone call to $phoneNumber')),
      );
    }
  }

  // Send an email
  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch email to $email')),
      );
    }
  }
    @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CommonAppBar(
        title: 'Customers',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () => _loadCustomers(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search customers...',
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade600),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, size: 16, color: Colors.grey.shade600),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                      onSubmitted: (_) => _performSearch(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 42,
                  width: 42,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _performSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C5F2D),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.search, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
            // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Results: $_totalItems',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          // Customer List
          Expanded(
            child: _isLoading && _customers.isEmpty
                ? const Center(child: CircularProgressIndicator())                : _customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No customers found',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 16,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch();
                                },
                                child: const Text('Clear search'),
                              ),
                          ],
                        ),
                      )                    : ListView.builder(
                        itemCount: _customers.length,
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        itemBuilder: (context, index) {
                          final customer = _customers[index];return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Customer name and number row
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: const Color(0xFF2C5F2D).withOpacity(0.1),
                                        child: Text(
                                          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : "?",
                                          style: const TextStyle(
                                            color: Color(0xFF2C5F2D),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              customer.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              customer.no,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward_ios, size: 14),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _navigateToCustomerDetail(customer),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  // Contact info row
                                  Row(
                                    children: [
                                      // Phone section
                                      Expanded(
                                        flex: 1,
                                        child: InkWell(
                                          onTap: customer.phone != null && customer.phone!.isNotEmpty 
                                              ? () => _makePhoneCall(customer.phone!) 
                                              : null,
                                          child: Row(
                                            children: [
                                              const Icon(Icons.phone, size: 14, color: Color(0xFF2C5F2D)),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  customer.phone ?? 'Not Available',
                                                  style: const TextStyle(fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Email section
                                      Expanded(
                                        flex: 1,
                                        child: InkWell(
                                          onTap: customer.emailId != null && customer.emailId!.isNotEmpty 
                                              ? () => _sendEmail(customer.emailId!) 
                                              : null,
                                          child: Row(
                                            children: [
                                              const Icon(Icons.email, size: 14, color: Color(0xFF2C5F2D)),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  customer.emailId ?? 'Not Available',
                                                  style: const TextStyle(fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Pagination controls
          if (_totalItems > 0)
            _buildPaginationControls(),
        ],
      ),
    );
  }
}
