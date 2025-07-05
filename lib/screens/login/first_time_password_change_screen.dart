// lib/screens/login/first_time_password_change_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';

class FirstTimePasswordChangeScreen extends StatefulWidget {
  final String username;
  final String currentPassword;
  final String persona;
  
  const FirstTimePasswordChangeScreen({
    super.key,
    required this.username,
    required this.currentPassword,
    required this.persona,
  });

  @override
  State<FirstTimePasswordChangeScreen> createState() => _FirstTimePasswordChangeScreenState();
}

class _FirstTimePasswordChangeScreenState extends State<FirstTimePasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill the old password with the current password
    _oldPasswordController.text = widget.currentPassword;
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isTablet = screenSize.width > 600;
    
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? 500 : double.infinity,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 80.0 : 24.0,
                            vertical: 16.0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo and app name section
                              RepaintBoundary(
                                child: _buildLogoSection(isSmallScreen, isTablet),
                              ),
                              
                              SizedBox(height: isSmallScreen ? 20 : 30),
                              
                              // Warning message
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.warningLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.warning),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.security, color: AppColors.warning, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'First Time Login',
                                            style: TextStyle(
                                              color: AppColors.warning,
                                              fontSize: isSmallScreen ? 14 : 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'For security reasons, please change your password before continuing.',
                                            style: TextStyle(
                                              color: AppColors.warningDark,
                                              fontSize: isSmallScreen ? 12 : 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Password change form
                              RepaintBoundary(
                                child: _buildPasswordChangeForm(authService, isSmallScreen, isTablet),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(bool isSmallScreen, bool isTablet) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/logo.png',
                height: isSmallScreen ? 40 : (isTablet ? 60 : 50),
                width: isSmallScreen ? 40 : (isTablet ? 60 : 50),
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: isSmallScreen ? 40 : (isTablet ? 60 : 50),
                    width: isSmallScreen ? 40 : (isTablet ? 60 : 50),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.agriculture,
                      color: AppColors.white,
                      size: 30,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Flexible(
              child: Text(
                'Sampoorna Feeds',
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : (isTablet ? 28 : 24),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordChangeForm(AuthService authService, bool isSmallScreen, bool isTablet) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isTablet ? 400 : double.infinity,
      ),
      padding: EdgeInsets.all(isSmallScreen ? 16 : (isTablet ? 24 : 20)),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'Change Your Password',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: AppColors.grey800,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: isSmallScreen ? 16 : 20),
            
            // Old password field (read-only)
            _buildTextField(
              controller: _oldPasswordController,
              label: 'Current Password',
              icon: Icons.lock_outline,
              isPassword: true,
              isReadOnly: true,
              obscureText: _obscureOldPassword,
              onToggleVisibility: () {
                setState(() {
                  _obscureOldPassword = !_obscureOldPassword;
                });
              },
              isSmallScreen: isSmallScreen,
            ),
            
            SizedBox(height: isSmallScreen ? 12 : 16),
            
            // New password field
            _buildTextField(
              controller: _newPasswordController,
              label: 'New Password',
              icon: Icons.lock,
              isPassword: true,
              obscureText: _obscureNewPassword,
              onToggleVisibility: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
              isSmallScreen: isSmallScreen,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a new password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                if (value == widget.currentPassword) {
                  return 'New password must be different from current password';
                }
                return null;
              },
            ),
            
            SizedBox(height: isSmallScreen ? 12 : 16),
            
            // Confirm password field
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              icon: Icons.lock_reset,
              isPassword: true,
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              isSmallScreen: isSmallScreen,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your new password';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            
            SizedBox(height: isSmallScreen ? 20 : 24),

            // Error message
            if (authService.error != null && authService.error!.isNotEmpty && !_isLoading)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authService.error ?? 'An error occurred',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Change password button
            _buildChangePasswordButton(isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isPassword,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    bool isReadOnly = false,
    bool isSmallScreen = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: isReadOnly,
      style: TextStyle(
        fontSize: isSmallScreen ? 14 : 16,
        color: isReadOnly ? AppColors.grey600 : null,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isReadOnly ? AppColors.grey100 : AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        prefixIcon: Icon(icon, size: isSmallScreen ? 20 : 24),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  size: isSmallScreen ? 20 : 24,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isSmallScreen ? 12 : 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildChangePasswordButton(bool isSmallScreen) {
    return SizedBox(
      height: isSmallScreen ? 45 : 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _handlePasswordChange(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.grey300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? SizedBox(
                height: isSmallScreen ? 20 : 24,
                width: isSmallScreen ? 20 : 24,
                child: const CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Change Password',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _handlePasswordChange(BuildContext context) async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    // Hide keyboard immediately
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final result = await authService.resetPassword(
        userId: widget.username,
        oldPassword: _oldPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
        persona: widget.persona,
      );
      
      if (result.success) {
        // Password changed successfully, complete the login process
        final loginSuccess = await authService.completeFirstTimeLogin(
          widget.username,
          _newPasswordController.text.trim(),
          persona: widget.persona,
        );
        
        if (loginSuccess && mounted) {
          // Navigate based on persona
          if (widget.persona == 'customer') {
            Navigator.pushReplacementNamed(context, '/customer');
          } else if (widget.persona == 'team') {
            Navigator.pushReplacementNamed(context, '/team');
          } else {
            Navigator.pushReplacementNamed(context, '/sales');
          }
        }
      }
    } catch (e) {
      // Error handling is done by AuthService
      debugPrint('Password change error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
