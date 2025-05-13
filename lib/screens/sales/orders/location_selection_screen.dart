import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/location.dart';

class LocationSelectionScreen extends StatefulWidget {
  final List<Location> locations;
  final String? initialSearchText;
  final Location? initialSelection;
  
  const LocationSelectionScreen({
    Key? key,
    required this.locations,
    this.initialSearchText,
    this.initialSelection,
  }) : super(key: key);
  
  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<Location> _filteredLocations = [];
  
  @override
  void initState() {
    super.initState();
    
    // Set initial search text if provided
    if (widget.initialSearchText != null && widget.initialSearchText!.isNotEmpty) {
      _searchController.text = widget.initialSearchText!;
    }
    
    // Initialize filtered list
    _filteredLocations = List.from(widget.locations);
    
    // Add listener for search
    _searchController.addListener(_filterLocations);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _filterLocations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredLocations = List.from(widget.locations);
      } else {
        _filteredLocations = widget.locations
            .where((location) => 
                location.name.toLowerCase().contains(query) ||
                location.code.toLowerCase().contains(query))
            .toList();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: const Color(0xFF008000),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search locations...',
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
          
          // Location List
          Expanded(
            child: _filteredLocations.isEmpty
                ? Center(
                    child: Text(
                      'No locations found',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredLocations.length,
                    itemBuilder: (context, index) {
                      final location = _filteredLocations[index];
                      final isSelected = widget.initialSelection != null && 
                                      widget.initialSelection!.code == location.code;
                      
                      return ListTile(
                        title: Text(
                          '${location.code} - ${location.name}',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        tileColor: isSelected ? Colors.green.withOpacity(0.1) : null,
                        onTap: () {
                          Navigator.pop(context, location);
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