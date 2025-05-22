//Procedure_Desc   Procedure_id    Patients_Procedures
class Procedures {
  int id;
  int procedureId;
  int procIdPv;
  int patientId;
  String procedureDesc;
  String mainProcedureDesc;
  int mainProcedureId;
  int procStatus;
  String visitDate;
  String notes;

  Procedures({
    this.id = 0,
    this.procedureId = 0,
    this.procIdPv = 0,
    this.patientId = 0,
    required this.procedureDesc,
    required this.mainProcedureDesc,
    required this.mainProcedureId,
    this.procStatus = 0,
    this.visitDate = "",
    this.notes = "",
  });

  // You can also add methods to serialize/deserialize to/from JSON if needed
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Procedure_id': procedureId,
      'Proc_id_pv': procIdPv,
      'Patient_Id': patientId,
      'Procedure_Desc': procedureDesc,
      'Main_Procedure_Desc': mainProcedureDesc,
      'Main_Procedure_id': mainProcedureId,
      'Procedure_Status': procStatus,
      'Visit_Date': visitDate,
      'Notes': notes
    };
  }

  factory Procedures.fromJson(Map<String, dynamic> json) {
    return Procedures(
      id: json['id'] ?? 0,
      procedureId: json['Procedure_id'],
      procIdPv: json['Proc_id_pv'] ?? 0,
      patientId: json['Patient_Id'] ?? 0,
      procedureDesc: json['Procedure_Desc'],
      mainProcedureDesc: json['Main_Procedure_Desc']??"",
      mainProcedureId: json['Main_Procedure_id']??0,
      procStatus: json['Procedure_Status'] ?? 0,
      visitDate: json['Visit_Date'] ?? "",
      notes: json['Notes'] ?? "",
    );
  }
  @override
  String toString() {
    return 'QuestionnaireModel(id:$id,Procedure_id: $procedureId,Procedure_Desc: $procedureDesc,Procedure_Status: $procStatus,Notes: $notes,Visit_Date: $visitDate,Proc_id_pv: $procIdPv,Patient_Id:$patientId,)';
  }
}
