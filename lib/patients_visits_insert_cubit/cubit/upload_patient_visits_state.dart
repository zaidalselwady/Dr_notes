part of 'upload_patient_visits_cubit.dart';

@immutable
sealed class UploadPatientVisitsState {}

final class UploadPatientVisitsInitial extends UploadPatientVisitsState {}

final class UploadingPatientVisits extends UploadPatientVisitsState {}

final class UploadPatientVisitsSuccess extends UploadPatientVisitsState {}

final class UploadPatientVisitsFailed extends UploadPatientVisitsState {
  final String error;

  UploadPatientVisitsFailed({required this.error});
}
