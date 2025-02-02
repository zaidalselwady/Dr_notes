part of 'update_patient_info_cubit.dart';

@immutable
sealed class UpdatePatientInfoState {}

final class UpdatePatientInfoInitial extends UpdatePatientInfoState {}

final class UpdatingPatientInfo extends UpdatePatientInfoState {}

final class UpdatePatientInfoSuccess extends UpdatePatientInfoState {
  
}

final class UpdatePatientInfoFailed extends UpdatePatientInfoState {
  final String error;

  UpdatePatientInfoFailed({required this.error});
}
