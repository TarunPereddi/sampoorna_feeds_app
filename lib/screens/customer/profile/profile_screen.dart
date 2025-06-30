import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common_app_bar.dart';
import '../../../services/auth_service.dart';
import '../../../mixins/tab_refresh_mixin.dart';
import '../../../utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TabRefreshMixin {
  bool _isLoading = false;
  String? _errorMessage;

  // TabRefreshMixin implementation
  @override
  int get tabIndex => 3; // Profile tab index

  @override
  Future<void> performRefresh() async {
    setState(() {
      _errorMessage = null;
    });
    // No API call needed, just refresh UI from global state
  }

  @override
  void initState() {
    super.initState();
    // No API call needed
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This ensures TabRefreshMixin can check for refreshes
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
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(bool isTablet) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final customer = authService.currentUser;
    if (customer == null) {
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
    // Convert customer to Map for compatibility with existing widgets
    final customerMap = {
      'No': customer.no,
      'Name': customer.name,
      'E_Mail': customer.emailId,
      'Phone_No': customer.phone,
      'Address': customer.address,
      'City': customer.city,
      'State_Code': customer.stateCode,
      'GST_Registration_No': customer.gstNo,
      'P_A_N_No': customer.panNo,
      'Customer_Price_Group': customer.customerPriceGroup,
      'Balance_LCY': customer.balanceLcy,
      'Blocked': customer.blocked,
      'Responsibility_Center': customer.customerPriceGroup, // Example mapping
    };
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Compact Profile header
            _buildCompactProfileHeader(customerMap, isTablet),
            
            const SizedBox(height: 16),
            
            // Personal Information card
            _buildPersonalInfoCard(customerMap, isTablet),
            
            const SizedBox(height: 12),
            
            // Business Information card
            _buildBusinessInfoCard(customerMap, isTablet),
            
            const SizedBox(height: 20),
            
            // Action buttons section - Reset Password and Logout
            _buildActionButtons(customerMap, isTablet),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Add this new method for compact header
  Widget _buildCompactProfileHeader(Map<String, dynamic> customer, bool isTablet) {
    return Card(
      elevation: 2,
      shadowColor: AppColors.grey300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Profile picture with status indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    (customer['Name'] != null && customer['Name'].toString().isNotEmpty) 
                        ? customer['Name'].toString()[0].toUpperCase() 
                        : 'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: customer['Blocked'] == true ? AppColors.error : AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: Icon(
                      customer['Blocked'] == true ? Icons.block : Icons.check_circle,
                      color: AppColors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer['Name'] ?? 'Unknown User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${customer['No'] ?? ''}',
                    style: TextStyle(
                      color: AppColors.grey600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary, width: 1),
                    ),
                    child: Text(
                      'Customer',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
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
  }

  // Update the action buttons section
  Widget _buildActionButtons(Map<String, dynamic> customer, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showResetPasswordDialog(context, customer),
            icon: const Icon(Icons.lock_reset, size: 18),
            label: const Text('Reset Password'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(Map<String, dynamic> customer, bool isTablet) {
    return Card(
      elevation: 1,
      shadowColor: AppColors.grey300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AppColors.grey300, height: 1),
            const SizedBox(height: 12),
            _buildProfileDetailItem('Full Name', customer['Name'] ?? 'N/A', Icons.badge),
            if (customer['E_Mail'] != null && customer['E_Mail'].toString().isNotEmpty)
              _buildProfileDetailItem('Email', customer['E_Mail'], Icons.email),
            if (customer['Phone_No'] != null && customer['Phone_No'].toString().isNotEmpty)
              _buildProfileDetailItem('Phone', customer['Phone_No'], Icons.phone),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoCard(Map<String, dynamic> customer, bool isTablet) {
    return Card(
      elevation: 1,
      shadowColor: AppColors.grey300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business_center,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Business Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AppColors.grey300, height: 1),
            const SizedBox(height: 12),
            _buildProfileDetailItem(
              'Responsibility Center', 
              customer['Responsibility_Center'] ?? 'N/A', 
              Icons.work_outline,
            ),
            _buildProfileDetailItem(
              'Account Status', 
              customer['Blocked'] == true ? 'Blocked' : 'Active', 
              customer['Blocked'] == true ? Icons.block : Icons.check_circle,
              valueColor: customer['Blocked'] == true ? AppColors.error : AppColors.success,
            ),
            _buildProfileDetailItem(
              'Commission %', 
              customer['Commission_Percent']?.toString() ?? 'N/A', 
              Icons.percent,
            ),
            _buildProfileDetailItem(
              'Location', 
              customer['Location'] ?? 'N/A', 
              Icons.location_on,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetailItem(
    String label, 
    String value, 
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
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
                fontSize: 13,
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
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ResetPasswordDialog(
          customer: customer,
          onSuccess: (result) {
            _showResetPasswordResultDialog(result);
          },
        );
      },
    );
  }

  void _showResetPasswordResultDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final bool success = result['success'] ?? false;
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error_outline,
                  color: success ? AppColors.success : AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  success ? 'Success' : 'Error',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result['message'] ?? (success ? 'Password reset successfully' : 'Failed to reset password'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.grey700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: success ? AppColors.success : AppColors.error,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
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
              ),              onPressed: () async {
                // Logout user and navigate to login screen
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.logout();
                
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

class ResetPasswordDialog extends StatefulWidget {
  final Map<String, dynamic> customer;
  final Function(Map<String, dynamic>) onSuccess;

  const ResetPasswordDialog({
    super.key,
    required this.customer,
    required this.onSuccess,
  });

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final formKey = GlobalKey<FormState>();
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool obscureOldPassword = true;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: screenSize.width > 600 ? 400 : screenSize.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.lock_reset, color: AppColors.info),
                  const SizedBox(width: 8),
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.grey300),
            
            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Please enter your current password and new password.',
                          style: TextStyle(
                            color: AppColors.grey700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Old Password Field
                        _buildPasswordField(
                          controller: oldPasswordController,
                          label: 'Current Password',
                          hint: 'Enter your current password',
                          obscureText: obscureOldPassword,
                          onToggleVisibility: () {
                            setState(() => obscureOldPassword = !obscureOldPassword);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your current password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // New Password Field
                        _buildPasswordField(
                          controller: newPasswordController,
                          label: 'New Password',
                          hint: 'Enter your new password',
                          obscureText: obscureNewPassword,
                          onToggleVisibility: () {
                            setState(() => obscureNewPassword = !obscureNewPassword);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your new password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Confirm Password Field
                        _buildPasswordField(
                          controller: confirmPasswordController,
                          label: 'Confirm New Password',
                          hint: 'Confirm your new password',
                          obscureText: obscureConfirmPassword,
                          onToggleVisibility: () {
                            setState(() => obscureConfirmPassword = !obscureConfirmPassword);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password';
                            }
                            if (value != newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.grey600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Future<void> _handleResetPassword() async {
    if (formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final customer = authService.currentUser;
        final userId = customer?.no ?? '';
        final result = await authService.resetPassword(
          userId: userId,
          oldPassword: oldPasswordController.text.trim(),
          newPassword: newPasswordController.text.trim(),
          persona: 'customer',
        );

        if (!mounted) return;
        // Prefer statusCode for success/failure, fallback to message if not present
        bool isSuccess = false;
        if (result.statusCode != null) {
          isSuccess = (result.statusCode == 200);
        } else {
          // fallback: check message
          isSuccess = result.message.toLowerCase().contains('success');
        }
        Navigator.pop(context);
        widget.onSuccess({
          'success': isSuccess,
          'message': result.message,
        });
        // No snackbar on either success or error, dialog will handle all feedback
      } catch (e) {
        setState(() => isLoading = false);
        if (!mounted) return;
        String errorMsg = e.toString();
        if (errorMsg.contains('400')) {
          errorMsg = 'Wrong password';
        }
        Navigator.pop(context);
        widget.onSuccess({
          'success': false,
          'message': errorMsg,
        });
      }
    }
  }
}
