import 'package:flutter/material.dart';
import '../../../models/state.dart';
import '../../../services/api_service.dart';
import '../../../utils/app_colors.dart';

class StateSelectionScreen extends StatefulWidget {
  final StateModel? initialSelection;
  
  const StateSelectionScreen({
    Key? key,
    this.initialSelection,
  }) : super(key: key);
  
  @override
  State<StateSelectionScreen> createState() => _StateSelectionScreenState();
}

class _StateSelectionScreenState extends State<StateSelectionScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<StateModel> _states = [];
  List<StateModel> _filteredStates = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadStates();
    _searchController.addListener(_filterStates);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadStates() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final statesData = await _apiService.getStates();
      setState(() {
        _states = statesData.map((json) => StateModel.fromJson(json)).toList();
        _filterStates(); // Apply any initial filter
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading states: $e')),
      );
    }
  }
  
  void _filterStates() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStates = List.from(_states);
      } else {
        _filteredStates = _states
            .where((state) => 
                state.description.toLowerCase().contains(query) ||
                state.code.toLowerCase().contains(query))
            .toList();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select State',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.grey100,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search states...',
                prefixIcon: Icon(Icons.search, color: AppColors.primaryDark),
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
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // States list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStates.isEmpty
                    ? const Center(
                        child: Text(
                          'No states found',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredStates.length,
                        itemBuilder: (context, index) {
                          final state = _filteredStates[index];
                          final isSelected = widget.initialSelection != null && 
                                          widget.initialSelection!.code == state.code;
                          
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                state.description,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Code: ${state.code}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  if (state.fromPin > 0 && state.toPin > 0)
                                    Text(
                                      'Pin Range: ${(state.fromPin * 1000).toString().padLeft(6, '0')} - ${(state.toPin * 1000 + 999).toString().padLeft(6, '0')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.grey600,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: isSelected 
                                  ? Icon(Icons.check_circle, color: AppColors.primaryDark)
                                  : Icon(Icons.chevron_right, color: AppColors.grey400),
                              onTap: () {
                                Navigator.pop(context, state);
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
