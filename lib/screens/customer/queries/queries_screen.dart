import 'package:flutter/material.dart';
import '../../../widgets/common_app_bar.dart';
import 'query_detail_screen.dart';

class QueriesScreen extends StatefulWidget {
  const QueriesScreen({super.key});

  @override
  State<QueriesScreen> createState() => _QueriesScreenState();
}

class _QueriesScreenState extends State<QueriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      appBar: const CommonAppBar(
        title: 'Queries',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewQueryDialog(context);
        },
        backgroundColor: const Color(0xFF008000),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: const Color(0xFF008000),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'New'),
                Tab(text: 'In Progress'),
                Tab(text: 'Resolved'),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search queries...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (value) {
                // Filter queries based on search text
                setState(() {});
              },
            ),
          ),

          // Query tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQueriesList('New'),
                _buildQueriesList('In Progress'),
                _buildQueriesList('Resolved'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueriesList(String status) {
    // Mock data for queries based on status
    final queries = _getMockQueries(status);

    // Apply search filter
    final searchQuery = _searchController.text.toLowerCase();
    final filteredQueries = searchQuery.isEmpty
        ? queries
        : queries.where((query) {
      return query['subject'].toLowerCase().contains(searchQuery) ||
          query['customerName'].toLowerCase().contains(searchQuery) ||
          query['id'].toLowerCase().contains(searchQuery);
    }).toList();

    if (filteredQueries.isEmpty) {
      return const Center(child: Text('No queries found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: filteredQueries.length,
      itemBuilder: (context, index) {
        final query = filteredQueries[index];
        return _buildQueryCard(query, status);
      },
    );
  }

  Widget _buildQueryCard(Map<String, dynamic> query, String status) {
    final Color priorityColor = _getPriorityColor(query['priority']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QueryDetailScreen(queryId: query['id']),
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
            // Customer Avatar
            CircleAvatar(
            backgroundColor: const Color(0xFF008000).withOpacity(0.2),
            radius: 20,
            child: Text(
              query['customerName'].substring(0, 1),
              style: const TextStyle(
                color: Color(0xFF008000),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Customer Name and Query ID
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                        Text(
                          query['customerName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          query['id'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Date and Priority
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        query['date'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: priorityColor, width: 1),
                        ),
                        child: Text(
                          query['priority'],
                          style: TextStyle(
                            color: priorityColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Query Subject and Preview
              Text(
                query['subject'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                query['preview'],
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Action buttons if not resolved
              if (status != 'Resolved')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (status == 'New')
                        TextButton.icon(
                          onPressed: () {
                            // Handle taking ownership
                            setState(() {
                              // Update status in a real app
                            });
                          },
                          icon: const Icon(Icons.person_add_alt, size: 18),
                          label: const Text('Take Ownership'),
                        ),
                      if (status == 'In Progress')
                        TextButton.icon(
                          onPressed: () {
                            // Handle marking as resolved
                            setState(() {
                              // Update status in a real app
                            });
                          },
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Mark Resolved'),
                        ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          // Handle replying
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QueryDetailScreen(queryId: query['id']),
                            ),
                          );
                        },
                        icon: const Icon(Icons.reply, size: 18),
                        label: const Text('Reply'),
                      ),
                    ],
                  ),
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

  List<Map<String, dynamic>> _getMockQueries(String status) {
    // Convert status to match our mock data structure
    String mappedStatus;
    switch (status) {
      case 'New':
        mappedStatus = 'New';
        break;
      case 'In Progress':
        mappedStatus = 'In Progress';
        break;
      case 'Resolved':
        mappedStatus = 'Resolved';
        break;
      default:
        mappedStatus = 'New';
    }

    // Mock queries data
    final allQueries = [
      {
        'id': 'QRY-2025-001',
        'customerName': 'B.K. Enterprises',
        'subject': 'Delivery schedule change request',
        'preview': 'We need to reschedule our delivery for order #ORD-2025-001 from 18th April to 20th April...',
        'date': '14/04/2025',
        'priority': 'High',
        'status': 'New',
      },
      {
        'id': 'QRY-2025-002',
        'customerName': 'Prajjawal Enterprises',
        'subject': 'Product quality concern',
        'preview': 'The recent delivery of chicken feed had some inconsistencies in texture and color...',
        'date': '13/04/2025',
        'priority': 'Medium',
        'status': 'In Progress',
      },
      {
        'id': 'QRY-2025-003',
        'customerName': 'Agro Suppliers Ltd',
        'subject': 'Billing discrepancy',
        'preview': 'There seems to be a discrepancy in our latest invoice. We were charged for 50 bags but only received 48...',
        'date': '12/04/2025',
        'priority': 'Medium',
        'status': 'New',
      },
      {
        'id': 'QRY-2025-004',
        'customerName': 'Farm Solutions Inc',
        'subject': 'Request for product documentation',
        'preview': 'We need the complete product documentation and safety data sheets for the new mineral mix...',
        'date': '11/04/2025',
        'priority': 'Low',
        'status': 'In Progress',
      },
      {
        'id': 'QRY-2025-005',
        'customerName': 'Green Agro Ltd',
        'subject': 'Payment terms extension request',
        'preview': 'Due to some temporary cash flow issues, we would like to request an extension of payment terms...',
        'date': '10/04/2025',
        'priority': 'High',
        'status': 'Resolved',
      },
      {
        'id': 'QRY-2025-006',
        'customerName': 'B.K. Enterprises',
        'subject': 'Product specifications',
        'preview': 'Could you please provide detailed specifications for your new organic feed line...',
        'date': '09/04/2025',
        'priority': 'Low',
        'status': 'Resolved',
      },
      {
        'id': 'QRY-2025-007',
        'customerName': 'Prajjawal Enterprises',
        'subject': 'Bulk order discount inquiry',
        'preview': 'We are planning to place a large order next month and would like to inquire about bulk discounts...',
        'date': '08/04/2025',
        'priority': 'Medium',
        'status': 'In Progress',
      },
    ];

    // Filter by status
    return allQueries.where((query) => query['status'] == mappedStatus).toList();
  }

  void _showNewQueryDialog(BuildContext context) {
    // Mock data for customer dropdown
    final List<String> customers = [
      'B.K. Enterprises',
      'Prajjawal Enterprises',
      'Agro Suppliers Ltd',
      'Farm Solutions Inc',
      'Green Agro Ltd',
    ];

    String? selectedCustomer;
    String? selectedPriority = 'Medium';
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Query'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Customer *',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedCustomer,
                      items: customers.map((customer) {
                        return DropdownMenuItem<String>(
                          value: customer,
                          child: Text(customer),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCustomer = value;
                        });
                      },
                      isExpanded: true,
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Priority dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedPriority,
                      items: ['Low', 'Medium', 'High'].map((priority) {
                        return DropdownMenuItem<String>(
                          value: priority,
                          child: Text(priority),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPriority = value;
                        });
                      },
                      isExpanded: true,
                    ),
                    const SizedBox(height: 16),

                    // Subject field
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject *',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 100,
                    ),
                    const SizedBox(height: 8),

                    // Description field
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      maxLength: 500,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validate form
                    if (selectedCustomer == null ||
                        subjectController.text.isEmpty ||
                        descriptionController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required fields')),
                      );
                      return;
                    }

                    // Create query (would be an API call in a real app)
                    Navigator.of(context).pop();

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Query created successfully')),
                    );

                    // Refresh the list in a real app
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C5F2D),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}