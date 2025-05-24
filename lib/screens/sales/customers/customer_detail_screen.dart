import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/api_service.dart';
import '../../../widgets/common_app_bar.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerNo;

  const CustomerDetailScreen({Key? key, required this.customerNo}) : super(key: key);

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _customerDetails = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomerDetails();
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
        await launchUrl(emailUri);
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
              ? Center(
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
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Customer Card with basic info
                      _buildCustomerInfoCard(),
                      const SizedBox(height: 16),

                      // Contact Card
                      _buildContactCard(),
                      const SizedBox(height: 16),

                      // Address Card
                      _buildAddressCard(),
                      const SizedBox(height: 16),

                      // Financial Info Card
                      _buildFinancialInfoCard(),
                      const SizedBox(height: 16),
                      
                      // Report Buttons
                      _buildReportButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF2C5F2D),
                  foregroundColor: Colors.white,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _customerDetails['Name'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Customer No: ${_customerDetails['No'] ?? 'N/A'}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                if (_customerDetails['Phone_No'] != null && _customerDetails['Phone_No'].toString().isNotEmpty) {
                  _makePhoneCall(_customerDetails['Phone_No']);
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Color(0xFF2C5F2D)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phone Number',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _customerDetails['Phone_No'] ?? 'Not Available',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_customerDetails['Phone_No'] != null && _customerDetails['Phone_No'].toString().isNotEmpty)
                    const Icon(
                      Icons.call,
                      color: Color(0xFF2C5F2D),
                      size: 20,
                    ),
                ],
              ),
            ),            const SizedBox(height: 16),
            InkWell(              onTap: () {
                final email = _customerDetails['E_Mail'];
                if (email != null && email.toString().trim().isNotEmpty) {
                  _sendEmail(email.toString());
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.email, color: Color(0xFF2C5F2D)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _customerDetails['E_Mail'] != null && 
                          _customerDetails['E_Mail'].toString().trim().isNotEmpty 
                              ? _customerDetails['E_Mail'] 
                              : 'Not Available',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),                  if (_customerDetails['E_Mail'] != null && _customerDetails['E_Mail'].toString().trim().isNotEmpty)
                    const Icon(
                      Icons.send,
                      color: Color(0xFF2C5F2D),
                      size: 20,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    // Extract address components
    final stateCode = _customerDetails['State_Code'] ?? '';
    final address = _customerDetails['Address'] ?? '';
    final address2 = _customerDetails['Address_2'] ?? '';
    final country = _customerDetails['Country_Region_Code'] ?? '';
    final city = _customerDetails['City'] ?? '';
    final county = _customerDetails['County'] ?? '';
    final postCode = _customerDetails['Post_Code'] ?? '';
    
    // Build full address
    final fullAddress = [
      address,
      address2,
      city,
      county,
      '$stateCode $postCode',
      country,
    ].where((element) => element.isNotEmpty).join(', ');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Color(0xFF2C5F2D)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    fullAddress.isEmpty ? 'No address available' : fullAddress,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialInfoCard() {
    // Format currency values
    final netChange = _customerDetails['Net_Change'] ?? 0.0;
    final creditLimit = _customerDetails['Credit_Limit_LCY'] ?? 0.0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildFinancialInfoRow(
              'Balance',
              '$netChange',
              netChange < 0 ? Colors.red : Colors.green,
            ),
            const Divider(),
            _buildFinancialInfoRow(
              'Credit Limit',
              '$creditLimit',
              Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invoice Report functionality coming soon')),
            );
          },
          icon: const Icon(Icons.receipt_long),
          label: const Text('Invoice Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C5F2D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Statement Report functionality coming soon')),
            );
          },
          icon: const Icon(Icons.summarize),
          label: const Text('Statement Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C5F2D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}
