// lib/models/sales_person.dart
class SalesPerson {
  final String code;
  final String name;
  final String responsibilityCenter;
  final bool blocked;
  final String email;
  final String location;
  final String phoneNo;
  
  SalesPerson({
    required this.code,
    required this.name,
    required this.responsibilityCenter,
    required this.blocked,
    this.email = '',
    this.location = '',
    this.phoneNo = '',
  });
    factory SalesPerson.fromJson(Map<String, dynamic> json) {
    return SalesPerson(
      code: json['Code'] as String,
      name: json['Name'] as String,
      responsibilityCenter: json['Responsibility_Center'] as String? ?? '',
      blocked: json['Block'] as bool? ?? false,
      email: json['E_Mail'] as String? ?? '',
      location: json['Location'] as String? ?? '',
      phoneNo: json['Phone_No'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Code': code,
      'Name': name,
      'Responsibility_Center': responsibilityCenter,
      'Block': blocked,
      'E_Mail': email,
      'Location': location,
      'Phone_No': phoneNo,
    };
  }
  
  List<String> get locationCodes => 
      location.isNotEmpty ? location.split(',') : [];
      
  List<String> get codes => 
      code.isNotEmpty ? code.split(',') : [];
}