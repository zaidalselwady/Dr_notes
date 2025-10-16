//Procedure_Desc   Procedure_id    Patients_Procedures
import 'dart:typed_data';

class ImageModel {
  String imgName;
  Uint8List? imgBase64;
  String? strokesJson;

  ImageModel({
    this.strokesJson,
    this.imgBase64,
    required this.imgName,
  });

  // You can also add methods to serialize/deserialize to/from JSON if needed
  Map<String, dynamic> toJson() {
    return {
      'strokesJson': strokesJson,
      'imgName': imgName,
      'imgBase64': imgBase64,
    };
  }

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      strokesJson: json['strokesJson'],
      imgBase64: json['imgBase64'],
      imgName: json['imgName'],
    );
  }
  bool get isDrawing => strokesJson != null && strokesJson!.isNotEmpty;
  bool get isImage => imgBase64 != null && imgBase64!.isNotEmpty;
  // @override
  // String toString() {
  //   return 'QuestionnaireModel(Procedure_id: $procedureId,Procedure_Desc: $procedureDesc)';
  // }
}
