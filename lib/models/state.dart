class StateModel {
  final String code;
  final String description;
  final int fromPin;
  final int toPin;

  StateModel({
    required this.code,
    required this.description,
    required this.fromPin,
    required this.toPin,
  });  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      code: json['Code'] as String? ?? '',
      description: json['Description'] as String? ?? '',
      fromPin: int.tryParse(json['From_PIN_Code']?.toString() ?? '0') ?? 0,
      toPin: int.tryParse(json['To_PIN_Code']?.toString() ?? '999999') ?? 999999,
    );
  }

  @override
  String toString() {
    return description;
  }
}
