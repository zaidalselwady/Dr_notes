part of 'get_generated_report_result_cubit.dart';

@immutable
sealed class GetGeneratedReportResultState {}

final class GetGeneratedReportResultInitial
    extends GetGeneratedReportResultState {}

final class GettingGeneratedReportResult
    extends GetGeneratedReportResultState {}

final class GetGeneratedReportResultSuccess
    extends GetGeneratedReportResultState {
  final List<dynamic> generatedReportScreen;

  GetGeneratedReportResultSuccess({required this.generatedReportScreen});
}

final class GetGeneratedReportResultFailed
    extends GetGeneratedReportResultState {
  final String error;

  GetGeneratedReportResultFailed({required this.error});
}
