class SalesOrder {
  final String no;
  final String customerNo;
  final DateTime orderDate;
  final DateTime? shipmentDate;
  final String status;
  final String? locationCode;
  final String? freight;
  final String? currencyCode;
  final String? paymentTermsCode;
  final String? customerName; // Not from API, for display purposes

  SalesOrder({
    required this.no,
    required this.customerNo,
    required this.orderDate,
    this.shipmentDate,
    required this.status,
    this.locationCode,
    this.freight,
    this.currencyCode,
    this.paymentTermsCode,
    this.customerName,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    return SalesOrder(
      no: json['No'] as String,
      customerNo: json['Sell_to_Customer_No'] as String,
      orderDate: DateTime.parse(json['Order_Date']),
      shipmentDate: json['Shipment_Date'] != null ? DateTime.parse(json['Shipment_Date']) : null,
      status: json['Status'] as String,
      locationCode: json['Location_Code'] as String?,
      freight: json['Freight'] as String?,
      currencyCode: json['Currency_Code'] as String?,
      paymentTermsCode: json['Payment_Terms_Code'] as String?,
    );
  }
}

class SalesOrderLine {
  final String documentNo;
  final String no;
  final double quantity;
  final double unitPrice;
  final double lineAmount;
  final String? hsnSacCode;
  final String? gstGroupCode;

  SalesOrderLine({
    required this.documentNo,
    required this.no,
    required this.quantity,
    required this.unitPrice,
    required this.lineAmount,
    this.hsnSacCode,
    this.gstGroupCode,
  });

  factory SalesOrderLine.fromJson(Map<String, dynamic> json) {
    return SalesOrderLine(
      documentNo: json['Document_No'] as String,
      no: json['No'] as String,
      quantity: json['Quantity'] != null 
        ? (json['Quantity'] is int 
          ? (json['Quantity'] as int).toDouble() 
          : json['Quantity'] as double) 
        : 0.0,
      unitPrice: json['Unit_Price'] != null 
        ? (json['Unit_Price'] is int 
          ? (json['Unit_Price'] as int).toDouble() 
          : json['Unit_Price'] as double) 
        : 0.0,
      lineAmount: json['Line_Amount'] != null 
        ? (json['Line_Amount'] is int 
          ? (json['Line_Amount'] as int).toDouble() 
          : json['Line_Amount'] as double) 
        : 0.0,
      hsnSacCode: json['HSN_SAC_Code'] as String?,
      gstGroupCode: json['GST_Group_Code'] as String?,
    );
  }
}