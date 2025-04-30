class ShipTo {
  final String customerNo;
  final String code;
  final String name;
  final String? address;
  final String? city;
  final String? state;
  final String? postCode;

  ShipTo({
    required this.customerNo,
    required this.code,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.postCode,
  });

  factory ShipTo.fromJson(Map<String, dynamic> json) {
    return ShipTo(
      customerNo: json['Customer_No'] as String,
      code: json['Code'] as String,
      name: json['Name'] as String,
      address: json['Address'] as String?,
      city: json['City'] as String?,
      state: json['State'] as String?,
      postCode: json['Post_Code'] as String?,
    );
  }

  @override
  String toString() {
    return name;
  }
}