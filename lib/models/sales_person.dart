// lib/models/sales_person.dart
class SalesPerson {
  final String code;
  final String name;
  final String responsibilityCenter;
  final bool blocked;
  final String email;
  final String location;
  final String phoneNo;
  final bool isTeamLeader; // Added field for Sales_Team
  final String teamCode; // Added field for Sales_Team_Code
  
  SalesPerson({
    required this.code,
    required this.name,
    required this.responsibilityCenter,
    required this.blocked,
    this.email = '',
    this.location = '',
    this.phoneNo = '',
    this.isTeamLeader = false, // Default to false
    this.teamCode = '', // Default to empty string
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
      isTeamLeader: json['Sales_Team'] as bool? ?? false, // Map Sales_Team field
      teamCode: json['Sales_Team_Code'] as String? ?? '', // Map Sales_Team_Code field
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
      'Sales_Team': isTeamLeader, // Include in JSON
      'Sales_Team_Code': teamCode, // Include in JSON
    };
  }
  
  List<String> get locationCodes => 
      location.isNotEmpty ? location.split(',') : [];
      
  List<String> get codes => 
      code.isNotEmpty ? code.split(',') : [];
}