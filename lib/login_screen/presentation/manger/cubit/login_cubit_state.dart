part of 'login_cubit.dart';

@immutable
sealed class LoginState {}

final class GetUsersInitial extends LoginState {}

final class GettingUsers extends LoginState {}

final class GetUsersSuccess extends LoginState {
  final User user;
  GetUsersSuccess({required this.user});
}

final class GetUsersFailed extends LoginState {
  final String massege;
  GetUsersFailed(this.massege);
}
