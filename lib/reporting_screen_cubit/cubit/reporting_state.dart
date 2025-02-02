part of 'reporting_cubit.dart';

@immutable
sealed class GetSearchFieldsState {}

final class ReportingInitial extends GetSearchFieldsState {}

final class GettingSearchFields extends GetSearchFieldsState {}

final class GetSearchFieldsSuccess extends GetSearchFieldsState {
  final List<FieldInfo> searchFields;

  GetSearchFieldsSuccess({required this.searchFields});
}

final class GetSearchFieldsFailed extends GetSearchFieldsState {
  final String error;

  GetSearchFieldsFailed({required this.error});
}
