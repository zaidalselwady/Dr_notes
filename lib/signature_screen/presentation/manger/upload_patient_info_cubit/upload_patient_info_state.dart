part of 'upload_patient_info_cubit.dart';

@immutable
sealed class UploadPatientInfoState {}

final class UploadPatientInfoInitial extends UploadPatientInfoState {}

final class UploadingPatientInfo extends UploadPatientInfoState {}

final class UploadPatientInfoSuccess extends UploadPatientInfoState {
  final int patientId;

  UploadPatientInfoSuccess({required this.patientId});
}

final class UploadPatientInfoFaild extends UploadPatientInfoState {
  final String error;

  UploadPatientInfoFaild({required this.error});
}
