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
  final ShipTo? existingShipTo; // For update mode
  
  const AddShipToScreen({
    Key? key,
    required this.customerNo,
    this.existingShipTo, // Optional for update mode
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
  
  // For tracking changes in update mode
  bool get _isUpdateMode => widget.existingShipTo != null;
  Map<String, String> _originalValues = {}; // Store original values for comparison
  bool _hasChanges = false; // Track if any changes have been made
  @override
  void initState() {
    super.initState();
    _loadExistingShipToAddresses();
    
    // Add listeners for conditional validation and change tracking
    _postcodeController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    _codeController.addListener(_onFieldChanged);
    _nameController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _address2Controller.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    
    // If in update mode, prefill the form with existing data
    if (_isUpdateMode) {
      _prefillFormData();
    }
  }
    void _prefillFormData() {
    final shipTo = widget.existingShipTo!;
    
    print('🔄 Prefilling form with ship-to data:');
    print('  Code: ${shipTo.code}');
    print('  Name: ${shipTo.name}');
    print('  State: ${shipTo.state}');
    print('  Address: ${shipTo.address}');
    print('  City: ${shipTo.city}');
    print('  PostCode: ${shipTo.postCode}');
    print('  Phone: ${shipTo.phoneNo}');
    
    // Set form values
    _codeController.text = shipTo.code;
    _nameController.text = shipTo.name;
    _addressController.text = shipTo.address ?? '';
    _address2Controller.text = shipTo.address2 ?? '';
    _cityController.text = shipTo.city ?? '';
    _postcodeController.text = shipTo.postCode ?? '';
    _phoneController.text = shipTo.phoneNo ?? '';
    
    // Store original values for comparison
    _originalValues = {
      'code': shipTo.code,
      'name': shipTo.name,
      'address': shipTo.address ?? '',
      'address2': shipTo.address2 ?? '',
      'city': shipTo.city ?? '',
      'postCode': shipTo.postCode ?? '',
      'phoneNo': shipTo.phoneNo ?? '',
      'state': shipTo.state ?? '',
    };
    
    // Load states and set selected state based on shipTo.state
    if (shipTo.state?.isNotEmpty == true) {
      print('🔄 Loading state for: ${shipTo.state}');
      _loadAndSetState(shipTo.state!);
    } else {
      print('🔄 No state to load (empty or null)');
    }
  }
    Future<void> _loadAndSetState(String stateCode) async {
    try {
      print('🏛️ Loading state for code: $stateCode');
      final states = await _apiService.getStates();
      print('🏛️ Available states: ${states.length}');
      
      // Find the state that matches the code
      final matchingStateJson = states.cast<Map<String, dynamic>>().firstWhere(
        (state) => state['Code'] == stateCode,
        orElse: () => {},
      );
      
      if (matchingStateJson.isNotEmpty && mounted) {
        final stateModel = StateModel.fromJson(matchingStateJson);
        print('🏛️ Found matching state: ${stateModel.description} (${stateModel.code})');
        setState(() {
          _selectedState = stateModel;
        });
        
        // Also set the validation state for postcode validation
        ValidationState.instance.setStateValidation(
          fromPin: stateModel.fromPin,
          toPin: stateModel.toPin,
          stateName: stateModel.description,
        );
      } else {
        print('🏛️ No matching state found for code: $stateCode');
      }
    } catch (e) {
      debugPrint('Error loading state for prefill: $e');
    }
  }
    void _onFieldChanged() {
    // Check for changes and update _hasChanges flag
    if (_isUpdateMode) {
      final hasChanges = _codeController.text != _originalValues['code'] ||
          _nameController.text != _originalValues['name'] ||
          _addressController.text != _originalValues['address'] ||
          _address2Controller.text != _originalValues['address2'] ||
          _cityController.text != _originalValues['city'] ||
          _postcodeController.text != _originalValues['postCode'] ||
          _phoneController.text != _originalValues['phoneNo'] ||
          (_selectedState?.code ?? '') != _originalValues['state'];
      
      print('🔄 Change detection: hasChanges=$hasChanges, current _hasChanges=$_hasChanges');
      if (hasChanges) {
        print('   - Code: "${_codeController.text}" vs "${_originalValues['code']}" = ${_codeController.text != _originalValues['code']}');
        print('   - Name: "${_nameController.text}" vs "${_originalValues['name']}" = ${_nameController.text != _originalValues['name']}');
        print('   - State: "${_selectedState?.code ?? ''}" vs "${_originalValues['state']}" = ${(_selectedState?.code ?? '') != _originalValues['state']}');
      }
      
      if (hasChanges != _hasChanges) {
        print('🔄 Updating _hasChanges from $_hasChanges to $hasChanges');
        setState(() {
          _hasChanges = hasChanges;
        });
      }
    }
    
    // Trigger validation when fields change to update conditional validation
    if (_autoValidate) {
      _formKey.currentState?.validate();
    }
  }@override
  void dispose() {
    // Remove listeners
    _postcodeController.removeListener(_onFieldChanged);
    _cityController.removeListener(_onFieldChanged);
    _codeController.removeListener(_onFieldChanged);
    _nameController.removeListener(_onFieldChanged);
    _addressController.removeListener(_onFieldChanged);
    _address2Controller.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    
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
    print('💾 Save button pressed - Mode: ${_isUpdateMode ? "Update" : "Create"}');
    setState(() {
      _autoValidate = true;
    });
    print('💾 Auto-validate enabled, calling form validation');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }
    print('✅ Form validation passed');
    
    // In update mode, check if there are changes
    if (_isUpdateMode && !_hasChanges) {
      print('ℹ️ No changes detected in update mode, returning');
      Navigator.pop(context);
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
      // Prepare ship-to data for API
    Map<String, dynamic> shipToData;
      if (_isUpdateMode) {
      // Update API expects different field names with specific case
      shipToData = {
        'custCode': widget.customerNo,
        'code': _codeController.text.trim(),
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'address2': _address2Controller.text.trim(),
        'state': _selectedState?.code ?? '',
        'city': _cityController.text.trim(),
        'postCode': _postcodeController.text.trim(),
        'phoneNo': _phoneController.text.trim(),
      };
    } else {
      // Create API uses standard field names
      shipToData = {
        'Customer_No': widget.customerNo,
        'Code': _codeController.text.trim(),
        'Name': _nameController.text.trim(),
        'Address': _addressController.text.trim(),
        'Address_2': _address2Controller.text.trim(),
        'State': _selectedState?.code ?? '',
        'City': _cityController.text.trim(),
        'Post_Code': _postcodeController.text.trim(),
        'Phone_No': _phoneController.text.trim(),
      };
    }

    try {
      if (_isUpdateMode) {
        print('🔄 Updating existing ship-to address');
        await _apiService.updateShipToAddress(shipToData);
      } else {
        print('➕ Creating new ship-to address');
        await _apiService.createShipToAddress(shipToData);
      }
      
      // Also create pincode entry if both postcode and city are provided (for both create and update)
      final postcode = _postcodeController.text.trim();
      final city = _cityController.text.trim();
      if (postcode.isNotEmpty && city.isNotEmpty) {
        print('📮 Creating pincode entry: $postcode -> $city');
        await _apiService.createPinCode(
          code: postcode,
          city: city,
        );
      }      // Create ShipTo object to pass back to previous screen
      final shipTo = ShipTo(
        customerNo: widget.customerNo,
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _selectedState?.code ?? '',
        postCode: _postcodeController.text.trim(),
        phoneNo: _phoneController.text.trim(),
        // Preserve other fields from existing ship-to if in update mode
        address2: _address2Controller.text.trim(),
        county: widget.existingShipTo?.county,
        contact: widget.existingShipTo?.contact,
        faxNo: widget.existingShipTo?.faxNo,
        email: widget.existingShipTo?.email,
        gln: widget.existingShipTo?.gln,
        gstRegistrationNo: widget.existingShipTo?.gstRegistrationNo,
        shipToGstCustomerType: widget.existingShipTo?.shipToGstCustomerType,
        countryRegionCode: widget.existingShipTo?.countryRegionCode,
        homePage: widget.existingShipTo?.homePage,
        locationCode: widget.existingShipTo?.locationCode,
        arnNo: widget.existingShipTo?.arnNo,
        consignee: widget.existingShipTo?.consignee ?? false,
        lastDateModified: widget.existingShipTo?.lastDateModified,
      );

      print('✅ Ship-to address ${_isUpdateMode ? "updated" : "created"} successfully');
      Navigator.pop(context, shipTo);
    } catch (e) {
      print('❌ Error ${_isUpdateMode ? "updating" : "creating"} ship-to address: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isUpdateMode ? "update" : "create"} ship-to address. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,      appBar: AppBar(
        title: Text(
          _isUpdateMode ? 'Update Ship-To Address' : 'Add Ship-To Address',
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
                : const Icon(Icons.save),            onPressed: _isLoading ? null : (_isUpdateMode && !_hasChanges ? null : _saveShipToAddress),
            tooltip: _isUpdateMode ? 'Update Address' : 'Save Address',
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
                      const SizedBox(width: 12),                      Expanded(
                        child: Text(
                          _isUpdateMode 
                            ? 'Update the ship-to address details. Changes will be saved when you tap the save button.'
                            : 'Add a new ship-to address. This address will be available for selection when creating new orders.',
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
                        hint: 'Enter unique identifier',                        icon: Icons.code,                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          // Check if code already exists (exclude current record in update mode)
                          final existingCode = _existingShipToAddresses.any(
                            (shipTo) => shipTo.code.toLowerCase() == value.toLowerCase() &&
                                       (!_isUpdateMode || shipTo.code != widget.existingShipTo?.code)
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
                
                const SizedBox(height: 20),                // Save button
                ElevatedButton(
                  onPressed: _isLoading ? null : (_isUpdateMode && !_hasChanges ? null : _saveShipToAddress),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_isUpdateMode && !_hasChanges) ? Colors.grey[400] : AppColors.primaryDark,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: (_isUpdateMode && !_hasChanges) ? 0 : 1,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text(
                              _isUpdateMode ? 'Update Address' : 'Save Address', 
                              style: TextStyle(fontSize: 16)
                            ),                          ],
                        ),
                ),
                
                // No changes indicator for update mode
                if (_isUpdateMode && !_hasChanges) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No changes detected. Make changes to the form to enable the update button.',
                            style: TextStyle(
                              color: Colors.grey[600], 
                              fontSize: 13,
                              fontStyle: FontStyle.italic
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  
                  // Call _onFieldChanged to update _hasChanges flag
                  _onFieldChanged();
                  
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
                          ),                          const SizedBox(height: 2),
                          Text(
                            _selectedState?.code ?? 'Select state',
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
