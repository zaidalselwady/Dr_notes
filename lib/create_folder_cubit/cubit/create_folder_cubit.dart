import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../../core/repos/data_repo.dart';
import 'package:xml/xml.dart' as xml;
part 'create_folder_state.dart';

class CreateFolderCubit extends Cubit<CreateFolderState> {
  CreateFolderCubit(this.dataRepo) : super(CreateFolderInitial());
  final DataRepo dataRepo;

  List<Map<String, dynamic>> driver = [];
  Future<List<dynamic>> createFolder(String folderName) async {
    emit(CreatingFolder());
    var result = await dataRepo.soapRequest(
        sqlStr: "",
        action: "IO_Create_Folder",
        newName: folderName,
        currentFolder: "",
        filePath: "",
        imageBytes: "");
    result.fold((failure) {
      emit(CreateFolderFaild(error: failure.errorMsg));
    }, (dMaster) async {
      final document = xml.XmlDocument.parse(dMaster.body);
      final resultElement =
          document.findAllElements('IO_Create_FolderResult').first;
      final jsonString = resultElement.innerText;
      debugPrint(jsonString);
      emit(CreateFolderSuccess(folderName:folderName));
      // Decode the JSON string to a list of maps
      // final List<dynamic> decodedJson = jsonDecode(jsonString);
      // final List<Map<String, dynamic>> dataList =
      //     List<Map<String, dynamic>>.from(decodedJson);

      // if (dataList.isNotEmpty) {
      //   driver = dataList;
      //   print("drivers $dataList");
      //   // emit(LoadingDriversSuccessful(drivers));
      // }
    });
    return driver;
  }
}
