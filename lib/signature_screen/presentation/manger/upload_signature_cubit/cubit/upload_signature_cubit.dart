import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'upload_signature_state.dart';

class UploadSignatureCubit extends Cubit<UploadSignatureState> {
  UploadSignatureCubit() : super(UploadSignatureInitial());
  
}
