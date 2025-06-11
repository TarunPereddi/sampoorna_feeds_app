class SalesShipment {
  final String etag;
  final String no;
  final String customerCode;
  final String customerName;
  final String postingDate;
  final String salespersonCode;
  final int otp;
  final bool otpVerified;

  SalesShipment({
    required this.etag,
    required this.no,
    required this.customerCode,
    required this.customerName,
    required this.postingDate,
    required this.salespersonCode,
    required this.otp,
    required this.otpVerified,
  });

  factory SalesShipment.fromJson(Map<String, dynamic> json) {
    return SalesShipment(
      etag: json['@odata.etag'] ?? '',
      no: json['No'] ?? '',
      customerCode: json['CustomerCode'] ?? '',
      customerName: json['CustomerName'] ?? '',
      postingDate: json['PostingDate'] ?? '',
      salespersonCode: json['SalespersonCode'] ?? '',
      otp: json['OTP'] ?? 0,
      otpVerified: json['OTPVarified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '@odata.etag': etag,
      'No': no,
      'CustomerCode': customerCode,
      'CustomerName': customerName,
      'PostingDate': postingDate,
      'SalespersonCode': salespersonCode,
      'OTP': otp,
      'OTPVarified': otpVerified,
    };
  }
}

class SalesShipmentResponse {
  final String odataContext;
  final List<SalesShipment> value;

  SalesShipmentResponse({
    required this.odataContext,
    required this.value,
  });

  factory SalesShipmentResponse.fromJson(Map<String, dynamic> json) {
    return SalesShipmentResponse(
      odataContext: json['@odata.context'] ?? '',
      value: (json['value'] as List<dynamic>?)
              ?.map((item) => SalesShipment.fromJson(item))
              .toList() ??
          [],
    );
  }
}
