class Customer {
  final String no;
  final String name;
  final String? phone;
  final String? address;
  final String? city;
  final String? stateCode;
  final String? gstNo;
  final String? panNo;
  final double balanceLcy;

  Customer({
    required this.no,
    required this.name,
    this.phone,
    this.address,
    this.city,
    this.stateCode,
    this.gstNo,
    this.panNo,
    this.balanceLcy = 0,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      no: json['No'] as String,
      name: json['Name'] as String,
      phone: json['Phone_No'] as String?,
      address: json['Address'] as String?,
      city: json['City'] as String?,
      stateCode: json['State_Code'] as String?,
      gstNo: json['GST_Registration_No'] as String?,
      panNo: json['P_A_N_No'] as String?,
      balanceLcy: json['Balance_LCY'] != null 
        ? (json['Balance_LCY'] is int 
          ? (json['Balance_LCY'] as int).toDouble() 
          : json['Balance_LCY'] as double) 
        : 0,
    );
  }

  @override
  String toString() {
    return name;
  }
}