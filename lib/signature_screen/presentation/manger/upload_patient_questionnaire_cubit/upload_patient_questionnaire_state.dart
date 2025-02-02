part of 'upload_patient_questionnaire_cubit.dart';

@immutable
sealed class UploadPatientQuestionnaireState {}

final class UploadPatientQuestionnaireInitial
    extends UploadPatientQuestionnaireState {}

final class UploadingPatientQuestionnaire
    extends UploadPatientQuestionnaireState {}

final class UploadPatientQuestionnaireSuccess
    extends UploadPatientQuestionnaireState {
  final int patientId;

  UploadPatientQuestionnaireSuccess({required this.patientId});
}

final class UploadPatientQuestionnaireFaild
    extends UploadPatientQuestionnaireState {
  final String error;

  UploadPatientQuestionnaireFaild({required this.error});
}
