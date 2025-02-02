part of 'delete_patient_cubit.dart';

@immutable
sealed class DeletePatientState {}

final class DeletePatientInitial extends DeletePatientState {}

final class DeletingPatient extends DeletePatientState {}

final class DeletePatientSuccess extends DeletePatientState {
  final int patientId;

  DeletePatientSuccess({required this.patientId});
}

final class DeletePatientFailed extends DeletePatientState {
  final String error;

  DeletePatientFailed({required this.error});
}
