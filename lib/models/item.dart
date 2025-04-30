class Item {
  final String no;
  final String description;
  final String? itemCategoryCode;
  final double unitPrice;
  final String? inventoryPostingGroup;
  final String? itemLocation;

  Item({
    required this.no,
    required this.description,
    this.itemCategoryCode,
    required this.unitPrice,
    this.inventoryPostingGroup,
    this.itemLocation,
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
    );
  }

  @override
  String toString() {
    return '$description ($no)';
  }
}