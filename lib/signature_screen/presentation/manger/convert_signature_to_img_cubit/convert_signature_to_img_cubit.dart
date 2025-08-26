import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

part 'convert_signature_to_img_state.dart';

class ConvertSignatureToImgCubit extends Cubit<ConvertSignatureToImgState> {
  ConvertSignatureToImgCubit() : super(ConvertSignatureInitial());

  /// Convert the signature canvas to Base64 string
  Future<String?> convertSignatureToBase64(
      SignatureController controller) async {
    emit(ConvertSignatureInitial());
    try {
      emit(ConvertingSignature());
      if (controller.isNotEmpty) {
        final signatureBytes = await controller.toPngBytes();
        if (signatureBytes != null) {
          emit(ConvertSignatureSuccess());
          return base64Encode(signatureBytes);
        } else {
          emit(ConvertSignatureFaild(error: "No Signature"));
        }
      }
    } catch (e) {
      emit(ConvertSignatureFaild(error: e.toString()));
      debugPrint("Error converting signature to Base64: $e");
    }
    return null;
  }
}
