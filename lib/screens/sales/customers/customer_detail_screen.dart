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
      });    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load customer details: $e';
        _isLoading = false;
      });
      debugPrint('Error loading customer details: $e');
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
  }
  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch email to $email')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending email: $e')),
      );
    }
  }

  Future<void> _openMaps(String address) async {
    if (address.isEmpty) {
      // Silently return if address is empty
      return;
    }
    
    final Uri mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    try {
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not open maps application');
      }
    } catch (e) {
      // Log error but don't show snackbar
      debugPrint('Error opening maps: $e');
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
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : Stack(
                  children: [
                    _buildCustomerDetailsContent(),
                    
                    // Floating action buttons for all tabs
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [                          FloatingActionButton.extended(
                            heroTag: 'generateInvoice',
                            onPressed: () {
                              _showDateRangeDialog(context, 'invoice');
                            },
                            backgroundColor: const Color(0xFF2C5F2D),
                            foregroundColor: Colors.white,
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('Generate Invoice'),
                          ),
                          const SizedBox(height: 12),
                          FloatingActionButton.extended(
                            heroTag: 'generateReport',
                            onPressed: () {
                              _showDateRangeDialog(context, 'statement');
                            },
                            backgroundColor: const Color(0xFF2C5F2D),
                            foregroundColor: Colors.white,
                            icon: const Icon(Icons.summarize),
                            label: const Text('Generate Report'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C5F2D).withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Text(
              (_customerDetails['Name'] ?? 'NA').toString().isNotEmpty 
                  ? (_customerDetails['Name'] ?? 'NA').toString()[0].toUpperCase()
                  : 'NA',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C5F2D),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Customer details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _customerDetails['Name'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${_customerDetails['No'] ?? 'N/A'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
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
              const SizedBox(height: 4),
              Text(
                formattedNetChange,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: netChange >= 0 ? Colors.white : Colors.red.shade200,
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
                      ),
                      Text(
                        formattedNetChange,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: netChange < 0 ? Colors.red : Colors.green.shade700,
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
          
          // Transaction History Card (can be added in future)
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
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    heightFactor: 2.0,
                    child: Text(
                      'Transaction history will appear here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
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

  void _showDateRangeDialog(BuildContext context, String reportType) {
    DateTime? fromDate;
    DateTime? toDate;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    reportType == 'invoice' ? Icons.receipt_long : Icons.summarize,
                    color: const Color(0xFF2C5F2D),
                  ),
                  const SizedBox(width: 8),
                  Text(reportType == 'invoice' ? 'Generate Invoice' : 'Generate Statement'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // From Date Picker
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          fromDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(fromDate != null 
                            ? DateFormat('dd/MM/yyyy').format(fromDate!)
                            : 'From Date'),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // To Date Picker
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: toDate ?? DateTime.now(),
                        firstDate: fromDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          toDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(toDate != null 
                            ? DateFormat('dd/MM/yyyy').format(toDate!)
                            : 'To Date'),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (fromDate != null && toDate != null)
                      ? () {
                          Navigator.pop(dialogContext);
                          _generateReport(reportType, fromDate!, toDate!);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C5F2D),
                  ),
                  child: const Text('Generate'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generateReport(String reportType, DateTime fromDate, DateTime toDate) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Generating PDF...'),
            ],
          ),
        );
      },
    );
      try {
      String? base64String;
      String fileName;
      
      // Create a variable to track if the dialog is showing
      bool isDialogShowing = true;
      
      if (reportType == 'invoice') {
        base64String = await _apiService.getInvoiceReport(
          customerNo: widget.customerNo,
          fromDate: fromDate,
          toDate: toDate,
        );
        fileName = 'Invoice_${widget.customerNo}_${DateFormat('yyyyMMdd').format(fromDate)}_${DateFormat('yyyyMMdd').format(toDate)}.pdf';
      } else {
        base64String = await _apiService.getCustomerStatementReport(
          customerNo: widget.customerNo,
          fromDate: fromDate,
          toDate: toDate,
        );
        fileName = 'Statement_${widget.customerNo}_${DateFormat('yyyyMMdd').format(fromDate)}_${DateFormat('yyyyMMdd').format(toDate)}.pdf';
      }
      
      // Close loading dialog if it's still showing
      if (isDialogShowing && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
        isDialogShowing = false;
      }
      
      if (base64String == null || base64String.isEmpty) {
        // Show no data dialog
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
        // Generate and share PDF
      bool success = await PdfService.generateAndSharePdf(
        base64String: base64String,
        fileName: fileName,
        context: context,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${reportType == 'invoice' ? 'Invoice' : 'Statement'} generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error if PDF couldn't be generated
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to generate ${reportType}. Invalid data received.'),
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
