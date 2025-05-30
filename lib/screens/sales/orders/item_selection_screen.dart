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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Item> _items = [];
  bool _isLoading = false;
  bool _isSearching = false;
  
  // Pagination 
  int _currentPage = 1;
  int _totalItems = 0;
  int _itemsPerPage = 10;
  bool _hasMoreItems = true;
  bool _isLoadingMore = false;
  
  // For API call debouncing
  Timer? _searchDebounce;
  
  @override
  void initState() {
    super.initState();
    
    // Set initial search text if provided
    if (widget.initialSearchText != null && widget.initialSearchText!.isNotEmpty) {
      _searchController.text = widget.initialSearchText!;
    }
    
    // Add scroll listener for pagination (if implemented)
    _scrollController.addListener(_scrollListener);
    
    // Load initial items
    _loadItems();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }
    void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && !_isLoadingMore && _hasMoreItems) {
        _loadMoreItems();
      }
    }
  }
    Future<void> _loadItems({String? searchQuery}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _currentPage = 1; // Reset to first page for new searches
      _items = []; // Clear current list for new searches
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
        _items = result.items.map((json) => Item.fromJson(json)).toList();
        _totalItems = result.totalCount;
        _hasMoreItems = _items.length < _totalItems;
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
  
  Future<void> _loadMoreItems() async {
    if (_isLoading || _isLoadingMore || !_hasMoreItems) return;
    
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    
    try {
      final result = await _apiService.getItemsWithPagination(
        locationCode: widget.locationCode,
        searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
        page: _currentPage,
        pageSize: _itemsPerPage,
      );
      
      setState(() {
        _items.addAll(result.items.map((json) => Item.fromJson(json)).toList());
        _hasMoreItems = _items.length < _totalItems;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--; // Revert page increment on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading more items: $e')),
      );
    }
  }
    void _performSearch() {
    if (_isSearching) return;
    
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _loadItems(searchQuery: _searchController.text.isEmpty ? null : _searchController.text);
    });
  }
  
  @override
  Widget build(BuildContext context) {    return Scaffold(      appBar: AppBar(
        title: const Text('Select Product', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primaryDark,
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
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),                ElevatedButton(
                  onPressed: _isSearching ? null : _performSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
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
            // Loading indicator for search
          if (_isSearching)
            const LinearProgressIndicator(),
            
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
                    Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primaryDark),
                    const SizedBox(width: 8),
                    Text(
                      'Results: $_totalItems',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Items List
          Expanded(
            child: _isLoading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Text(
                          'No items found',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      )
                    : Stack(
                        children: [
                          ListView.builder(
                            controller: _scrollController,
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final isSelected = widget.initialSelection != null && 
                                              widget.initialSelection!.no == item.no;
                              
                              return ListTile(
                                title: Text(
                                  '${item.no} - ${item.description}',
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                tileColor: isSelected ? Colors.green.withOpacity(0.1) : null,
                                onTap: () {
                                  Navigator.pop(context, item);
                                },
                              );
                            },
                          ),
                          if (_isLoadingMore)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                height: 50,
                                alignment: Alignment.center,
                                color: Colors.black.withOpacity(0.1),
                                child: const CircularProgressIndicator(),
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}