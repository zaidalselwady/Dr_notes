part of 'save_user_locally_cubit.dart';

@immutable
sealed class SaveUserLocallyState {}

final class SaveUserLocallyInitial extends SaveUserLocallyState {}

final class SavingUserLocally extends SaveUserLocallyState {}

final class SaveUserLocallySuccess extends SaveUserLocallyState {
  final User user;

  SaveUserLocallySuccess({required this.user});
}

final class SaveUserLocallyFailed extends SaveUserLocallyState {
  final String error;

  SaveUserLocallyFailed({required this.error});
}

final class GetUserLocally extends SaveUserLocallyState {
  final User user;

  GetUserLocally({required this.user});
}
