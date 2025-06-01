import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/item.dart';
import '../../../services/api_service.dart';
import '../../../utils/app_colors.dart';

class ItemSelectionScreen extends StatefulWidget {
  final String locationCode;
  final String? initialSearchText;
  final Item? initialSelection;
  
  const ItemSelectionScreen({
    Key? key,
    required this.locationCode,
    this.initialSearchText,
    this.initialSelection,
  }) : super(key: key);
  
  @override
  State<ItemSelectionScreen> createState() => _ItemSelectionScreenState();
}

class _ItemSelectionScreenState extends State<ItemSelectionScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();  final ScrollController _scrollController = ScrollController();
  
  List<Item> _items = [];
  bool _isLoading = false;
  bool _isSearching = false;
  
  // Pagination 
  int _currentPage = 1;
  int _totalItems = 0;
  int _itemsPerPage = 10;
  int _totalPages = 0;
  
  // For API call debouncing
  Timer? _searchDebounce;
    @override
  void initState() {
    super.initState();
    
    // Set initial search text if provided
    if (widget.initialSearchText != null && widget.initialSearchText!.isNotEmpty) {
      _searchController.text = widget.initialSearchText!;
    }
    
    // Add listener for real-time search
    _searchController.addListener(_onSearchChanged);
    
    // Load initial items
    _loadItems();
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }
    void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _currentPage = 1; // Reset to first page on search
      });
      _loadItems(searchQuery: _searchController.text.isEmpty ? null : _searchController.text);
    });
  }Future<void> _loadItems({String? searchQuery}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (searchQuery != null) _isSearching = true;
    });
    
    try {
      final result = await _apiService.getItemsWithPagination(
        locationCode: widget.locationCode,
        searchQuery: searchQuery,
        page: _currentPage,
        pageSize: _itemsPerPage,
      );
      
      setState(() {
        // Include all items (blocked and non-blocked) but display them differently
        _items = result.items.map((json) => Item.fromJson(json)).toList();
        _totalItems = result.totalCount;
        _totalPages = (_totalItems / _itemsPerPage).ceil();
        _isLoading = false;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading items: $e')),
      );
    }
  }
  
  void _goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage || _isLoading) return;
    
    setState(() {
      _currentPage = page;
    });
    
    _loadItems(searchQuery: _searchController.text.isEmpty ? null : _searchController.text);
  }
  
  void _previousPage() {
    if (_currentPage > 1) {
      _goToPage(_currentPage - 1);
    }
  }
  
  void _nextPage() {
    if (_currentPage < _totalPages) {
      _goToPage(_currentPage + 1);
    }
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Product', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primaryDark,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: _isSearching 
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
            // Loading indicator for search
          if (_isSearching)
            const LinearProgressIndicator(),// Items List
          Expanded(
            child: Stack(
              children: [
                _items.isEmpty && !_isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty 
                                  ? 'No items found for "${_searchController.text}"'
                                  : 'No items found',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 16,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search terms',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final isSelected = widget.initialSelection != null && 
                                          widget.initialSelection!.no == item.no;
                          final isBlocked = item.blocked;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected 
                                    ? AppColors.primary 
                                    : isBlocked 
                                        ? Colors.red
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
                                      '${item.no} - ${item.description}',
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isBlocked ? Colors.red : AppColors.grey900,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (isBlocked)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'BLOCKED',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: isBlocked 
                                  ? const Text(
                                      'This item is currently blocked and cannot be selected',
                                      style: TextStyle(color: Colors.red, fontSize: 12),
                                    )
                                  : null,
                              onTap: isBlocked 
                                  ? () {
                                      // Show message for blocked items
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('This item is blocked and cannot be selected'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  : () {
                                      Navigator.pop(context, item);
                                    },
                            ),
                          );
                        },
                      ),
                // Loading overlay for page changes
                if (_isLoading && _items.isNotEmpty)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                // Full loading for initial load
                if (_isLoading && _items.isEmpty)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
            // Pagination Controls
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: AppColors.grey300, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - Items count
                Text(
                  '$_totalItems items',
                  style: TextStyle(
                    color: AppColors.grey700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                // Right side - Navigation controls
                Row(
                  children: [
                    // Previous button
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: IconButton(
                        onPressed: _currentPage > 1 && !_isLoading ? _previousPage : null,
                        icon: Icon(
                          Icons.chevron_left,
                          color: _currentPage > 1 && !_isLoading 
                              ? AppColors.grey700 
                              : AppColors.grey400,
                        ),
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Page indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.grey300),
                      ),
                      child: Text(
                        '$_currentPage/$_totalPages',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Next button
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: IconButton(
                        onPressed: _currentPage < _totalPages && !_isLoading ? _nextPage : null,
                        icon: Icon(
                          Icons.chevron_right,
                          color: _currentPage < _totalPages && !_isLoading 
                              ? AppColors.grey700 
                              : AppColors.grey400,
                        ),
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );  }
}