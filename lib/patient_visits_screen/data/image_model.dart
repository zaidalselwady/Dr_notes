//Procedure_Desc   Procedure_id    Patients_Procedures
import 'dart:typed_data';

class ImageModel {
  String imgName;
  Uint8List imgBase64;

  ImageModel({
    required this.imgName,
    required this.imgBase64,
  });

  // You can also add methods to serialize/deserialize to/from JSON if needed
  Map<String, dynamic> toJson() {
    return {
      'imgName': imgName,
      'imgBase64': imgBase64,
    };
  }

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      imgName: json['imgName'],
      imgBase64: json['imgBase64'],
    );
  }
  // @override
  // String toString() {
  //   return 'QuestionnaireModel(Procedure_id: $procedureId,Procedure_Desc: $procedureDesc)';
  // }
}
