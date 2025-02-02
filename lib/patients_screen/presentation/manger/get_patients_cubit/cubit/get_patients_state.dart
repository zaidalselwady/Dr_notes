part of 'get_patients_cubit.dart';

@immutable
sealed class GetPatientsState {}

final class GetPatientsInitial extends GetPatientsState {}

final class GettingPatients extends GetPatientsState {}

final class GetPatientsSuccess extends GetPatientsState {
  final List<PatientInfo> patients;

  GetPatientsSuccess({required this.patients});
}

final class GetPatientsFaild extends GetPatientsState {
  final String error;

  GetPatientsFaild({required this.error});
}
