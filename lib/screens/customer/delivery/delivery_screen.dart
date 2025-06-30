import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common_app_bar.dart';
import '../../../utils/app_colors.dart';
import '../../../mixins/tab_refresh_mixin.dart';
import '../../../models/sales_shipment.dart';
import '../../../models/customer.dart';
import '../../../models/sales_person.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import 'document_selection_screen.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> with TabRefreshMixin {
  // TabRefreshMixin implementation
  @override
  int get tabIndex => 3; // Delivery tab index (previously Profile)  // State variables
  List<SalesShipment> _shipments = [];
  SalesShipment? _selectedShipment;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isVerifying = false;
  bool _isResending = false;
  bool _isLoadingShipments = false;

  @override
  void initState() {
    super.initState();
    _loadShipmentData();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _documentController.dispose();
    super.dispose();
  }
  // Load shipment data from API
  Future<void> _loadShipmentData() async {
    setState(() {
      _isLoadingShipments = true;
    });    try {
      // Get current user's customer number from Provider
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final customerNo = currentUser.no;
      debugPrint('Loading shipments for customer: $customerNo');

      // Fetch shipments from API (use customerNo instead of salespersonCode)
      final shipmentsData = await _apiService.getSalesShipments(
        salespersonCode: null, // Don't send salespersonCode
        customerCode: customerNo,
      );

      // Print the entire response to the console for debugging
      debugPrint('Full shipments API response:');
      debugPrint(shipmentsData.toString());

      // Convert to SalesShipment objects
      final shipments = shipmentsData.map((json) => SalesShipment.fromJson(json)).toList();

      setState(() {
        _shipments = shipments;
        _isLoadingShipments = false;
      });

      debugPrint('Loaded ${shipments.length} shipments');

    } catch (e) {
      setState(() {
        _isLoadingShipments = false;
      });

      debugPrint('Error loading shipments: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load shipments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }  @override
  Future<void> performRefresh() async {
    debugPrint('DeliveryScreen: Performing refresh');
    // Clear form state when tab is refreshed/switched to
    _clearForm();
    await _loadShipmentData();
  }

  // Clear form state
  void _clearForm() {
    setState(() {
      _selectedShipment = null;
      _documentController.clear();
      _otpController.clear();
    });
  }
  void _selectDocument() {
    if (_isLoadingShipments) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading shipments, please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }    if (_shipments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending OTP verifications available (last 15 days)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(        builder: (context) => DocumentSelectionScreen(
          shipments: _shipments,
          onDocumentSelected: (shipment) {
            setState(() {
              _selectedShipment = shipment;
              _documentController.text = shipment.no;
              _otpController.clear();
            });
            
            // Log OTP value for testing purposes
            debugPrint('Document selected: ${shipment.no}');
            debugPrint('OTP for testing: ${shipment.otp}');
          },
        ),
      ),
    );
  }
  void _verifyOTP() async {
    if (_selectedShipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a document first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter OTP'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });
    try {
      // Get current user ID from AuthService Provider
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Use correct userID based on persona
      String userId;
      if (currentUser is SalesPerson) {
        userId = currentUser.code;
      } else if (currentUser is Customer) {
        userId = currentUser.no;
      } else {
        throw Exception('Unknown user type');
      }

      await _apiService.verifyOTP(
        documentNo: _selectedShipment!.no,
        otp: _otpController.text,
        userID: userId,
      );

      setState(() {
        _isVerifying = false;
      });
      // Show success dialog and refresh data
      await _showSuccessDialog('OTP Verification Successful',
          'The delivery has been successfully verified.');

      // Clear the form and refresh shipment data
      _clearForm();
      await _loadShipmentData();

    } catch (e) {
      setState(() {
        _isVerifying = false;
      });
      // Show error dialog and refresh data
      await _showErrorDialog('OTP Verification Failed',
          'Failed to verify OTP. Please check the OTP and try again.');

      // Refresh shipment data in case of failure
      await _loadShipmentData();
    }
  }

  void _resendOTP() async {
    if (_selectedShipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a document first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      await _apiService.resendOTP(documentNo: _selectedShipment!.no);

      setState(() {
        _isResending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to registered number'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      setState(() {
        _isResending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP send failed'),
          backgroundColor: Colors.red,
        ),
      );
    }  }
  Future<void> _showSuccessDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showErrorDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Delivery OTP',
      ),
      body: RefreshIndicator(
        onRefresh: performRefresh,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Compact Header Section
              Container(
                padding: const EdgeInsets.all(16), // Reduced from 20
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: 40, // Reduced from 60
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 8), // Reduced from 12
                    Text(
                      'OTP Verification',
                      style: TextStyle(
                        fontSize: 20, // Reduced from 24
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 4), // Reduced from 8
                    Text(
                      'Select document and verify OTP for delivery',
                      style: TextStyle(
                        fontSize: 12, // Reduced from 14
                        color: AppColors.grey600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16), // Reduced from 24
              
              // Document Selection Section
              Text(
                'Document Number',
                style: TextStyle(
                  fontSize: 14, // Reduced from 16
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey800,
                ),
              ),
              const SizedBox(height: 6), // Reduced from 8
              
              TextFormField(
                controller: _documentController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: _isLoadingShipments 
                      ? 'Loading shipments...' 
                      : 'Select a document number',
                  suffixIcon: _isLoadingShipments
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        )
                      : Icon(Icons.search, color: AppColors.primary),                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Reduced padding
                ),
                onTap: _selectDocument,
              ),
                // Selected Document Details - More compact
              if (_selectedShipment != null) ...[
                const SizedBox(height: 12), // Reduced from 16
                Container(
                  padding: const EdgeInsets.all(12), // Reduced from 16
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document Details',
                        style: TextStyle(
                          fontSize: 12, // Reduced from 14
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey800,
                        ),
                      ),
                      const SizedBox(height: 6), // Reduced from 8_buildDetailRow('Customer', _selectedShipment!.customerName),
                      _buildDetailRow('Customer Code', _selectedShipment!.customerCode),
                      _buildDetailRow('Posting Date', _selectedShipment!.postingDate),
                    ],
                  ),
                ),
              ],
                const SizedBox(height: 16), // Reduced from 24
              
              // OTP Input Section
              Text(
                'Enter OTP',
                style: TextStyle(
                  fontSize: 14, // Reduced from 16
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey800,
                ),
              ),
              const SizedBox(height: 6), // Reduced from 8
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],                decoration: InputDecoration(
                  hintText: 'Enter 6-digit OTP',
                  prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Reduced padding
                ),
                enabled: _selectedShipment != null,
              ),
                // Resend OTP Link - More compact
              const SizedBox(height: 8), // Reduced from 12
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _selectedShipment != null && !_isResending ? _resendOTP : null,
                  child: _isResending
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12, // Reduced from 14
                              height: 12, // Reduced from 14
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 6), // Reduced from 8
                            const Text('Resending...', style: TextStyle(fontSize: 12)),
                          ],
                        )
                      : const Text('Resend OTP', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: _selectedShipment != null 
                        ? AppColors.primary 
                        : AppColors.grey400,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced padding
                  ),
                ),
              ),
                const SizedBox(height: 16), // Reduced from 32
              
              // Verify Button - More compact
              ElevatedButton.icon(
                onPressed: (_selectedShipment != null && !_isVerifying) ? _verifyOTP : null,
                icon: _isVerifying 
                    ? SizedBox(
                        width: 14, // Reduced from 16
                        height: 14, // Reduced from 16
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : const Icon(Icons.verified, size: 18), // Reduced icon size
                label: Text(_isVerifying ? 'Verifying...' : 'Verify OTP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12), // Reduced from 16
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14, // Reduced from 16
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const Spacer(), // This will push instructions to bottom
                // Instructions - More compact at bottom
              Container(
                padding: const EdgeInsets.all(12), // Reduced from 16
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 16, // Reduced from 20
                    ),
                    const SizedBox(width: 8), // Reduced from 12
                    Expanded(
                      child: Text(
                        'First select a document number, then enter the OTP to verify delivery.',
                        style: TextStyle(
                          fontSize: 11, // Reduced from 13
                          color: Colors.blue.shade800,
                        ),
                      ),
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
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3), // Reduced from 4
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90, // Reduced from 100
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 11, // Reduced from 13
                color: AppColors.grey600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11, // Reduced from 13
                fontWeight: FontWeight.w500,
                color: AppColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}