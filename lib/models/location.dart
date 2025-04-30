class Location {
  final String code;
  final String name;
  final String? stateCode;

  Location({
    required this.code,
    required this.name,
    this.stateCode,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      code: json['Code'] as String,
      name: json['Name'] as String,
      stateCode: json['State_Code'] as String?,
    );
  }

  @override
  String toString() {
    return name;
  }
}