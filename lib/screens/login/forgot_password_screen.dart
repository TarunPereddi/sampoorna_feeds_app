// lib/screens/login/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';


class ForgotPasswordScreen extends StatefulWidget {
  final String initialUserID;
  final String persona;

  const ForgotPasswordScreen({
    super.key,
    this.initialUserID = '',
    this.persona = 'sales',
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialUserID.isNotEmpty) {
      _userIdController.text = widget.initialUserID;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 500 : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Please enter your User ID and registered mobile number to recover your password',
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    
                    // User ID field
                    TextFormField(
                      controller: _userIdController,
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      decoration: InputDecoration(
                        labelText: 'User ID',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                        prefixIcon: Icon(Icons.person, size: isSmallScreen ? 20 : 24),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your User ID';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // Mobile number field
                    TextFormField(
                      controller: _phoneNumberController,
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      decoration: InputDecoration(
                        labelText: 'Registered Mobile Number',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                        prefixIcon: Icon(Icons.phone, size: isSmallScreen ? 20 : 24),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your registered mobile number';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    
                    // Submit button
                    SizedBox(
                      height: isSmallScreen ? 45 : 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                          ? SizedBox(
                              height: isSmallScreen ? 20 : 24,
                              width: isSmallScreen ? 20 : 24,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Reset Password',
                              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
    Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    // Hide keyboard immediately
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.forgotPassword(
      _userIdController.text,
      _phoneNumberController.text,
      persona: widget.persona,
    );
    
    if (result.success) {
      setState(() {
        _isLoading = false;
      });
      
      // Show a dialog with the success message
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 8),
                  const Text('Success'),
                ],
              ),
              content: Text(result.message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    // Return to login screen with the user ID
                    Navigator.of(context).pop(_userIdController.text);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      
      // Show a dialog with the error message
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Error'),
                ],
              ),
              content: Text(result.message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog only
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }
}
