import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import '../../canvas_screen/data/proc_model.dart';
import '../../core/repos/data_repo.dart';

part 'get_proc_state.dart';

class GetProcCubit extends Cubit<GetProcState> {
  GetProcCubit(this.dataRepo) : super(GetProcInitial());
  final DataRepo dataRepo;

  Future<void> fetchPatientsWithSoapRequest(String sqlStr) async {
    emit(GettingProc());
    var result = await dataRepo.fetchWithSoapRequest(
        "getJson_select", sqlStr);
    result.fold((failure) {
      emit(
        GetProcFailed(
          error: failure.errorMsg,
        ),
      );
    }, (dMaster) async {
      final document = xml.XmlDocument.parse(dMaster.body);

      final elements = document.findAllElements('getJson_selectResult');

// Check if the elements list is not empty before accessing the first element
      if (elements.isNotEmpty) {
        final resultElement = elements.first;
        final jsonString = resultElement.innerText;
        // Decode the JSON string to a list of maps
        if (jsonDecode(jsonString) is List) {
          final List<dynamic> decodedJson = jsonDecode(jsonString);
          final List<Procedures> procList = decodedJson
              .map((json) => Procedures.fromJson(json as Map<String, dynamic>))
              .toList();

          if (procList.isNotEmpty) {
            emit(GetProcSuccess(proc: procList));
          } else {
            emit(
              GetProcSuccess(
                proc: const [],
              ),
            );
          }
        } else {
          int result = int.parse(jsonString);
          if (result > 0) {
          } else {}
        }
      } else {
        emit(
          GetProcFailed(
            error: 'No data found',
          ),
        );
      }
    });
  }
}


