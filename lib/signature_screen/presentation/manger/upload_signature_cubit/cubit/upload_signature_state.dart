part of 'upload_signature_cubit.dart';

@immutable
sealed class UploadSignatureState {}

final class UploadSignatureInitial extends UploadSignatureState {}

final class UploadingSignature extends UploadSignatureState {}
final class UploadSignatureSuccess extends UploadSignatureState {}
final class UploadSignatureFaild extends UploadSignatureState {}