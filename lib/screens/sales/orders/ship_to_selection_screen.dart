import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/ship_to.dart';
import '../../../services/api_service.dart';
import '../../../utils/app_colors.dart';
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
  final TextEditingController _searchController = TextEditingController();  List<ShipTo> _shipToAddresses = [];
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
    return Scaffold(      appBar: AppBar(
        title: const Text(
          'Select Ship-To Address',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar with Add Button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Search Field - 70% width
                Expanded(
                  flex: 7,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search ship-to addresses...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
                const SizedBox(width: 8),
                // Add Button - 30% width
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showAddShipToDialog();
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add New',
                      style: TextStyle(color: Colors.white),
                    ),                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Ship-To List with improved spacing
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
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Add New Ship-To', style: TextStyle(color: Colors.white)),                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDark,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
                                            return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            elevation: isSelected ? 2 : 1,
                            color: isSelected ? AppColors.primaryDark.withOpacity(0.1) : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected ? AppColors.primaryDark : Colors.transparent,
                                width: isSelected ? 1 : 0,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              title: Text(
                                '${shipTo.code} - ${shipTo.name}',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  shipTo.address,
                                  shipTo.city,
                                  shipTo.state,
                                ].where((s) => s != null && s.isNotEmpty).join(', '),
                                style: const TextStyle(fontSize: 13),
                              ),
                              onTap: () {
                                Navigator.pop(context, shipTo);
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