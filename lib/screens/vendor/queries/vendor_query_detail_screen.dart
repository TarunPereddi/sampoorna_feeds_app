import 'package:flutter/material.dart';

class VendorQueryDetailScreen extends StatefulWidget {
  final String queryId;

  const VendorQueryDetailScreen({
    super.key,
    required this.queryId,
  });

  @override
  State<VendorQueryDetailScreen> createState() => _VendorQueryDetailScreenState();
}

class _VendorQueryDetailScreenState extends State<VendorQueryDetailScreen> {
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
              'Query Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
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
          if (_queryDetails['status'] == 'Active')
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
        color: const Color(0xFFE8F5E9),
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
              Text(
                _queryDetails['subject'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _queryDetails['priority'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _queryDetails['description'],
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
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
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _queryDetails['status'] == 'Active' ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _queryDetails['status'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
        final bool isFromMe = message['sender'] == 'vendor';

        return _buildMessageBubble(message, isFromMe);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isFromMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFromMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade700,
              child: const Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFromMe ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
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
                  Text(
                    message['time'],
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isFromMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              child: const Text(
                'V',
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
        'sender': 'vendor',
        'time': '${DateTime.now().hour}:${DateTime.now().minute}',
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
            if (_queryDetails['status'] == 'Active')
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Mark as Resolved'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsResolved();
                },
              ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh'),
              onTap: () {
                Navigator.pop(context);
                _loadQueryDetails();
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
      _queryDetails['status'] = 'Active';
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

  Map<String, dynamic> _getMockQueryDetails() {
    if (widget.queryId == 'QRY-001') {
      return {
        'id': 'QRY-001',
        'subject': 'Payment schedule clarification',
        'description': 'Need to discuss the payment schedule for the recent order PO-1234. The terms seem to be different from our previous agreement. Can we arrange a call to discuss this?',
        'date': '15 Apr 2025',
        'priority': 'Medium',
        'status': 'Active',
      };
    } else if (widget.queryId == 'QRY-002') {
      return {
        'id': 'QRY-002',
        'subject': 'Delivery address update',
        'description': 'I need to update the delivery address for my next shipment. The new warehouse location is now operational. Please confirm when this change can be reflected in your system.',
        'date': '12 Apr 2025',
        'priority': 'High',
        'status': 'Active',
      };
    } else if (widget.queryId == 'QRY-003') {
      return {
        'id': 'QRY-003',
        'subject': 'Invoice discrepancy',
        'description': 'There was a discrepancy in the invoice amount for order PO-1220. The billed amount is higher than what was agreed upon. Please check and provide clarification.',
        'date': '28 Mar 2025',
        'priority': 'High',
        'status': 'Resolved',
      };
    } else {
      return {
        'id': widget.queryId,
        'subject': 'Generic query',
        'description': 'This is a generic query description.',
        'date': '10 Apr 2025',
        'priority': 'Medium',
        'status': 'Active',
      };
    }
  }

  List<Map<String, dynamic>> _getMockMessages() {
    if (widget.queryId == 'QRY-001') {
      return [
        {
          'id': 'msg-3',
          'text': 'Thank you for your quick response. I will review the schedule and get back to you.',
          'sender': 'vendor',
          'time': '10:15',
        },
        {
          'id': 'msg-2',
          'text': 'The updated payment schedule has been shared via email. Please check and confirm if it aligns with your requirements.',
          'sender': 'sampoorna',
          'time': '10:10',
        },
        {
          'id': 'msg-1',
          'text': 'Hello, I wanted to clarify the payment schedule for order PO-1234. The current terms seem different from our previous agreement.',
          'sender': 'vendor',
          'time': '09:45',
        },
      ];
    } else if (widget.queryId == 'QRY-002') {
      return [
        {
          'id': 'msg-1',
          'text': 'Hello, I need to update the delivery address for my next shipment. Our new warehouse location is now operational.',
          'sender': 'vendor',
          'time': '14:30',
        },
      ];
    } else if (widget.queryId == 'QRY-003') {
      return [
      {
        'id': 'msg-3',
    'text': 'Thank you for the clarification. I understand the issue now. Consider this matter resolved.',
    'sender': 'vendor',
    'time': '11:45',
  },
    {
    'id': 'msg-2',
    'text': 'We have checked the invoice and found that there was an error in the calculation. A corrected invoice has been issued and sent to your email. Please let us know if you need anything else.',
    'sender': 'sampoorna',
    'time': '11:30',
    },
    {
    'id': 'msg-1',
    'text': 'There seems to be a discrepancy in the invoice amount for order PO-1220. The billed amount is higher than what was agreed upon.',
    'sender': 'vendor',
    'time': '10:15',
    },
    ];
    } else {
    return [
    {
    'id': 'msg-1',
    'text': 'This is a generic message for testing purposes.',
    'sender': 'vendor',
    'time': '12:00',
    },
    ];
    }
  }
}