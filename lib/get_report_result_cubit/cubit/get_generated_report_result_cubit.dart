import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import '../../core/repos/data_repo.dart';

part 'get_generated_report_result_state.dart';

class GetGeneratedReportResultCubit
    extends Cubit<GetGeneratedReportResultState> {
  GetGeneratedReportResultCubit(this.dataRepo)
      : super(GetGeneratedReportResultInitial());
  final DataRepo dataRepo;
  Future<void> fetchPatientsWithSoapRequest(String sqlStr) async {
    emit(GettingGeneratedReportResult());
    var result = await dataRepo.fetchWithSoapRequest("getJson_select", sqlStr);
    result.fold((failure) {
      emit(
        GetGeneratedReportResultFailed(
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
          final List<Map<String, dynamic>> dataList =
              List<Map<String, dynamic>>.from(decodedJson);

          if (dataList.isNotEmpty) {
            emit(GetGeneratedReportResultSuccess(
                generatedReportScreen: dataList));
          } else {
            emit(
              GetGeneratedReportResultSuccess(
                generatedReportScreen: const [],
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
          GetGeneratedReportResultSuccess(
            generatedReportScreen: const [],
          ),
        );
      }
    });
  }
}
