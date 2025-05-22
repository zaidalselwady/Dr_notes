import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import '../../../../../core/repos/data_repo.dart';
import '../../../../../questionnaire_screen/data/questionnaire_model.dart';

part 'patient_questionnaire_state.dart';

class PatientQuestionnaireCubit extends Cubit<PatientQuestionnaireState> {
  PatientQuestionnaireCubit(this.dataRepo)
      : super(PatientQuestionnaireInitial());
  final DataRepo dataRepo;

  Future<void> fetchPatientsWithSoapRequest(int patientId) async {
    emit(GettingPatientQuestionnaire());
    var result = await dataRepo.fetchWithSoapRequest("getJson_select",
        "SELECT * FROM Patients_Questionnaire Where Patient_id=$patientId");
    result.fold((failure) {
      emit(GetPatientQuestionnaireFailed(error: failure.errorMsg));
    }, (dMaster) async {
      final document = xml.XmlDocument.parse(dMaster.body);

      final elements = document.findAllElements('getJson_selectResult');
// Check if the elements list is not empty before accessing the first element
      if (elements.isNotEmpty) {
        final resultElement = elements.first;
        final jsonString = resultElement.innerText;
        // Decode the JSON string to a list of maps
        final decodedJson = jsonDecode(jsonString);
        final questionnaireList = <QuestionnaireModel>[];
        if (decodedJson is List && decodedJson.isNotEmpty) {
          // Assuming the list contains a single object, since the DB response is an array of one object
          final response = decodedJson.first;
          // Generate the questionnaire list
          // Iterate over the keys (Q1, Q2, Q3, etc.)
          response.forEach((key, value) {
            // Check if the key starts with "Q" and if the value is not null
            if (key.startsWith('Q') ) {
              // Create a questionnaire model and add it to the list
              questionnaireList.add(
                QuestionnaireModel.fromDb(key, value),
              );
            }
          });
          if (questionnaireList.isNotEmpty) {
            if (isClosed) {}
            emit(GetPatientQuestionnaireSuccess(
                patientQuestionnaireModel: questionnaireList));
          } else {
            int result = int.parse(jsonString);
            if (result > 0) {
            } else {}
          }
        } else {
          emit(GetPatientQuestionnaireFailed(error: "No Medical history"));
        }
      } else {
        emit(GetPatientQuestionnaireFailed(error: ""));
      }
    });
  }
}
