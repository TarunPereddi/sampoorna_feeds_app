import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QueryDetailScreen extends StatefulWidget {
  final String queryId;

  const QueryDetailScreen({
    super.key,
    required this.queryId,
  });

  @override
  State<QueryDetailScreen> createState() => _QueryDetailScreenState();
}

class _QueryDetailScreenState extends State<QueryDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  late Map<String, dynamic> _queryDetails;
  late List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();
    _loadQueryDetails();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _loadQueryDetails() {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call to fetch query details
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _queryDetails = _getMockQueryDetails();
        _messages = _getMockMessages();
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Query Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2C5F2D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Query details card
          _buildQueryDetailsCard(),

          // Chat messages
          Expanded(
            child: _buildMessagesList(),
          ),

          // Message input
          if (_queryDetails['status'] != 'Resolved')
            _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildQueryDetailsCard() {
    final Color priorityColor = _getPriorityColor(_queryDetails['priority']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Customer Avatar
              CircleAvatar(
                backgroundColor: const Color(0xFF2C5F2D).withOpacity(0.2),
                radius: 20,
                child: Text(
                  _queryDetails['customerName'].substring(0, 1),
                  style: const TextStyle(
                    color: Color(0xFF2C5F2D),
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
                      _queryDetails['customerName'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.queryId,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(_queryDetails['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getStatusColor(_queryDetails['status']), width: 1),
                ),
                child: Text(
                  _queryDetails['status'],
                  style: TextStyle(
                    color: _getStatusColor(_queryDetails['status']),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Query Subject
          Text(
            _queryDetails['subject'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),

          // Query Metadata
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                'Created on ${_queryDetails['date']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: priorityColor, width: 1),
                ),
                child: Text(
                  _queryDetails['priority'],
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
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      reverse: true,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final bool isFromCustomer = message['sender'] == 'customer';

        return _buildMessageBubble(message, isFromCustomer);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isFromCustomer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isFromCustomer ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFromCustomer)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                _queryDetails['customerName'].substring(0, 1),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFromCustomer ? Colors.grey.shade100 : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['text'],
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message['time'],
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (!isFromCustomer && message['status'] == 'seen')
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.done_all,
                            size: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (!isFromCustomer)
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2C5F2D),
              child: const Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // Add attachment functionality
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              minLines: 1,
              maxLines: 4,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: Theme.of(context).primaryColor,
            onPressed: () {
              _sendMessage();
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final String messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _messages.insert(0, {
        'id': 'msg-${_messages.length + 1}',
        'text': messageText,
        'sender': 'sales',
        'time': DateFormat('HH:mm').format(DateTime.now()),
        'status': 'sent',
      });
      _messageController.clear();
    });
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_queryDetails['status'] != 'Resolved')
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Mark as Resolved'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsResolved();
                },
              ),
            if (_queryDetails['status'] == 'Resolved')
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Reopen Query'),
                onTap: () {
                  Navigator.pop(context);
                  _reopenQuery();
                },
              ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Assign to Another Agent'),
              onTap: () {
                Navigator.pop(context);
                // Show assignment dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text('Add Internal Note'),
              onTap: () {
                Navigator.pop(context);
                // Show internal note dialog
              },
            ),
          ],
        ),
      ),
    );
  }

  void _markAsResolved() {
    setState(() {
      _queryDetails['status'] = 'Resolved';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Query has been marked as resolved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _reopenQuery() {
    setState(() {
      _queryDetails['status'] = 'In Progress';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Query has been reopened'),
        backgroundColor: Colors.orange,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> _getMockQueryDetails() {
    // Return mock data based on the query ID
    if (widget.queryId == 'QRY-2025-001') {
      return {
        'id': 'QRY-2025-001',
        'customerName': 'B.K. Enterprises',
        'subject': 'Delivery schedule change request',
        'date': '14/04/2025',
        'priority': 'High',
        'status': 'New',
      };
    } else if (widget.queryId == 'QRY-2025-002') {
      return {
        'id': 'QRY-2025-002',
        'customerName': 'Prajjawal Enterprises',
        'subject': 'Product quality concern',
        'date': '13/04/2025',
        'priority': 'Medium',
        'status': 'In Progress',
      };
    } else {
      // Default mock data for any other query ID
      return {
        'id': widget.queryId,
        'customerName': 'Customer',
        'subject': 'Query Subject',
        'date': '10/04/2025',
        'priority': 'Medium',
        'status': 'New',
      };
    }
  }

  List<Map<String, dynamic>> _getMockMessages() {
    if (widget.queryId == 'QRY-2025-001') {
      return [
        {
          'id': 'msg-1',
          'text': 'We need to reschedule our delivery for order #ORD-2025-001 from 18th April to 20th April due to a facility maintenance on the original date. Please let us know if this is possible.',
          'sender': 'customer',
          'time': '10:15',
          'status': 'seen',
        },
      ];
    } else if (widget.queryId == 'QRY-2025-002') {
      return [
      {
        'id': 'msg-3',
    'text': 'Thank you for the quick response. Well collect the samples as suggested for testing.',
    'sender': 'customer',
    'time': '14:30',
    'status': 'seen',
    },
    {
    'id': 'msg-2',
    'text': 'I understand your concern. Can you provide more details about the inconsistencies youve noticed? If possible, could you also share some photos? We can arrange for a sample to be tested from your current stock.',
    'sender': 'sales',
    'time': '14:22',
    'status': 'seen',
    },
    {
    'id': 'msg-1',
    'text': 'The recent delivery of chicken feed had some inconsistencies in texture and color compared to our previous orders. Some bags appear darker and the texture seems coarser than usual.',
    'sender': 'customer',
    'time': '13:45',
    'status': 'seen',
    },
    ];
    } else {
    // Default mock messages for any other query ID
    return [
    {
    'id': 'msg-1',
    'text': 'This is a sample message for this query. Please review and respond.',
    'sender': 'customer',
    'time': '12:00',
    'status': 'seen',
    },
    ];
    }
  }
}