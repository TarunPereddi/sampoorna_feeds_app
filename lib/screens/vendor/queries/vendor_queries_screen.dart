import 'package:flutter/material.dart';
import 'vendor_query_detail_screen.dart';

class VendorQueriesScreen extends StatefulWidget {
  const VendorQueriesScreen({super.key});

  @override
  State<VendorQueriesScreen> createState() => _VendorQueriesScreenState();
}

class _VendorQueriesScreenState extends State<VendorQueriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF008000),
        title: Row(
          children: [
            Image.asset(
              'assets/app_logo.png',
              height: 30,
              width: 30,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            const Text(
              'Queries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search queries...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                // Implement search functionality
                setState(() {});
              },
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQueriesList('Active'),
                _buildQueriesList('Resolved'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          _showNewQueryDialog(context);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildQueriesList(String status) {
    // Filter queries based on search text and status
    final String searchText = _searchController.text.toLowerCase();
    final List<Map<String, dynamic>> allQueries = _generateMockQueries(status);
    final List<Map<String, dynamic>> filteredQueries = allQueries
        .where((query) {
      return query['subject'].toLowerCase().contains(searchText) ||
          query['id'].toLowerCase().contains(searchText);
    })
        .toList();

    return filteredQueries.isEmpty
        ? _buildEmptyState(status)
        : ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredQueries.length,
      itemBuilder: (context, index) {
        final query = filteredQueries[index];
        return _buildQueryCard(context, query, status);
      },
    );
  }

  Widget _buildEmptyState(String status) {
    final String message = status == 'Active'
        ? 'No active queries found'
        : 'No resolved queries found';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.question_answer,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (status == 'Active')
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  _showNewQueryDialog(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New Query'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQueryCard(BuildContext context, Map<String, dynamic> query, String status) {
    final bool isActive = status == 'Active';
    final Color priorityColor = _getPriorityColor(query['priority']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFFE8F5E9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorQueryDetailScreen(queryId: query['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      query['priority'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    query['date'],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isActive ? Icons.circle : Icons.check_circle,
                    size: 16,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          query['subject'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          query['description'],
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (query['unreadMessages'] > 0 && isActive)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${query['unreadMessages']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _generateMockQueries(String status) {
    final List<Map<String, dynamic>> queries = [];

    if (status == 'Active') {
      queries.addAll([
        {
          'id': 'QRY-001',
          'subject': 'Payment schedule clarification',
          'description': 'Need to discuss the payment schedule for the recent order PO-1234.',
          'date': '15 Apr 2025',
          'priority': 'Medium',
          'unreadMessages': 2,
        },
        {
          'id': 'QRY-002',
          'subject': 'Delivery address update',
          'description': 'I need to update the delivery address for my next shipment.',
          'date': '12 Apr 2025',
          'priority': 'High',
          'unreadMessages': 0,
        },
      ]);
    } else if (status == 'Resolved') {
      queries.addAll([
        {
          'id': 'QRY-003',
          'subject': 'Invoice discrepancy',
          'description': 'There was a discrepancy in the invoice amount for order PO-1220.',
          'date': '28 Mar 2025',
          'priority': 'High',
          'unreadMessages': 0,
        },
        {
          'id': 'QRY-004',
          'subject': 'Product specification request',
          'description': 'Needed details about the specifications for Mineral Mix product.',
          'date': '22 Mar 2025',
          'priority': 'Low',
          'unreadMessages': 0,
        },
      ]);
    }

    return queries;
  }

  void _showNewQueryDialog(BuildContext context) {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String selectedPriority = 'Medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Query'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    hintText: 'Brief title for your query',
                  ),
                ),
                const SizedBox(height: 16),

                // Priority
                const Text('Priority'),
                DropdownButton<String>(
                  value: selectedPriority,
                  isExpanded: true,
                  items: ['Low', 'Medium', 'High'].map((priority) {
                    return DropdownMenuItem<String>(
                      value: priority,
                      child: Text(priority),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedPriority = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Provide details about your query',
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate input
                if (subjectController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a subject')),
                  );
                  return;
                }

                if (descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a description')),
                  );
                  return;
                }

                // Submit query
                Navigator.pop(context);

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Query submitted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Refresh the list
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}