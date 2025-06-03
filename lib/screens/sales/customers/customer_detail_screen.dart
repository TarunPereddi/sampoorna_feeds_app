import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../services/pdf_service.dart';
import '../../../widgets/common_app_bar.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerNo;

  const CustomerDetailScreen({Key? key, required this.customerNo}) : super(key: key);

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _customerDetails = {};
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTransactions = false;
  String? _errorMessage;
  late TabController _tabController;
  
  // Indian Rupee currency formatter
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );  
  
  @override
  
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCustomerDetails();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  Future<void> _loadCustomerDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customerDetails = await _apiService.getCustomerDetails(widget.customerNo);      // Ensure email field is properly handled
      if (customerDetails['E_Mail'] == null || customerDetails['E_Mail'].toString().trim().isEmpty) {
        customerDetails['E_Mail'] = ""; // Set to empty string instead of null
      }
      
      debugPrint('Email field value after processing: ${customerDetails['E_Mail']}');
      
      setState(() {
        _customerDetails = customerDetails;
        _isLoading = false;
      });
      
      // Load transactions after customer details are loaded
      _loadTransactions();
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load customer details: $e';
        _isLoading = false;
      });
      debugPrint('Error loading customer details: $e');
    }
  }
    Future<void> _loadTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
    });
    
    try {
      // Extract salesperson code from customer details if available
      String? salesPersonCode;
      if (_customerDetails.containsKey('Salesperson_Code') && 
          _customerDetails['Salesperson_Code'] != null &&
          _customerDetails['Salesperson_Code'].toString().isNotEmpty) {
        salesPersonCode = _customerDetails['Salesperson_Code'];
      }
      
      final transactions = await _apiService.getCustomerTransactions(
        widget.customerNo,
        salesPersonCode: salesPersonCode,
      );
      
      setState(() {
        _transactions = transactions;
        _isLoadingTransactions = false;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      setState(() {
        _isLoadingTransactions = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone call to $phoneNumber')),
      );
    }
  }  Future<void> _sendEmail(String email) async {
    try {
      final cleanEmail = email.trim();
      
      if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email address')),
        );
        return;
      }

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: cleanEmail,
        query: 'subject=Inquiry from Sampoorna Feeds App',
      );
      
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication, // Add this mode
        );
      } else {
        // Fallback for Android
        final Uri alternativeUri = Uri.parse('mailto:$cleanEmail?subject=Inquiry');
        await launchUrl(alternativeUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open email app: $e')),
      );
    }
  }
  Future<void> _openMaps(String address) async {
    if (address.isEmpty) return;
    
    try {
      final encodedAddress = Uri.encodeComponent(address);
      
      // Primary: Google Maps web URL
      final Uri googleMapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
      
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(
          googleMapsUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback: geo: scheme for Android
        final Uri geoUri = Uri.parse('geo:0,0?q=$encodedAddress');
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open maps: $e')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Customer Details',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadCustomerDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())              : _errorMessage != null
              ? _buildErrorWidget()
              : _buildCustomerDetailsContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Error loading data',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(_errorMessage!),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCustomerDetails,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetailsContent() {
    return Column(
      children: [
        // Header with customer name and balance info
        _buildCustomerHeader(),
        
        // TabBar for organizing content
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2C5F2D),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2C5F2D),
          tabs: const [
            Tab(icon: Icon(Icons.info), text: "Info"),
            Tab(icon: Icon(Icons.location_on), text: "Address"),
            Tab(icon: Icon(Icons.receipt_long), text: "Finance"),
          ],
        ),
        
        // TabBarView with content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Info Tab
              _buildInfoTab(),
              
              // Address Tab
              _buildAddressTab(),
              
              // Finance Tab
              _buildFinanceTab(),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildCustomerHeader() {
    // Format currency values for display
    final netChange = _customerDetails['Net_Change'] ?? 0.0;
    final formattedNetChange = _currencyFormat.format(netChange);
    
    // Check if customer is blocked
    final isBlocked = _customerDetails['Blocked'] != null && 
                     _customerDetails['Blocked'].toString().trim().isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isBlocked 
            ? Colors.red.shade700.withOpacity(0.9)
            : const Color(0xFF2C5F2D).withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Text(
              (_customerDetails['Name'] ?? 'NA').toString().isNotEmpty 
                  ? (_customerDetails['Name'] ?? 'NA').toString()[0].toUpperCase()
                  : 'NA',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isBlocked ? Colors.red.shade700 : const Color(0xFF2C5F2D),
              ),
            ),
          ),
          const SizedBox(width: 16),
            // Customer details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                Text(
                  _customerDetails['Name'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),                Row(
                  children: [
                    Text(
                      'ID: ${_customerDetails['No'] ?? 'N/A'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    // Blocked tag under ID
                    if (isBlocked)
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BLOCKED: ${_customerDetails['Blocked'].toString().toUpperCase()}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),                const SizedBox(height: 8),
                // Generate Report Button (responsive sizing)
                Align(
                  alignment: Alignment.centerLeft,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen = MediaQuery.of(context).size.width < 400;
                      return ElevatedButton.icon(
                        onPressed: () => _showReportGenerationDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: isBlocked ? Colors.red.shade700 : const Color(0xFF2C5F2D),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 6 : 8, 
                            horizontal: isSmallScreen ? 12 : 16,
                          ),
                          minimumSize: Size(isSmallScreen ? 120 : 140, 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        icon: Icon(Icons.description, size: isSmallScreen ? 16 : 18),
                        label: Text(
                          'Generate Report',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Balance indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),              Text(
                formattedNetChange,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: netChange < 0 ? Colors.white : 
                         netChange > 0 ? Colors.red.shade200 : 
                         Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Contact Chips
          Wrap(
            spacing: 8,
            children: [
              if (_customerDetails['Phone_No'] != null && _customerDetails['Phone_No'].toString().isNotEmpty)
                ActionChip(
                  avatar: const Icon(Icons.call, color: Color(0xFF2C5F2D), size: 18),
                  label: const Text('Call'),
                  onPressed: () => _makePhoneCall(_customerDetails['Phone_No']),
                ),
              if (_customerDetails['E_Mail'] != null && _customerDetails['E_Mail'].toString().trim().isNotEmpty)
                ActionChip(
                  avatar: const Icon(Icons.email, color: Color(0xFF2C5F2D), size: 18),
                  label: const Text('Email'),
                  onPressed: () => _sendEmail(_customerDetails['E_Mail']),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Contact Info Card
          Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  
                  // Phone
                  _buildInfoRow(
                    Icons.phone,
                    'Phone',
                    _customerDetails['Phone_No'] ?? 'Not Available',
                  ),
                  
                  // Email
                  _buildInfoRow(
                    Icons.email,
                    'Email',
                    _customerDetails['E_Mail'] != null && 
                    _customerDetails['E_Mail'].toString().trim().isNotEmpty 
                        ? _customerDetails['E_Mail'] 
                        : 'Not Available',
                  ),
                  
                  // Additional fields can be added here if needed
                ],
              ),
            ),
          ),
          
          // Customer Category/Group details can be added here if available
          if (_customerDetails['Customer_Group_Code'] != null) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    
                    // Customer Group
                    _buildInfoRow(
                      Icons.category,
                      'Customer Group',
                      _customerDetails['Customer_Group_Code'] ?? 'Not Available',
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // Add bottom padding to ensure floating action buttons don't overlap
          const SizedBox(height: 80),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2C5F2D).withOpacity(0.7)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTab() {
    // Extract address components
    final stateCode = _customerDetails['State_Code'] ?? '';
    final address = _customerDetails['Address'] ?? '';
    final address2 = _customerDetails['Address_2'] ?? '';
    final country = _customerDetails['Country_Region_Code'] ?? '';
    final city = _customerDetails['City'] ?? '';
    final county = _customerDetails['County'] ?? '';
    final postCode = _customerDetails['Post_Code'] ?? '';
    
    final addressLines = [
      if (address.isNotEmpty) address,
      if (address2.isNotEmpty) address2,
      if (city.isNotEmpty) city,
      if (county.isNotEmpty) county,
      if (stateCode.isNotEmpty || postCode.isNotEmpty) '$stateCode $postCode'.trim(),
      if (country.isNotEmpty) country,
    ];
    
    // Full address for maps
    final fullAddress = addressLines.join(', ');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address Card
          Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF2C5F2D)),
                      const SizedBox(width: 8),
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Action button for directions - opens maps
                      IconButton(
                        icon: const Icon(Icons.directions, color: Color(0xFF2C5F2D)),
                        onPressed: () => _openMaps(fullAddress),
                        tooltip: 'Get directions',
                      ),
                    ],
                  ),
                  const Divider(),
                  if (addressLines.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('No address information available'),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: addressLines.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            addressLines[index],
                            style: TextStyle(
                              fontSize: 15,
                              color: index == 0 
                                  ? Colors.black 
                                  : Colors.black.withOpacity(0.7),
                              fontWeight: index == 0 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          
          // Add bottom padding to ensure floating action buttons don't overlap
          const SizedBox(height: 80),
        ],
      ),
    );
  }
  Widget _buildFinanceTab() {
    // Format currency values
    final netChange = _customerDetails['Net_Change'] ?? 0.0;
    final creditLimit = _customerDetails['Credit_Limit_LCY'] ?? 0.0;
    final formattedNetChange = _currencyFormat.format(netChange);
    final formattedCreditLimit = _currencyFormat.format(creditLimit);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Summary Card
          Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Financial Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                    // Balance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Balance',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                        ),
                      ),                      Text(
                        formattedNetChange,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: netChange < 0 ? Colors.green.shade700 : 
                                 netChange > 0 ? Colors.red : 
                                 Colors.black,
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 24),
                  
                  // Credit Limit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Credit Limit',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        formattedCreditLimit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Transaction History Card
          Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isLoadingTransactions)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Transactions list
                  if (_transactions.isEmpty && !_isLoadingTransactions)
                    const Center(
                      heightFactor: 2.0,
                      child: Text(
                        'No recent transactions found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    _buildTransactionsList(),
                ],
              ),
            ),
          ),
          
          // Add padding at the bottom to accommodate the floating action buttons
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  
  Widget _buildTransactionsList() {
    return Column(
      children: [
        // Table header
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Date',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Document Type',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Debit',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Credit',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // Table rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _transactions.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final transaction = _transactions[index];
            final postingDate = transaction['Posting_Date'] != null
                ? DateFormat('dd/MM/yy').format(DateTime.parse(transaction['Posting_Date']))
                : 'N/A';
            final documentNo = transaction['Document_Type'] ?? 'N/A';
            final debitAmount = transaction['Debit_Amount'] ?? 0.0;
            final creditAmount = transaction['Credit_Amount'] ?? 0.0;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      postingDate,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),                  Expanded(
                    flex: 3,
                    child: Text(
                      documentNo,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      debitAmount > 0 ? _currencyFormat.format(debitAmount) : '',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      creditAmount > 0 ? _currencyFormat.format(creditAmount) : '',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );  }

  void _showReportGenerationDialog(BuildContext context) {
    DateTime? fromDate;
    DateTime? toDate;
    String selectedReportType = 'invoice'; // Default to invoice
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Get screen size for responsive design
            final screenSize = MediaQuery.of(context).size;
            final isTablet = screenSize.width > 600;
            final isSmallScreen = screenSize.width < 400;
            final availableHeight = screenSize.height * 0.8; // Use 80% of screen height max
            
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : (isTablet ? 60 : 24),
                vertical: 20,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 500 : double.infinity,
                  maxHeight: availableHeight,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with title
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C5F2D).withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.description,
                            color: const Color(0xFF2C5F2D),
                            size: isSmallScreen ? 20 : 22,
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Expanded(
                            child: Text(
                              'Generate Report',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2C5F2D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Scrollable content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Report Type Selection Section
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Report Type',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  
                                  // Radio buttons for report type
                                  Column(
                                    children: [
                                      RadioListTile<String>(
                                        title: Row(
                                          children: [
                                            Icon(
                                              Icons.receipt_long, 
                                              size: isSmallScreen ? 18 : 20, 
                                              color: Colors.grey.shade700,
                                            ),
                                            SizedBox(width: isSmallScreen ? 8 : 12),
                                            Expanded(
                                              child: Text(
                                                'Invoice Report',
                                                style: TextStyle(
                                                  fontSize: isSmallScreen ? 13 : 15,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        value: 'invoice',
                                        groupValue: selectedReportType,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedReportType = value!;
                                          });
                                        },
                                        activeColor: const Color(0xFF2C5F2D),
                                        contentPadding: EdgeInsets.zero,
                                        dense: isSmallScreen,
                                      ),
                                      SizedBox(height: isSmallScreen ? 4 : 8),
                                      RadioListTile<String>(
                                        title: Row(
                                          children: [
                                            Icon(
                                              Icons.summarize, 
                                              size: isSmallScreen ? 18 : 20, 
                                              color: Colors.grey.shade700,
                                            ),
                                            SizedBox(width: isSmallScreen ? 8 : 12),
                                            Expanded(
                                              child: Text(
                                                'Statement Report',
                                                style: TextStyle(
                                                  fontSize: isSmallScreen ? 13 : 15,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        value: 'statement',
                                        groupValue: selectedReportType,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedReportType = value!;
                                          });
                                        },
                                        activeColor: const Color(0xFF2C5F2D),
                                        contentPadding: EdgeInsets.zero,
                                        dense: isSmallScreen,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: isSmallScreen ? 16 : 24),
                            
                            // Date Range Selection Section
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Date Range',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  
                                  // From Date Picker
                                  _buildDatePickerField(
                                    context: context,
                                    label: 'From Date',
                                    date: fromDate,
                                    onDateSelected: (picked) {
                                      setState(() {
                                        fromDate = picked;
                                      });
                                    },
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                    initialDate: fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  
                                  // To Date Picker
                                  _buildDatePickerField(
                                    context: context,
                                    label: 'To Date',
                                    date: toDate,
                                    onDateSelected: (picked) {
                                      setState(() {
                                        toDate = picked;
                                      });
                                    },
                                    firstDate: fromDate ?? DateTime(2020),
                                    lastDate: DateTime.now(),
                                    initialDate: toDate ?? DateTime.now(),
                                    isSmallScreen: isSmallScreen,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Action buttons
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: isSmallScreen ? 1 : 0,
                            child: TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 12 : 20, 
                                  vertical: isSmallScreen ? 10 : 12,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                              ),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Expanded(
                            flex: isSmallScreen ? 1 : 0,
                            child: ElevatedButton(
                              onPressed: (fromDate != null && toDate != null)
                                  ? () {
                                      Navigator.pop(dialogContext);
                                      _generateReport(selectedReportType, fromDate!, toDate!);
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2C5F2D),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 12 : 24, 
                                  vertical: isSmallScreen ? 10 : 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Generate',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildDatePickerField({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required Function(DateTime) onDateSelected,
    required DateTime firstDate,
    required DateTime lastDate,
    required DateTime initialDate,
    bool isSmallScreen = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: lastDate,
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    date != null 
                      ? DateFormat('dd/MM/yyyy').format(date)
                      : 'Select $label',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 15,
                      color: date != null ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today, 
                  size: isSmallScreen ? 18 : 20, 
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  void _showLoadingDialog(BuildContext context, String reportType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C5F2D)),
              ),
              const SizedBox(height: 20),
              Text(
                'Generating ${reportType == 'invoice' ? 'Invoice' : 'Statement'}...',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please wait while we prepare your document.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  String _generateUniqueFileName(String reportType) {
    final now = DateTime.now();
    final dateFormatter = DateFormat('yyyyMMdd');
    final timeFormatter = DateFormat('HHmmss');
    
    final date = dateFormatter.format(now);
    final time = timeFormatter.format(now);
    
    final customerName = _customerDetails['Name']?.toString().replaceAll(' ', '_') ?? 'Customer';
    
    if (reportType == 'invoice') {
      return 'Invoice_${customerName}_${widget.customerNo}_${date}_${time}.pdf';
    } else {
      return 'Statement_${customerName}_${widget.customerNo}_${date}_${time}.pdf';
    }
  }

  Future<void> _generateReport(String reportType, DateTime fromDate, DateTime toDate) async {
    // Show improved loading dialog
    _showLoadingDialog(context, reportType);
      
    try {
      String? base64String;
      
      if (reportType == 'invoice') {
        base64String = await _apiService.getInvoiceReport(
          customerNo: widget.customerNo,
          fromDate: fromDate,
          toDate: toDate,
        );
      } else {
        base64String = await _apiService.getCustomerStatementReport(
          customerNo: widget.customerNo,
          fromDate: fromDate,
          toDate: toDate,
        );
      }
      
      // Close loading dialog 
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      if (base64String == null || base64String.isEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('No Data'),
              content: Text('No ${reportType} data exists for the selected date range.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }
        // Generate unique filename and save PDF
      final fileName = _generateUniqueFileName(reportType);
      String? savedFilePath = await PdfService.saveToDownloads(
        base64String: base64String,
        fileName: fileName,
        context: context,
      );
      
      if (savedFilePath == null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to save ${reportType}. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to generate ${reportType}: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}
