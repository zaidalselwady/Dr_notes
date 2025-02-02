import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import '../../core/repos/data_repo.dart';
import '../../patient_visits_screen/data/image_model.dart';

part 'get_files_state.dart';

class GetFilesCubit extends Cubit<GetFilesState> {
  GetFilesCubit(this.dataRepo) : super(GetFilesInitial());
  final DataRepo dataRepo;

  Future<List<dynamic>> getImages(String folderName) async {
    emit(GettingFiles());
    var result = await dataRepo.soapRequest(
        sqlStr: "",
        action: "IO_get_Images",
        newName: "",
        currentFolder: folderName,
        filePath: "",
        imageBytes: "");
    result.fold((failure) {
      emit(GetFilesFaild(error: failure.errorMsg));
    }, (dMaster) async {
      final document = xml.XmlDocument.parse(dMaster.body);
      if (document.findAllElements('IO_get_ImagesResult').isNotEmpty) {
        final resultElement =
            document.findAllElements('IO_get_ImagesResult').first;
        final jsonString = resultElement.innerText;

        try {
          // Split the Base64 string on commas
          List<String> base64Strings = jsonString.split(',');
          List<ImageModel> imageModels = [];

          for (var element in base64Strings) {
            List<String> parts = element.split("IMAGENAME");

            if (parts.length == 2) {
              String imgName = parts[1].split(' ')[0].trim(); // The image name
              String base64String = parts[0].trim(); // The Base64 string
              // Clean the Base64 string
              String cleanedBase64String =
                  base64String.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
              // Ensure the Base64 string is properly padded
              String base64Padded = cleanedBase64String.padRight(
                (cleanedBase64String.length + 3) ~/ 4 * 4,
                '=',
              );
              // Decode the Base64 string into Uint8List
              Uint8List imgBase64 = base64Decode(base64Padded);
              // Create the ImageModel instance
              imageModels
                  .add(ImageModel(imgName: imgName, imgBase64: imgBase64));
            }
          }
          imageModels.removeAt(0);
          emit(
            GetFilesSuccess(images: imageModels),
          );
        } catch (e) {
          emit(
            GetFilesFaild(
              error: e.toString(),
            ),
          );
        }
      } else {
        emit(GetFilesSuccess(images: const []));
      }
    });
    return [];
  }
}


  // List<String> base64Strings = List<String>.from(json.decode(jsonString));
      // List<Uint8List> imageBytes = base64Strings
      //     .map((base64String) => base64Decode(base64String))
      //     .toList();
      // setState(() {
      //   _images = imageBytes;
      //   _isLoading = false;
      // });
      // final List<dynamic> decodedJson = jsonDecode(jsonString);
      // final List<Map<String, dynamic>> dataList =
      //     List<Map<String, dynamic>>.from(decodedJson);
      // if (dataList.isNotEmpty) {
      //   driver = dataList;
      //   print("drivers $dataList");
      //   // emit(LoadingDriversSuccessful(drivers));
      // }



// for (var element in base64Strings) {
          //   element.split("IMAGENAME");
          // }
          // // Decode each Base64 string
          // List<Uint8List> imageBytesList = base64Strings.map((str) {
          //   String cleanedBase64String =
          //       str.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
          //   String base64Padded = cleanedBase64String.padRight(
          //     (cleanedBase64String.length + 3) ~/ 4 * 4,
          //     '=',
          //   );
          //   return base64Decode(base64Padded);
          // }).toList();
