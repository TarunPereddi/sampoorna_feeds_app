import 'package:flutter/material.dart';
import '../../../models/sales_shipment.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/common_app_bar.dart';

class DocumentSelectionScreen extends StatefulWidget {
  final List<SalesShipment> shipments;
  final Function(SalesShipment) onDocumentSelected;

  const DocumentSelectionScreen({
    super.key,
    required this.shipments,
    required this.onDocumentSelected,
  });

  @override
  State<DocumentSelectionScreen> createState() => _DocumentSelectionScreenState();
}

class _DocumentSelectionScreenState extends State<DocumentSelectionScreen> {
  late List<SalesShipment> _filteredShipments;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredShipments = widget.shipments;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();    setState(() {
      if (query.isEmpty) {
        _filteredShipments = widget.shipments;
      } else {
        _filteredShipments = widget.shipments.where((shipment) {
          return shipment.no.toLowerCase().contains(query) ||
                 shipment.customerName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Select Document',
      ),
      body: Column(
        children: [
          // Search bar and entry count
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.grey100,
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,                  decoration: InputDecoration(
                    hintText: 'Search by document number or customer...',
                    prefixIcon: Icon(Icons.search, color: AppColors.grey600),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: AppColors.grey600),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
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
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Entry count indicator
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.grey600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _searchController.text.isEmpty
                          ? 'Showing ${widget.shipments.length} document${widget.shipments.length == 1 ? '' : 's'}'
                          : 'Showing ${_filteredShipments.length} of ${widget.shipments.length} document${widget.shipments.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: AppColors.grey600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Document list
          Expanded(
            child: _filteredShipments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchController.text.isEmpty 
                              ? Icons.description_outlined 
                              : Icons.search_off,
                          size: 80,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No pending OTP verifications'
                              : 'No documents found',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.grey600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No documents available from the last 15 days\nthat require OTP verification'
                              : 'Try adjusting your search criteria',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.grey500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredShipments.length,
                    itemBuilder: (context, index) {
                      final shipment = _filteredShipments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Icon(
                              Icons.description,
                              color: AppColors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            shipment.no,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                shipment.customerName,
                                style: TextStyle(
                                  color: AppColors.grey700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),                              Text(
                                'Date: ${shipment.postingDate}',
                                style: TextStyle(
                                  color: AppColors.grey600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: AppColors.grey400,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onDocumentSelected(shipment);
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
