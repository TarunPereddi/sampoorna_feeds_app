// lib/screens/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/persona_state.dart';
import '../../utils/app_colors.dart';
import 'forgot_password_screen.dart';
import 'first_time_password_change_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedPersona = 'sales'; // Default to sales persona
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final credentials = await authService.getSavedCredentials();
    
    setState(() {
      _usernameController.text = credentials['username'] ?? '';
      _passwordController.text = credentials['password'] ?? '';
      _rememberMe = credentials['rememberMe'] ?? false;
    });
  }  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      backgroundColor: AppColors.background, // Light green background
      // In login_screen.dart, wrap the body content with SingleChildScrollView:

body: SafeArea(
 child: LayoutBuilder(
   builder: (context, constraints) {
     return SingleChildScrollView(  // Add this
       child: ConstrainedBox(      // Add this
         constraints: BoxConstraints(
           minHeight: constraints.maxHeight,  // Ensure it takes full height
         ),
         child: IntrinsicHeight(   // Add this
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
                   children: [                     // Logo and app name section
                     RepaintBoundary(
                       child: _buildLogoSection(isSmallScreen, isTablet),
                     ),
                     
                     SizedBox(height: isSmallScreen ? 30 : 40),
                     
                     // Login form
                     RepaintBoundary(
                       child: _buildLoginForm(authService, isSmallScreen, isTablet),
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
    );
  }

  Widget _buildLogoSection(bool isSmallScreen, bool isTablet) {
    return Column(
      children: [
        // Logo and app name row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [            Container(
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
                    ),                    child: const Icon(
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

  Widget _buildLoginForm(AuthService authService, bool isSmallScreen, bool isTablet) {
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
            // Username field
            _buildTextField(
              controller: _usernameController,
              label: 'Username',
              icon: Icons.person,
              isSmallScreen: isSmallScreen,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your username';
                }
                return null;
              },
            ),
            
            SizedBox(height: isSmallScreen ? 12 : 16),
            
            // Password field
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock,
              isPassword: true,
              isSmallScreen: isSmallScreen,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),

            SizedBox(height: isSmallScreen ? 12 : 16),

// Forgot Password link (add this right after password field)
Align(
 alignment: Alignment.centerRight,
 child: TextButton(
   onPressed: () => _navigateToForgotPassword(),
   style: TextButton.styleFrom(
     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
     minimumSize: Size.zero,
     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
   ),
   child: Text(
     'Forgot Password?',
     style: TextStyle(
       fontSize: isSmallScreen ? 12 : 13,
       color: AppColors.primary,
       fontWeight: FontWeight.w500,
     ),
   ),
 ),
),

// Remember Me checkbox
Row(
  children: [
    Checkbox(
      value: _rememberMe,
      onChanged: (value) {
        setState(() {
          _rememberMe = value ?? false;
        });
      },
      activeColor: AppColors.primary,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    ),
    Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _rememberMe = !_rememberMe;
          });
        },
        child: Text(
          'Remember me',
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            color: AppColors.grey700,
          ),
        ),
      ),
    ),
  ],
),

            
            SizedBox(height: isSmallScreen ? 16 : 24),

            // Persona Selection
            _buildPersonaSelection(isSmallScreen),
            
            SizedBox(height: isSmallScreen ? 16 : 20),            // Error message
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

            // Login button
            _buildLoginButton(isSmallScreen),
            
            // Development Mock Login Button (only for customer persona) - HIDDEN FOR NOW
            // if (_selectedPersona == 'customer') ...[
            //   const SizedBox(height: 8),
            //   SizedBox(
            //     height: isSmallScreen ? 40 : 45,
            //     child: ElevatedButton(
            //       onPressed: _isLoading ? null : () => _handleMockLogin(context),
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: Colors.orange,
            //         foregroundColor: Colors.white,
            //         disabledBackgroundColor: AppColors.grey300,
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(10),
            //         ),
            //         elevation: 2,
            //       ),
            //       child: Text(
            //         'DEV: Mock Customer Login',
            //         style: TextStyle(
            //           fontSize: isSmallScreen ? 12 : 14,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isSmallScreen = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.white,        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: AppColors.grey300),
        ),        enabledBorder: OutlineInputBorder(
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
         _obscurePassword ? Icons.visibility : Icons.visibility_off,
         size: isSmallScreen ? 20 : 24,
       ),
       onPressed: () {
         setState(() {
           _obscurePassword = !_obscurePassword;
         });
       },
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

  Widget _buildPersonaSelection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Your Role',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: AppColors.grey800,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),

        // Persona selection with segmented control style
        Container(          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.grey300),
          ),
          child: Row(
            children: [
              _buildPersonaSegment('Customer', 'customer', Icons.people, 
                  isSmallScreen: isSmallScreen),
              _buildPersonaSegment('Team', 'team', Icons.store, 
                  isSmallScreen: isSmallScreen),
              _buildPersonaSegment('Sales', 'sales', Icons.business_center, 
                  isSmallScreen: isSmallScreen),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonaSegment(String title, String value, IconData icon, 
      {bool isDisabled = false, bool isSmallScreen = false}) {
    bool isSelected = _selectedPersona == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // if (isDisabled) {
          //   _showComingSoonDialog(title);
          // } else {
            setState(() {
              _selectedPersona = value;
            });
          // }
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 10 : 12,
            horizontal: 4,
          ),
          decoration: BoxDecoration(            color: isSelected && !isDisabled 
                ? AppColors.primary 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [              Icon(
                icon,
                color: isDisabled 
                    ? AppColors.grey400 
                    : isSelected 
                        ? AppColors.white 
                        : AppColors.grey600,
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                title,                style: TextStyle(
                  color: isDisabled 
                      ? AppColors.grey400 
                      : isSelected 
                          ? AppColors.white 
                          : AppColors.grey600,
                  fontWeight: isSelected && !isDisabled 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                  fontSize: isSmallScreen ? 11 : 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isSmallScreen) {
    return SizedBox(
      height: isSmallScreen ? 45 : 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _handleLogin(context),        style: ElevatedButton.styleFrom(
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
                width: isSmallScreen ? 20 : 24,                child: const CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Login',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _showComingSoonDialog(String featureType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.schedule, color: AppColors.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text('$featureType Portal Coming Soon'),
              ),
            ],
          ),
          content: const Text(
            'We\'re working hard to bring you this feature. Please check back soon!',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  Future<void> _handleLogin(BuildContext context) async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    // Hide keyboard immediately
    FocusScope.of(context).unfocus();
    
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    setState(() {
      _isLoading = true;
    });
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      // Save credentials if remember me is checked
      await authService.saveLoginCredentials(username, password, _rememberMe);
      dynamic result;

      // Pass persona to login
      result = await authService.login(username, password, persona: _selectedPersona);

      // Set global persona state after successful login
      if ((result == true || result == 'first_login')) {
        PersonaState.setPersona(_selectedPersona);
      }

      if (result == 'first_login') {
        // Navigate to first-time password change screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FirstTimePasswordChangeScreen(
                username: username,
                currentPassword: password,
                persona: _selectedPersona,
              ),
            ),
          );
        }
      } else if (result == true) {
        // Navigate to the correct shell based on persona
        if (mounted) {
          if (_selectedPersona == 'sales') {
            Navigator.pushReplacementNamed(context, '/sales');
          } else if (_selectedPersona == 'team') {
            Navigator.pushReplacementNamed(context, '/team');
          } else if (_selectedPersona == 'customer') {
            Navigator.pushReplacementNamed(context, '/customer');
          }
        }
      } else if (result == false) {
        // Login failed - check if it's a customer login permission issue
        final authService = Provider.of<AuthService>(context, listen: false);
        if (authService.error == 'Customer login not permitted' && _selectedPersona == 'customer') {
          // Clear the password field for security and reset states
          setState(() {
            _passwordController.clear();
          });
        }
      }
    } catch (e) {
      // Error handling is done by AuthService
      debugPrint('Login error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Mock login handler for development
  Future<void> _handleMockLogin(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Create mock customer data with Mobile_App_Enable set to true
      final mockCustomerData = {
        'No': 'SFC00030',
        'Name': 'DHUMAN SINGH POULTRY FARM PROP DHUMAN SINGH',
        'Phone_No': '9814156806',
        'Address': 'S/O:SHANKAR SINGH ,HIALA,NAWANSHAHAR,PUNJAB',
        'E_Mail': '',
        'City': 'NAWANSHAHR',
        'State_Code': 'PB',
        'GST_Registration_No': '', // Unregistered customer
        'P_A_N_No': 'BJBPS9115D',
        'Customer_Price_Group': 'PB-25%-170',
        'Balance_LCY': 132847,
        'Customer_Location': '', // Empty as per API data
        'Blocked': ' ',
        'Responsibility_Center': 'FEED',
        'Salesperson_Code': 'SAM36',
        'Mobile_App_Enable': true, // Set to true for mock login (overriding the false from API data)
      };

      // Set mock customer directly in auth service
      await authService.setMockCustomer(mockCustomerData, 'customer');
      
      // Set global persona state
      PersonaState.setPersona('customer');
      
      // Navigate to customer shell
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/customer');
      }
    } catch (e) {
      debugPrint('Mock login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mock login failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Navigate to forgot password screen
  void _navigateToForgotPassword() async {
    final returnedUserID = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => ForgotPasswordScreen(
          initialUserID: _usernameController.text.trim(),
          persona: _selectedPersona,
        ),
      ),
    );
    
    // Update the username field with the returned user ID
    if (returnedUserID != null && returnedUserID.isNotEmpty) {
      setState(() {
        _usernameController.text = returnedUserID;
      });
    }
  }
}