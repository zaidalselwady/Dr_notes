part of 'convert_signature_to_img_cubit.dart';

@immutable
sealed class ConvertSignatureToImgState {}

final class ConvertSignatureInitial extends ConvertSignatureToImgState {}

final class ConvertingSignature extends ConvertSignatureToImgState {}

final class ConvertSignatureSuccess extends ConvertSignatureToImgState {}

final class ConvertSignatureFaild extends ConvertSignatureToImgState {
  final String error;

  ConvertSignatureFaild({required this.error});
}
