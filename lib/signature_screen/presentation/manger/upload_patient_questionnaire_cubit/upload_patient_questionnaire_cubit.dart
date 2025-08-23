import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import '../../../../core/repos/data_repo.dart';
import '../../../../questionnaire_screen/data/questionnaire_model.dart';

part 'upload_patient_questionnaire_state.dart';

class UploadPatientQuestionnaireCubit
    extends Cubit<UploadPatientQuestionnaireState> {
  UploadPatientQuestionnaireCubit(this.dataRepo)
      : super(UploadPatientQuestionnaireInitial());
  final DataRepo dataRepo;
  Future<void> uploadPatientQuestionnaire(
    List<QuestionnaireModel> questionnaireAnswers, int patientId) async {
  emit(UploadingPatientQuestionnaire());
  
  // Convert answers to bit representation
  List<String> bitAnswers = questionnaireAnswers.map((q) {
    if (q.answer == null) return 'NULL';
    return q.answer! ? '1' : '0';
  }).toList();
  
  // Convert notes to SQL-safe format
  List<String> noteValues = questionnaireAnswers.map((q) {
    if (q.answer == true && q.note != null && q.note!.isNotEmpty) {
      // Escape single quotes and wrap in quotes
      final escapedNote = q.note!.replaceAll("'", "''");
      return "'$escapedNote'";
    }
    return 'NULL';
  }).toList();
  
  // Build the complete INSERT statement with both answers and notes
  final String insertQuery = """
    INSERT INTO Patients_Questionnaire(
      Patient_id,
      Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11, Q12, Q13, Q14,
      Q1_Note, Q2_Note, Q3_Note, Q4_Note, Q5_Note, Q6_Note, Q7_Note,
      Q8_Note, Q9_Note, Q10_Note, Q11_Note, Q12_Note, Q13_Note, Q14_Note
    ) VALUES (
      $patientId,
      ${bitAnswers.join(', ')},
      ${noteValues.join(', ')}
    )
  """;
  
  var response = await dataRepo.fetchWithSoapRequest("Insert_Update_cmd", insertQuery);
  
  response.fold((failure) {
    emit(UploadPatientQuestionnaireFaild(error: failure.errorMsg));
  }, (inserted) async {
    final document = xml.XmlDocument.parse(inserted.body);
    final resultElement =
        document.findAllElements('Insert_Update_cmdResult').first;
    final jsonString = resultElement.innerText;
    emit(UploadPatientQuestionnaireSuccess(patientId: patientId));
  });
}
  // Future<void> uploadPatientQuestionnaire(
  //     List<QuestionnaireModel> questionnaireAnswers, int patientId) async {
  //   emit(UploadingPatientQuestionnaire());
  //   // Convert answers to bit representation
  //   List<int?> bitAnswers = questionnaireAnswers.map((q) {
  //     q.answer == null
  //         ? null
  //         : q.answer!
  //             ? 1
  //             : 0;
  //   }).toList();
  //   // Convert list to a comma-separated string
  //   String bitValues = bitAnswers.join(",");

  //   var response = await dataRepo.fetchWithSoapRequest("Insert_Update_cmd",
  //       "INSERT INTO Patients_Questionnaire(Patient_id,Q1,Q2,Q3,Q4,Q5,Q6,Q7,Q8,Q9,Q10,Q11,Q12,Q13,Q14)Values($patientId,$bitValues)");

  //   response.fold((failure) {
  //     emit(UploadPatientQuestionnaireFaild(error: failure.errorMsg));
  //   }, (inserted) async {
  //     final document = xml.XmlDocument.parse(inserted.body);
  //     final resultElement =
  //         document.findAllElements('Insert_Update_cmdResult').first;
  //     final jsonString = resultElement.innerText;
  //     emit(UploadPatientQuestionnaireSuccess(patientId: patientId));
  //   });
  // }
}
