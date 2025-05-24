// lib/screens/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'forgot_password_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // Light green background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and app name on the same line
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 50,
                        width: 50,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sampoorna Feeds',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Login form with light green background
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              prefixIcon: const Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: TextButton(
                                onPressed: () => _navigateToForgotPassword(),
                                child: const Text(
                                  'Forgot?',
                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Persona Selection
                          const Text(
                            'Select Your Role',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Persona selection with segmented control style
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                _buildPersonaSegment('Customer', 'customer', Icons.people, isDisabled: true),
                                _buildPersonaSegment('Vendor', 'vendor', Icons.store, isDisabled: true),
                                _buildPersonaSegment('Sales', 'sales', Icons.business_center),
                              ],
                            ),
                          ),

                          // Show error message if login fails
                          if (authService.error != null && !_isLoading)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                authService.error!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _handleLogin(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Login',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonaSegment(String title, String value, IconData icon, {bool isDisabled = false}) {
    bool isSelected = _selectedPersona == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isDisabled) {
            // Show "Coming Soon" popup for disabled options
            _showComingSoonDialog(title);
          } else {
            setState(() {
              _selectedPersona = value;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected && !isDisabled ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isDisabled 
                    ? Colors.grey.shade400 
                    : isSelected 
                        ? Colors.white 
                        : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isDisabled 
                      ? Colors.grey.shade400 
                      : isSelected 
                          ? Colors.white 
                          : Colors.grey,
                  fontWeight: isSelected && !isDisabled ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
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
          title: Row(
            children: [
              Icon(Icons.schedule, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text('$featureType Portal Coming Soon'),
            ],
          ),
          content: const Text(
            'We\'re working hard to bring you this feature. Please check back soon!',
            style: TextStyle(fontSize: 16),
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
  Future<void> _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Hide keyboard immediately
    FocusScope.of(context).unfocus();
    
    final username = _usernameController.text;
    final password = _passwordController.text;
    
    setState(() {
      _isLoading = true;
    });

    if (_selectedPersona == 'sales') {
      // Use AuthService for sales persona
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.login(username, password);
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        // Navigate to sales shell
        Navigator.pushReplacementNamed(context, '/sales');
      }
    } else {
      // For customer and vendor personas, use the original navigation
      setState(() {
        _isLoading = false;
      });
      
      Navigator.pushReplacementNamed(context, '/$_selectedPersona');
    }
  }  // Navigate to forgot password screen
  void _navigateToForgotPassword() async {
    final returnedUserID = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => ForgotPasswordScreen(
          initialUserID: _usernameController.text,
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
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}