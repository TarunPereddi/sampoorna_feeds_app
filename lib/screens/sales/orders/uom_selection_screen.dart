import 'package:flutter/material.dart';
import '../../../models/item_unit_of_measure.dart';

class UomSelectionScreen extends StatefulWidget {
  final List<ItemUnitOfMeasure> uoms;
  final List<String> fallbackUoms;
  final String? initialSearchText;
  final String? selectedUom;
  
  const UomSelectionScreen({
    Key? key,
    required this.uoms,
    required this.fallbackUoms,
    this.initialSearchText,
    this.selectedUom,
  }) : super(key: key);
  
  @override
  State<UomSelectionScreen> createState() => _UomSelectionScreenState();
}

class _UomSelectionScreenState extends State<UomSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<String> _filteredUoms = [];
  
  @override
  void initState() {
    super.initState();
    
    // Set initial search text if provided
    if (widget.initialSearchText != null && widget.initialSearchText!.isNotEmpty) {
      _searchController.text = widget.initialSearchText!;
    }
    
    // Initialize filtered list
    _initializeUomList();
    
    // Add listener for search
    _searchController.addListener(_filterUoms);
  }
  
  void _initializeUomList() {
    // Use API UOMs if available, otherwise fallback
    if (widget.uoms.isNotEmpty) {
      _filteredUoms = widget.uoms.map((uom) => uom.code).toList();
    } else {
      _filteredUoms = List.from(widget.fallbackUoms);
    }
    
    // Apply initial filter if search text exists
    _filterUoms();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _filterUoms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _initializeUomList();
      } else {
        if (widget.uoms.isNotEmpty) {
          _filteredUoms = widget.uoms
              .map((uom) => uom.code)
              .where((code) => code.toLowerCase().contains(query))
              .toList();
        } else {
          _filteredUoms = widget.fallbackUoms
              .where((uom) => uom.toLowerCase().contains(query))
              .toList();
        }
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Unit of Measure'),
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
                hintText: 'Search units...',
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
          
          // UOM List
          Expanded(
            child: _filteredUoms.isEmpty
                ? Center(
                    child: Text(
                      'No units of measure found',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUoms.length,
                    itemBuilder: (context, index) {
                      final uom = _filteredUoms[index];
                      final isSelected = widget.selectedUom == uom;
                      
                      return ListTile(
                        title: Text(
                          uom,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        tileColor: isSelected ? Colors.green.withOpacity(0.1) : null,
                        onTap: () {
                          Navigator.pop(context, uom);
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