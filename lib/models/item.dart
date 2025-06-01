class Item {
  final String no;
  final String description;
  final String? itemCategoryCode;
  final double unitPrice;
  final String? inventoryPostingGroup;
  final String? itemLocation;
  final String? salesUnitOfMeasure; // Add this field
  final bool blocked; // Add blocked field

  Item({
    required this.no,
    required this.description,
    this.itemCategoryCode,
    required this.unitPrice,
    this.inventoryPostingGroup,
    this.itemLocation,
    this.salesUnitOfMeasure, // Add to constructor
    this.blocked = false, // Add to constructor with default value
  });
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      no: json['No'] as String,
      description: json['Description'] as String,
      itemCategoryCode: json['Item_Category_Code'] as String?,
      unitPrice: json['Unit_Price'] != null 
        ? (json['Unit_Price'] is int 
          ? (json['Unit_Price'] as int).toDouble() 
          : json['Unit_Price'] as double) 
        : 0.0,
      inventoryPostingGroup: json['Inventory_Posting_Group'] as String?,
      itemLocation: json['Item_Location'] as String?,
      salesUnitOfMeasure: json['Sales_Unit_of_Measure'] as String?,
      blocked: json['Blocked'] as bool? ?? false, // Add blocked field from JSON
    );
  }

  @override
  String toString() {
    return '$description ($no)';
  }
}