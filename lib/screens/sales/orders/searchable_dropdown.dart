import 'package:flutter/material.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final T? selectedItem;
  final Function(T?) onChanged;
  final bool required;
  final String Function(T) displayStringForItem;
  final TextEditingController? searchController;
  final Function(String)? onSearchTextChanged;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.items,
    this.selectedItem,
    required this.onChanged,
    this.required = false,
    required this.displayStringForItem,
    this.searchController,
    this.onSearchTextChanged,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  late TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  bool _isDropdownOpen = false;
  List<T> _filteredItems = [];
  OverlayEntry? _overlayEntry;
  bool _isInternalChange = false;

  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ?? TextEditingController();
    _filteredItems = List.from(widget.items);

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _openDropdown();
      } else {
        _closeDropdown();
      }
    });
  }

  @override
  void didUpdateWidget(SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update filtered items if the item list changes
    if (oldWidget.items != widget.items) {
      setState(() {
        _filteredItems = List.from(widget.items);
      });
    }
    
    // Update search controller if it changes
    if (oldWidget.searchController != widget.searchController && 
        widget.searchController != null && 
        _searchController != widget.searchController) {
      _searchController = widget.searchController!;
    }
  }

  @override
  void dispose() {
    // Only dispose the controller if we created it
    if (widget.searchController == null) {
      _searchController.dispose();
    }
    _focusNode.dispose();
    _closeDropdown();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items
            .where((item) => widget.displayStringForItem(item).toLowerCase().contains(query.toLowerCase()))
            .toList();
      }

      // Rebuild the overlay with updated filtered items
      if (_isDropdownOpen) {
        _updateOverlay();
      }
    });
    
    // Call the onSearchTextChanged callback if provided
    if (!_isInternalChange && widget.onSearchTextChanged != null) {
      widget.onSearchTextChanged!(query);
    }
  }

  void _openDropdown() {
    if (_overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildDropdown(size),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
    });
  }

  void _updateOverlay() {
    _overlayEntry?.remove();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildDropdown(size),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    if (mounted) {
      setState(() {
        _isDropdownOpen = false;
      });
    }
  }

  void _selectItem(T item) {
    widget.onChanged(item);
    
    _isInternalChange = true;
    _searchController.clear();
    _isInternalChange = false;
    
    _filteredItems = List.from(widget.items);
    _closeDropdown();
    FocusScope.of(context).unfocus();
  }

  Widget _buildDropdown(Size size) {
    return Positioned(
      width: size.width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: Offset(0, size.height),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: 200,
              minWidth: size.width,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _filteredItems.isEmpty
                ? const ListTile(
              title: Text('No items found'),
              leading: Icon(Icons.info_outline),
            )
                : ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return ListTile(
                  title: Text(widget.displayStringForItem(item)),
                  selected: widget.selectedItem == item,
                  selectedTileColor: const Color(0xFFE8F5E9),
                  onTap: () => _selectItem(item),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.required ? '${widget.label}*' : widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: () {
              if (!_focusNode.hasFocus) {
                FocusScope.of(context).requestFocus(_focusNode);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.selectedItem != null && !_isDropdownOpen
                  ? InputDecorator(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          widget.onChanged(null);
                        },
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
                child: Text(widget.displayStringForItem(widget.selectedItem!)),
              )
                  : TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Search ${widget.label.toLowerCase()}...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixIcon: widget.searchController != null 
                      ? const Icon(Icons.search)
                      : const Icon(Icons.arrow_drop_down),
                ),
                onChanged: _filterItems,
              ),
            ),
          ),
        ),
        if (widget.required && widget.selectedItem == null)
          const Padding(
            padding: EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              'This field is required',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}