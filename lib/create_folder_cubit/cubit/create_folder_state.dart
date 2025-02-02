part of 'create_folder_cubit.dart';

@immutable
sealed class CreateFolderState {}

final class CreateFolderInitial extends CreateFolderState {}

final class CreatingFolder extends CreateFolderState {}

final class CreateFolderSuccess extends CreateFolderState {
  final String folderName;

  CreateFolderSuccess({required this.folderName});
}

final class CreateFolderFaild extends CreateFolderState {
  final String error;

  CreateFolderFaild({required this.error});
}
