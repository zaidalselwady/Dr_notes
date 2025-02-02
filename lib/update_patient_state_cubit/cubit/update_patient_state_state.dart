part of 'update_patient_state_cubit.dart';

@immutable
sealed class UpdatePatientStateState {}

final class UpdatePatientStateInitial extends UpdatePatientStateState {}

final class UpdatingPatientState extends UpdatePatientStateState {}

final class UpdatePatientStateSuccess extends UpdatePatientStateState {}

final class UpdatePatientStateFaild extends UpdatePatientStateState {
  final String error;

  UpdatePatientStateFaild({required this.error});
}
