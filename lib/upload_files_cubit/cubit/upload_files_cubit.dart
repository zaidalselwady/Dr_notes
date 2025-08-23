
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import '../../core/repos/data_repo.dart';

part 'upload_files_state.dart';

class UploadFilesCubit extends Cubit<UploadFilesState> {
  UploadFilesCubit(this.dataRepo) : super(UploadFilesInitial());
  final DataRepo dataRepo;

  Future<void> uploadPhoto(String folderName, String base64Image,
      String imageName, String patientFolder) async {
    try {
      emit(UploadingFiles());
      //final base64Image = await convertCanvasToB64();
      var result = await dataRepo.soapRequest(
          action: "WriteImageFile",
          newName: folderName,
          currentFolder: "",
          filePath:
              "DrApp/$patientFolder/$imageName.png", 
          imageBytes: base64Image,
          sqlStr: "");
      result.fold((failure) {
        emit(UploadFilesError(failure.errorMsg));
      }, (dMaster) async {
        final document = xml.XmlDocument.parse(dMaster.body);
        final resultElement =
            document.findAllElements('WriteImageFileResult').first;
        final responseString = resultElement.innerText;
        if (responseString == "Success") {
          emit(
            UploadFilesSuccess(responseString),
          );
        } else {
          emit(
            UploadFilesError(responseString),
          );
        }
      });
    } catch (e) {
      emit(UploadFilesError(e.toString()));
    }
  }
}
