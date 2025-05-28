import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common_app_bar.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_colors.dart';
import '../../login/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isResettingPassword = false;
  String? _errorMessage;
  Map<String, dynamic>? _salesPersonDetails;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the current user's code
      final authService = Provider.of<AuthService>(context, listen: false);
      final salesPerson = authService.currentUser;

      if (salesPerson == null) {
        throw Exception('Not logged in');
      }

      // Load sales person data
      final salesPersonData = await _apiService.getSalesPersonDetails(salesPerson.code);
      setState(() {
        _salesPersonDetails = salesPersonData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: $e';
        _isLoading = false;
      });
      debugPrint('Error loading profile details: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      appBar: CommonAppBar(
        title: 'My Profile',
      ),
      body: _isLoading 
        ? Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          )
        : _errorMessage != null 
          ? _buildErrorView() 
          : _buildProfileView(isTablet),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.grey700,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: _loadProfileData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(bool isTablet) {
    final salesPerson = _salesPersonDetails;
    
    if (salesPerson == null) {
      return Center(
        child: Text(
          'No profile data available',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.grey700,
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadProfileData,
      color: AppColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxWidth: isTablet ? 600 : double.infinity,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile header
                      _buildProfileHeader(salesPerson, isTablet),
                      
                      SizedBox(height: isTablet ? 32 : 24),
                      
                      // Action buttons section
                      _buildActionButtons(salesPerson, isTablet),
                      
                      SizedBox(height: isTablet ? 32 : 24),
                      
                      // Profile details card
                      _buildPersonalInfoCard(salesPerson, isTablet),
                      
                      SizedBox(height: isTablet ? 24 : 16),
                      
                      // Business Information card
                      _buildBusinessInfoCard(salesPerson, isTablet),
                      
                      SizedBox(height: isTablet ? 32 : 24),
                      
                      // Logout button
                      _buildLogoutButton(isTablet),
                      
                      SizedBox(height: isTablet ? 32 : 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> salesPerson, bool isTablet) {
    return Card(
      elevation: 3,
      shadowColor: AppColors.grey300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.primaryLight,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
          child: Column(
            children: [
              // Profile picture with status indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: isTablet ? 60 : 50,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      (salesPerson['Name'] != null && salesPerson['Name'].toString().isNotEmpty) 
                          ? salesPerson['Name'].toString()[0].toUpperCase() 
                          : 'U',
                      style: TextStyle(
                        fontSize: isTablet ? 48 : 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: salesPerson['Block'] == true ? AppColors.error : AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: Icon(
                        salesPerson['Block'] == true ? Icons.block : Icons.check_circle,
                        color: AppColors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 20 : 16),
              Text(
                salesPerson['Name'] ?? 'Unknown User',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 26 : 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${salesPerson['Code'] ?? ''}',
                style: TextStyle(
                  color: AppColors.grey600,
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Text(
                  'Sales Person',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> salesPerson, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showResetPasswordDialog(context, salesPerson),
            icon: const Icon(Icons.lock_reset, size: 20),
            label: const Text('Reset Password'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(
                vertical: isTablet ? 16 : 14,
                horizontal: isTablet ? 24 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showEditProfileDialog(context),
            icon: const Icon(Icons.edit, size: 20),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary, width: 1.5),
              padding: EdgeInsets.symmetric(
                vertical: isTablet ? 16 : 14,
                horizontal: isTablet ? 24 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(Map<String, dynamic> salesPerson, bool isTablet) {
    return Card(
      elevation: 2,
      shadowColor: AppColors.grey300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: isTablet ? 26 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.grey300, height: 1),
            const SizedBox(height: 16),
            _buildProfileDetailItem('Full Name', salesPerson['Name'] ?? 'N/A', Icons.badge, isTablet),
            if (salesPerson['E_Mail'] != null && salesPerson['E_Mail'].toString().isNotEmpty)
              _buildProfileDetailItem('Email', salesPerson['E_Mail'], Icons.email, isTablet),
            if (salesPerson['Phone_No'] != null && salesPerson['Phone_No'].toString().isNotEmpty)
              _buildProfileDetailItem('Phone', salesPerson['Phone_No'], Icons.phone, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoCard(Map<String, dynamic> salesPerson, bool isTablet) {
    return Card(
      elevation: 2,
      shadowColor: AppColors.grey300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business_center,
                  color: AppColors.primary,
                  size: isTablet ? 26 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Business Information',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.grey300, height: 1),
            const SizedBox(height: 16),
            _buildProfileDetailItem(
              'Responsibility Center', 
              salesPerson['Responsibility_Center'] ?? 'N/A', 
              Icons.work_outline, 
              isTablet
            ),
            _buildProfileDetailItem(
              'Account Status', 
              salesPerson['Block'] == true ? 'Blocked' : 'Active', 
              salesPerson['Block'] == true ? Icons.block : Icons.check_circle, 
              isTablet,
              valueColor: salesPerson['Block'] == true ? AppColors.error : AppColors.success,
            ),
            _buildProfileDetailItem(
              'Commission %', 
              salesPerson['Commission_Percent']?.toString() ?? 'N/A', 
              Icons.percent, 
              isTablet
            ),
            _buildProfileDetailItem(
              'Location', 
              salesPerson['Location'] ?? 'N/A', 
              Icons.location_on, 
              isTablet
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetailItem(
    String label, 
    String value, 
    IconData icon, 
    bool isTablet, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isTablet ? 20 : 18,
            color: AppColors.grey600,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.grey700,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.grey900,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(bool isTablet) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout, size: 20),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 18 : 16,
            horizontal: isTablet ? 32 : 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, Map<String, dynamic> salesPerson) {
    final TextEditingController mobileController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.lock_reset, color: AppColors.info),
                  const SizedBox(width: 8),
                  const Text('Reset Password'),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please enter your registered mobile number to reset your password.',
                      style: TextStyle(
                        color: AppColors.grey700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        hintText: 'Enter your registered mobile number',
                        prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your mobile number';
                        }
                        if (value.length < 10) {
                          return 'Please enter a valid mobile number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isResettingPassword ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.grey600),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isResettingPassword ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        _isResettingPassword = true;
                      });

                      try {
                        final authService = Provider.of<AuthService>(context, listen: false);
                        final result = await authService.forgotPassword(
                          salesPerson['Code'] ?? '',
                          mobileController.text.trim(),
                        );

                        setState(() {
                          _isResettingPassword = false;
                        });

                        Navigator.pop(context);

                        // Show result dialog
                        _showResetPasswordResultDialog(result);
                      } catch (e) {
                        setState(() {
                          _isResettingPassword = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isResettingPassword
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Reset Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResetPasswordResultDialog(dynamic result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error,
                color: result.success ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 8),
              Text(result.success ? 'Success' : 'Error'),
            ],
          ),
          content: Text(
            result.message,
            style: TextStyle(
              color: AppColors.grey700,
              fontSize: 14,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: result.success ? AppColors.success : AppColors.error,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.edit, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Edit Profile'),
            ],
          ),
          content: Text(
            'Profile editing functionality will be available in the next update. You can currently reset your password using the Reset Password button.',
            style: TextStyle(
              color: AppColors.grey700,
              fontSize: 14,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: AppColors.error),
              const SizedBox(width: 8),
              const Text('Logout'),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: AppColors.grey700,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.grey600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Logout user and navigate to login screen
                final authService = Provider.of<AuthService>(context, listen: false);
                authService.logout();
                
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
