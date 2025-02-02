part of 'get_proc_cubit.dart';

@immutable
sealed class GetProcState {}

final class GetProcInitial extends GetProcState {}
final class GettingProc extends GetProcState {}
final class GetProcSuccess extends GetProcState {
  final List<Procedures> proc;

  GetProcSuccess({required this.proc});

}
final class GetProcFailed extends GetProcState {
  final String error;

  GetProcFailed({required this.error});
}
