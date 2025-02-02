part of 'patient_questionnaire_cubit.dart';

@immutable
sealed class PatientQuestionnaireState {}

final class PatientQuestionnaireInitial extends PatientQuestionnaireState {}

final class GettingPatientQuestionnaire extends PatientQuestionnaireState {}

final class GetPatientQuestionnaireSuccess extends PatientQuestionnaireState {
  final List<QuestionnaireModel> patientQuestionnaireModel;

  GetPatientQuestionnaireSuccess({required this.patientQuestionnaireModel});
}

final class GetPatientQuestionnaireFailed extends PatientQuestionnaireState {
  final String error;

  GetPatientQuestionnaireFailed({required this.error});
}
