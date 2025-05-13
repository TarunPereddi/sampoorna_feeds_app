import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/item.dart';
import '../../../services/api_service.dart';

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
    // Implement pagination if needed
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Could load more items here if pagination is implemented
    }
  }
  
  Future<void> _loadItems({String? searchQuery}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (searchQuery != null) _isSearching = true;
    });
    
    try {
      final itemsData = await _apiService.getItems(
        locationCode: widget.locationCode,
        searchQuery: searchQuery,
      );
      
      setState(() {
        _items = itemsData.map((json) => Item.fromJson(json)).toList();
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
  
  void _performSearch() {
    if (_isSearching) return;
    
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    
    _searchDebounce = Timer(const Duration(milliseconds: 100), () {
      _loadItems(searchQuery: _searchController.text.isEmpty ? null : _searchController.text);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Item'),
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
          
          // Loading indicator for search
          if (_isSearching)
            const LinearProgressIndicator(),
          
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
                    : ListView.builder(
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
                            subtitle: Text('Unit Price: ₹${item.unitPrice.toStringAsFixed(2)}'),
                            tileColor: isSelected ? Colors.green.withOpacity(0.1) : null,
                            onTap: () {
                              Navigator.pop(context, item);
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