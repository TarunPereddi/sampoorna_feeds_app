class ShipTo {
  final String customerNo;
  final String code;
  final String name;
  final String? gln;
  final String? address;
  final String? address2;
  final String? city;
  final String? county;
  final String? postCode;
  final String? state;
  final String? countryRegionCode;
  final String? phoneNo;
  final String? contact;
  final String? faxNo;
  final String? email;
  final String? homePage;
  final String? locationCode;
  final String? gstRegistrationNo;
  final String? arnNo;
  final bool consignee;
  final String? shipToGstCustomerType;
  final String? lastDateModified;

  ShipTo({
    required this.customerNo,
    required this.code,
    required this.name,
    this.gln,
    this.address,
    this.address2,
    this.city,
    this.county,
    this.postCode,
    this.state,
    this.countryRegionCode,
    this.phoneNo,
    this.contact,
    this.faxNo,
    this.email,
    this.homePage,
    this.locationCode,
    this.gstRegistrationNo,
    this.arnNo,
    this.consignee = false,
    this.shipToGstCustomerType,
    this.lastDateModified,
  });

  factory ShipTo.fromJson(Map<String, dynamic> json) {
    return ShipTo(
      customerNo: json['Customer_No'] as String,
      code: json['Code'] as String,
      name: json['Name'] as String,
      gln: json['GLN'] as String?,
      address: json['Address'] as String?,
      address2: json['Address_2'] as String?,
      city: json['City'] as String?,
      county: json['County'] as String?,
      postCode: json['Post_Code'] as String?,
      state: json['State'] as String?,
      countryRegionCode: json['Country_Region_Code'] as String?,
      phoneNo: json['Phone_No'] as String?,
      contact: json['Contact'] as String?,
      faxNo: json['Fax_No'] as String?,
      email: json['E_Mail'] as String?,
      homePage: json['Home_Page'] as String?,
      locationCode: json['Location_Code'] as String?,
      gstRegistrationNo: json['GST_Registration_No'] as String?,
      arnNo: json['ARN_No'] as String?,
      consignee: json['Consignee'] as bool? ?? false,
      shipToGstCustomerType: json['Ship_to_GST_Customer_Type'] as String?,
      lastDateModified: json['Last_Date_Modified'] as String?,
    );
  }

  // Helper method to get formatted address
  String get formattedAddress {
    List<String> addressParts = [];
    
    if (address != null && address!.isNotEmpty) {
      addressParts.add(address!);
    }
    if (address2 != null && address2!.isNotEmpty) {
      addressParts.add(address2!);
    }
    if (city != null && city!.isNotEmpty) {
      addressParts.add(city!);
    }
    if (state != null && state!.isNotEmpty) {
      addressParts.add(state!);
    }
    if (postCode != null && postCode!.isNotEmpty) {
      addressParts.add(postCode!);
    }
    
    return addressParts.join(', ');
  }

  @override
  String toString() {
    return name;
  }
}