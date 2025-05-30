import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/ship_to.dart';
import '../../../models/state.dart';
import '../../../services/api_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/validation_state.dart';
import 'state_selection_screen.dart';

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
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();  bool _isLoading = false;
  List<ShipTo> _existingShipToAddresses = [];
  StateModel? _selectedState;
  bool _autoValidate = false;
    @override
  void initState() {
    super.initState();
    _loadExistingShipToAddresses();
    
    // Add listeners for conditional validation
    _postcodeController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
  }
  
  void _onFieldChanged() {
    // Trigger validation when fields change to update conditional validation
    if (_autoValidate) {
      _formKey.currentState?.validate();
    }
  }  @override
  void dispose() {
    // Remove listeners
    _postcodeController.removeListener(_onFieldChanged);
    _cityController.removeListener(_onFieldChanged);
    
    _codeController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    _phoneController.dispose();
    
    // Clear validation state when leaving screen
    ValidationState.instance.clearValidation();
    
    super.dispose();
  }
    Future<void> _loadExistingShipToAddresses() async {
    try {
      final shipToData = await _apiService.getShipToAddresses(customerNo: widget.customerNo);      setState(() {
        _existingShipToAddresses = shipToData.map((json) => ShipTo.fromJson(json)).toList();
      });
    } catch (e) {
      // Handle error silently or log it
      debugPrint('Error loading existing ship-to addresses: $e');
    }}  Future<void> _saveShipToAddress() async {
    print('💾 Save button pressed');
    setState(() {
      _autoValidate = true;
    });
    print('💾 Auto-validate enabled, calling form validation');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }
    print('✅ Form validation passed');
    
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
      'State': _selectedState?.code ?? '',
      'City': _cityController.text.trim(),
      'Post_Code': _postcodeController.text.trim(),
      'Phone_No': _phoneController.text.trim(),
    };    try {
      // Create the ship-to address
      await _apiService.createShipToAddress(shipToData);
      
      // Also create pincode entry if both postcode and city are provided
      final postcode = _postcodeController.text.trim();
      final city = _cityController.text.trim();
      if (postcode.isNotEmpty && city.isNotEmpty) {
        print('📮 Creating pincode entry: $postcode -> $city');
        await _apiService.createPinCode(
          code: postcode,
          city: city,
        );
      }
        // Create ShipTo object to pass back to previous screen
      final newShipTo = ShipTo(
        customerNo: widget.customerNo,
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _selectedState?.code ?? '',
        postCode: _postcodeController.text.trim(),
        phoneNo: _phoneController.text.trim(),
      );
        Navigator.pop(context, newShipTo);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: const Text(
          'Add Ship-To Address',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
          const SizedBox(width: 8),
        ],
      ),      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Compact information card
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info.withOpacity(0.2)),
                  ),                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add a new ship-to address. This address will be available for selection when creating new orders.',
                          style: TextStyle(color: AppColors.info, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                  // Required fields in a more compact layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Code field (increased width)
                    Expanded(
                      flex: 3,
                      child: _buildCompactField(                        controller: _codeController,
                        label: 'Code*',
                        hint: 'Enter unique identifier',                        icon: Icons.code,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          // Check if code already exists
                          final existingCode = _existingShipToAddresses.any(
                            (shipTo) => shipTo.code.toLowerCase() == value.toLowerCase()
                          );
                          if (existingCode) {
                            return 'This code already exists. Please use a unique code.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name field (slightly decreased width)
                    Expanded(
                      flex: 4,
                      child: _buildCompactField(
                        controller: _nameController,
                        label: 'Name*',
                        hint: 'Address name',
                        icon: Icons.business,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Phone and City
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildCompactField(
                        controller: _phoneController,
                        label: 'Phone',
                        hint: 'Contact number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),                    Expanded(
                      child: _buildCompactField(
                        controller: _cityController,
                        label: 'City',
                        hint: 'City',
                        icon: Icons.location_city,
                        validator: _validateCity,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Address row
                _buildCompactField(
                  controller: _addressController,
                  label: 'Address',
                  hint: 'Street address',
                  icon: Icons.location_on,
                ),
                
                const SizedBox(height: 8),
                
                // Address 2 row (optional)
                _buildCompactField(
                  controller: _address2Controller,
                  label: 'Address 2',
                  hint: 'Additional address details',
                  icon: Icons.location_on_outlined,
                ),
                
                const SizedBox(height: 8),                // State and Post Code in a row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [                    Expanded(
                      child: _buildStateSelectionField(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(                      child: _buildCompactField(
                        controller: _postcodeController,
                        label: 'Post Code',
                        hint: 'Postal code',
                        icon: Icons.local_post_office,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: _validatePostCode,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Save button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveShipToAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 1,
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
                            Text('Save Address', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );  }
    Widget _buildStateSelectionField() {    return FormField<StateModel>(
      validator: (value) {
        // State is only required if postcode is filled
        if (_postcodeController.text.trim().isNotEmpty && _selectedState == null) {
          return 'Please select a state when postcode is entered';
        }
        return null;
      },
      builder: (FormFieldState<StateModel> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                final selectedState = await Navigator.push<StateModel>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StateSelectionScreen(),
                  ),
                );                if (selectedState != null) {
                  print('🏛️ State selected: ${selectedState.description}');
                  print('🏛️ State fromPin: ${selectedState.fromPin}, toPin: ${selectedState.toPin}');
                  
                  setState(() {
                    _selectedState = selectedState;
                    // Clear postcode when state changes
                    _postcodeController.clear();
                  });
                  
                  // Set validation state globally
                  ValidationState.instance.setStateValidation(
                    fromPin: selectedState.fromPin,
                    toPin: selectedState.toPin,
                    stateName: selectedState.description,
                  );
                  
                  state.didChange(selectedState);
                  print('🏛️ State selection completed');
                }
              },              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: state.hasError ? Colors.red : AppColors.grey300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.white,
                ),
                child: Row(
                  children: [
                    Icon(Icons.map, color: AppColors.primaryDark, size: 20),
                    const SizedBox(width: 12),
                    Expanded(                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [                          Text(
                            'State',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedState?.description ?? 'Select state',
                            style: TextStyle(
                              color: _selectedState != null ? AppColors.grey800 : AppColors.grey600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: AppColors.grey600, size: 16),
                  ],
                ),
              ),
            ),            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 5),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        );
      },
    );
  }  String? _validateCity(String? value) {
    print('🔍 AddShipToScreen: _validateCity called with: "$value"');
    print('🔍 AddShipToScreen: Postcode controller text: "${_postcodeController.text}"');
    
    // City is only required if postcode is filled
    if (_postcodeController.text.trim().isNotEmpty) {
      if (value == null || value.trim().isEmpty) {
        print('❌ AddShipToScreen: City required because postcode is filled');
        return 'City is required when postcode is entered';
      }
    }
    
    print('✅ AddShipToScreen: City validation passed');
    return null;
  }

  String? _validatePostCode(String? value) {
    print('🔍 AddShipToScreen: _validatePostCode called with: "$value"');
    print('🔍 AddShipToScreen: Selected state: ${_selectedState?.description}');
    
    // Postcode is only required if state is selected
    if (_selectedState == null) {
      // If no state is selected and no postcode is entered, that's fine
      if (value == null || value.trim().isEmpty) {
        print('✅ AddShipToScreen: No state and no postcode - validation passed');
        return null;
      } else {
        // If postcode is entered but no state is selected
        print('❌ AddShipToScreen: Postcode entered but no state selected');
        return 'Please select a state first';
      }
    }
    
    // If state is selected, postcode becomes required
    if (value == null || value.trim().isEmpty) {
      print('❌ AddShipToScreen: State selected but no postcode entered');
      return 'Postcode is required when state is selected';
    }

    print('🔍 AddShipToScreen: Calling ValidationState.instance.validatePostCode');
    // Use the global validation state for range validation
    final result = ValidationState.instance.validatePostCode(value);
    print('🔍 AddShipToScreen: Validation result: "$result"');
    return result;
  }
  
  Widget _buildCompactField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryDark, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        floatingLabelStyle: TextStyle(color: AppColors.primaryDark),
        isDense: true, // Makes the field more compact
        errorMaxLines: 2, // Allow error text to wrap to multiple lines
        errorStyle: const TextStyle(
          fontSize: 12,
          height: 1.2,
        ),
      ),
      style: TextStyle(color: AppColors.grey800, fontSize: 14),
      cursorColor: AppColors.primary,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
    );
  }
}
