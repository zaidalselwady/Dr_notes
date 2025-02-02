class FieldInfo {
  int id;
  int fieldWidth;
  String fieldDesc;
  String? fieldOrdName;
  String? fieldPreName;
  String fieldName;
  int fieldOrder;
  String? fieldType;
  bool isVisible;
  String? fieldGroup;

  FieldInfo({
    this.id = 0,
    required this.fieldWidth,
    required this.fieldDesc,
    this.fieldOrdName,
    this.fieldPreName,
    required this.fieldName,
    required this.fieldOrder,
    this.fieldType,
    required this.isVisible,
    this.fieldGroup,
  });

  /// Convert the object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Field_Width': fieldWidth,
      'Field_Desc': fieldDesc,
      'Field_Ord_Name': fieldOrdName,
      'Field_Pre_Nam': fieldPreName,
      'Field_Name': fieldName,
      'Field_Order': fieldOrder,
      'Field_Type': fieldType,
      'is_Visible': isVisible,
      'Field_Group': fieldGroup,
    };
  }

  /// Create an object from JSON
  factory FieldInfo.fromJson(Map<String, dynamic> json) {
    return FieldInfo(
      id: json['id'],
      fieldWidth: json['Field_Width'] ?? 0,
      fieldDesc: json['Field_Desc'] ?? "",
      fieldOrdName: json['Field_Ord_Name'] ?? "",
      fieldPreName: json['Field_Pre_Name'] ?? "",
      fieldName: json['Field_Name'] ?? "",
      fieldOrder: json['Field_Order'] ?? 0,
      fieldType: json['Field_Type'] ?? "",
      isVisible: json['is_Visible'] ?? false,
      fieldGroup: json['Field_Group'] ?? "",
    );
  }

  @override
  String toString() {
    return 'FieldInfo(id: $id, fieldWidth: $fieldWidth, fieldDesc: $fieldDesc, fieldOrdName: $fieldOrdName, fieldPreName: $fieldPreName, fieldName: $fieldName, fieldOrder: $fieldOrder, fieldType: $fieldType, isVisible: $isVisible,fieldGroup:$fieldGroup)';
  }
}
