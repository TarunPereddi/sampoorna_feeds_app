class ValidationState {
  static ValidationState? _instance;
  static ValidationState get instance => _instance ??= ValidationState._();
  
  ValidationState._();
  
  int? _fromPin;
  int? _toPin;
  String? _stateName;
    void setStateValidation({
    required int fromPin,
    required int toPin,
    required String stateName,
  }) {
    _fromPin = fromPin;
    _toPin = toPin;
    _stateName = stateName;
  }
    void clearValidation() {
    _fromPin = null;
    _toPin = null;
    _stateName = null;
  }
  
  bool get hasValidation => _fromPin != null && _toPin != null;
  
  int? get fromPin => _fromPin;
  int? get toPin => _toPin;
  String? get stateName => _stateName;
    String? validatePostCode(String? value) {
    
    if (value == null || value.isEmpty) {
      return 'Post code is required';
    }
    
    final postCode = int.tryParse(value);
    if (postCode == null) {
      return 'Invalid post code';
    }
    
    
    if (!hasValidation) {
      return null; // No validation data available
    }
    
    // Convert 3-digit pins to 6-digit postcodes
    final fromRange = _fromPin! * 1000;
    final toRange = _toPin! * 1000 + 999;
    
    if (postCode < fromRange || postCode > toRange) {
      final errorMessage = 'Post code must be between ${fromRange.toString().padLeft(6, '0')} and ${toRange.toString().padLeft(6, '0')}';
      return errorMessage;
    }
    
    return null;
  }
}
