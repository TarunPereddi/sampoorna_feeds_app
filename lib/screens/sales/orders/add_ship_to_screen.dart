import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/ship_to.dart';
import '../../../services/api_service.dart';
import '../../../widgets/common_app_bar.dart';

class AddShipToScreen extends StatefulWidget {
  final String customerNo;
  
  const AddShipToScreen({
    Key? key,
    required this.customerNo,
  }) : super(key: key);
  
  @override
  State<AddShipToScreen> createState() => _AddShipToScreenState();
}

class _AddShipToScreenState extends State<AddShipToScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  bool _isLoading = false;
  List<ShipTo> _existingShipToAddresses = [];
  
  @override
  void initState() {
    super.initState();
    _loadExistingShipToAddresses();
  }
  
  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _loadExistingShipToAddresses() async {
    try {
      final shipToData = await _apiService.getShipToAddresses(customerNo: widget.customerNo);
      setState(() {
        _existingShipToAddresses = shipToData.map((json) => ShipTo.fromJson(json)).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading existing ship-to addresses: $e')),
      );
    }
  }
  
  Future<void> _saveShipToAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Check if code already exists
    final existingCode = _existingShipToAddresses.any(
      (shipTo) => shipTo.code.toLowerCase() == _codeController.text.toLowerCase()
    );
    
    if (existingCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This code already exists. Please use a unique code.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Prepare ship-to data for API
    final shipToData = {
      'Customer_No': widget.customerNo,
      'Code': _codeController.text.trim(),
      'Name': _nameController.text.trim(),
      'Address': _addressController.text.trim(),
      'Address_2': _address2Controller.text.trim(),
      'State': _stateController.text.trim(),
      'City': _cityController.text.trim(),
      'Post_Code': _postcodeController.text.trim(),
      'Phone_No': _phoneController.text.trim(), // Added phone number
    };
      try {
      // Create the ship-to address
      await _apiService.createShipToAddress(shipToData);
      
      // Create ShipTo object to pass back to previous screen
      final newShipTo = ShipTo(
        customerNo: widget.customerNo,
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postCode: _postcodeController.text.trim(),
        phoneNo: _phoneController.text.trim(),
      );
      
      Navigator.pop(context, newShipTo);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ship-to address added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding ship-to address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CommonAppBar(
        title: 'Add Ship-To Address',
        actions: [
          // Save action button
          IconButton(
            icon: _isLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveShipToAddress,
            tooltip: 'Save Address',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Information card
                Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 24),
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Add a new ship-to address for this customer. This address will be available for selection when creating new orders.',
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Code field
                _buildFormField(
                  controller: _codeController,
                  label: 'Code*',
                  hint: 'Enter a unique code (e.g., MAIN, STORE1)',
                  icon: Icons.code,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Code is required';
                    }
                    return null;
                  },
                ),
                
                // Name field
                _buildFormField(
                  controller: _nameController,
                  label: 'Name*',
                  hint: 'Enter a name for this address',
                  icon: Icons.business,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                
                // Phone field
                _buildFormField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter contact phone number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                
                // Address field
                _buildFormField(
                  controller: _addressController,
                  label: 'Address',
                  hint: 'Enter street address',
                  icon: Icons.location_on,
                  maxLines: 2,
                ),
                
                // Address 2 field
                _buildFormField(
                  controller: _address2Controller,
                  label: 'Address 2',
                  hint: 'Enter additional address details',
                  icon: Icons.location_on_outlined,
                ),
                
                // City field
                _buildFormField(
                  controller: _cityController,
                  label: 'City',
                  hint: 'Enter city',
                  icon: Icons.location_city,
                ),
                
                // State field
                _buildFormField(
                  controller: _stateController,
                  label: 'State',
                  hint: 'Enter state',
                  icon: Icons.map,
                ),
                
                // Post Code field
                _buildFormField(
                  controller: _postcodeController,
                  label: 'Post Code',
                  hint: 'Enter postal code',
                  icon: Icons.local_post_office,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Save button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveShipToAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text('Save Ship-To Address', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
      ),
    );
  }
}
