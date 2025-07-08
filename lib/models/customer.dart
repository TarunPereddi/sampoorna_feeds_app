class Customer {
  final String no;
  final String name;
  final String? phone;
  final String? address;
  final String? emailId;
  final String? city;
  final String? stateCode;
  final String? gstNo;
  final String? panNo;  final String? customerPriceGroup; // Add this field
  final double balanceLcy;
  final String? customerLocation; // Add customerLocation field
  final String? blocked; // Add blocked field
  final String? responsibilityCenter; // Add responsibility center field
  final String? salespersonCode; // Add salesperson code field
  final bool? mobileAppEnable; // Add mobile app enable field

  Customer({
    required this.no,
    required this.name,
    this.phone,
    this.address,
    this.emailId,
    this.city,
    this.stateCode,
    this.gstNo,
    this.panNo,
    this.customerPriceGroup, // Add to constructor
    this.balanceLcy = 0,
    this.customerLocation,
    this.blocked, // Add to constructor
    this.responsibilityCenter, // Add to constructor
    this.salespersonCode, // Add to constructor
    this.mobileAppEnable, // Add to constructor
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      no: json['No'] as String,
      name: json['Name'] as String,
      phone: json['Phone_No'] as String?,
      address: json['Address'] as String?,
      emailId: json['E_Mail'] as String?,
      city: json['City'] as String?,
      stateCode: json['State_Code'] as String?,
      gstNo: json['GST_Registration_No'] as String?,
      panNo: json['P_A_N_No'] as String?,      customerPriceGroup: json['Customer_Price_Group'] as String?, // Add to fromJson
      balanceLcy: json['Balance_LCY'] != null 
        ? (json['Balance_LCY'] is int 
          ? (json['Balance_LCY'] as int).toDouble() 
          : json['Balance_LCY'] as double) 
        : 0,
      blocked: json['Blocked'] as String?, // Add blocked field from JSON
      customerLocation: json['Customer_Location'] as String?, // Add customerLocation field from JSON
      responsibilityCenter: json['Responsibility_Center'] as String?, // Add responsibility center field from JSON
      salespersonCode: json['Salesperson_Code'] as String?, // Add salesperson code field from JSON
      mobileAppEnable: json['Mobile_App_Enable'] as bool?, // Add mobile app enable field from JSON
    );
  }

  // Get location codes from customerLocation (comma-separated string)
  List<String> get locationCodes {
    if (customerLocation != null && customerLocation!.isNotEmpty) {
      return customerLocation!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  @override
  String toString() {
    return name;
  }
}