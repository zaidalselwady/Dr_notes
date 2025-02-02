import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'get_folders_state.dart';

class GetFoldersCubit extends Cubit<GetFoldersState> {
  GetFoldersCubit() : super(GetFoldersInitial());
  // Future<List<dynamic>> getFolders(String folderName) async {
  //   var result = await widget.dataRepo.fetchWithSoapRequest(
  //       action: "IO_get_Folder_Files",
  //       newName: folderName,
  //       currentFolder: "p6",
  //       filePath: "",
  //       imageBytes: "");
  //   result.fold((failure) {
  //     print(failure.errorMsg);
  //   }, (dMaster) async {
  //     final document = xml.XmlDocument.parse(dMaster.body);
  //     final resultElement =
  //         document.findAllElements('IO_get_Folder_FilesResult').first;
  //     final jsonString = resultElement.innerText;
  //     print(jsonString);
  //     // final List<dynamic> decodedJson = jsonDecode(jsonString);
  //     // final List<Map<String, dynamic>> dataList =
  //     //     List<Map<String, dynamic>>.from(decodedJson);

  //     // if (dataList.isNotEmpty) {
  //     //   driver = dataList;
  //     //   print("drivers $dataList");
  //     //   // emit(LoadingDriversSuccessful(drivers));
  //     // }
  //   });
  //   return driver;
  // }
}
