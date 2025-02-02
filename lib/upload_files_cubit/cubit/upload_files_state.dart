part of 'upload_files_cubit.dart';

@immutable
sealed class UploadFilesState {}

final class UploadFilesInitial extends UploadFilesState {}

class UploadingFiles extends UploadFilesState {}

class UploadFilesSuccess extends UploadFilesState {
  final String responseString;
  UploadFilesSuccess(this.responseString);
}

class UploadFilesError extends UploadFilesState {
  final String errorMessage;
  UploadFilesError(this.errorMessage);
}
