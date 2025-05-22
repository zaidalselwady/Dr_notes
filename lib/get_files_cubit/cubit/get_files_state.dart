part of 'get_files_cubit.dart';

@immutable
sealed class GetFilesState {}

final class GetFilesInitial extends GetFilesState {}

final class GettingFiles extends GetFilesState {}

final class GetFilesSuccess extends GetFilesState {
  final List<ImageModel> images;

  GetFilesSuccess({required this.images});
}



final class GetFilesFaild extends GetFilesState {
  final String error;

  GetFilesFaild({required this.error});
}
