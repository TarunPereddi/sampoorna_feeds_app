import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/ship_to.dart';
import '../../../services/api_service.dart';
import 'add_ship_to_screen.dart'; // Import the new screen

class ShipToSelectionScreen extends StatefulWidget {
  final String customerNo;
  final String? initialSearchText;
  final ShipTo? initialSelection;
  
  const ShipToSelectionScreen({
    Key? key,
    required this.customerNo,
    this.initialSearchText,
    this.initialSelection,
  }) : super(key: key);
  
  @override
  State<ShipToSelectionScreen> createState() => _ShipToSelectionScreenState();
}

class _ShipToSelectionScreenState extends State<ShipToSelectionScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
    List<ShipTo> _shipToAddresses = [];
  List<ShipTo> _filteredShipToAddresses = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    // Set initial search text if provided
    if (widget.initialSearchText != null && widget.initialSearchText!.isNotEmpty) {
      _searchController.text = widget.initialSearchText!;
    }
    
    // Load ship-to addresses
    _loadShipToAddresses();
    
    // Add listener for search
    _searchController.addListener(_filterShipToAddresses);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadShipToAddresses() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final shipToData = await _apiService.getShipToAddresses(customerNo: widget.customerNo);
      setState(() {
        _shipToAddresses = shipToData.map((json) => ShipTo.fromJson(json)).toList();
        _filterShipToAddresses(); // Apply any initial filter
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading ship-to addresses: $e')),
      );
    }
  }
  
  void _filterShipToAddresses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredShipToAddresses = List.from(_shipToAddresses);
      } else {
        _filteredShipToAddresses = _shipToAddresses
            .where((shipTo) => 
                shipTo.name.toLowerCase().contains(query) ||
                shipTo.code.toLowerCase().contains(query) ||
                (shipTo.address?.toLowerCase().contains(query) ?? false))
            .toList();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Ship-To Address'),
        backgroundColor: const Color(0xFF008000),
        actions: [
          // Add Ship-To action
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddShipToDialog();
            },
            tooltip: 'Add New Ship-To',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search ship-to addresses...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          
          // Ship-To List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredShipToAddresses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'No ship-to addresses found',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                _showAddShipToDialog();
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add New Ship-To'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF008000),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredShipToAddresses.length,
                        itemBuilder: (context, index) {
                          final shipTo = _filteredShipToAddresses[index];
                          final isSelected = widget.initialSelection != null && 
                                          widget.initialSelection!.code == shipTo.code;
                                          
                          return ListTile(
                            title: Text(
                              '${shipTo.code} - ${shipTo.name}',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              [
                                shipTo.address,
                                shipTo.city,
                                shipTo.state,
                              ].where((s) => s != null && s.isNotEmpty).join(', '),
                            ),
                            tileColor: isSelected ? Colors.green.withOpacity(0.1) : null,
                            onTap: () {
                              Navigator.pop(context, shipTo);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
    void _showAddShipToDialog() {
    // Navigate to the AddShipToScreen instead of showing a dialog
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => AddShipToScreen(
          customerNo: widget.customerNo,
        ),
      ),
    ).then((newShipTo) {
      // Refresh the list when we return
      if (newShipTo != null) {
        _loadShipToAddresses();
      }
    });
  }
}