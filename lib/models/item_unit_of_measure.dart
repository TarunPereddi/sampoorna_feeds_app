class ItemUnitOfMeasure {
  final String itemNo;
  final String code;
  final double qtyPerUnitOfMeasure;
  final String itemUnitOfMeasure;
  
  ItemUnitOfMeasure({
    required this.itemNo,
    required this.code,
    required this.qtyPerUnitOfMeasure,
    required this.itemUnitOfMeasure,
  });
  
  factory ItemUnitOfMeasure.fromJson(Map<String, dynamic> json) {
    return ItemUnitOfMeasure(
      itemNo: json['Item_No'] as String,
      code: json['Code'] as String,
      qtyPerUnitOfMeasure: json['Qty_per_Unit_of_Measure'] != null 
        ? (json['Qty_per_Unit_of_Measure'] is int 
          ? (json['Qty_per_Unit_of_Measure'] as int).toDouble() 
          : json['Qty_per_Unit_of_Measure'] as double) 
        : 0.0,
      itemUnitOfMeasure: json['ItemUnitOfMeasure'] as String,
    );
  }
  
  @override
  String toString() {
    return code;
  }
}