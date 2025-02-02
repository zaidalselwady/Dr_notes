import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:hand_write_notes/search_fields_model.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import '../../core/repos/data_repo.dart';

part 'reporting_state.dart';

class GetSearchFields extends Cubit<GetSearchFieldsState> {
  GetSearchFields(this.dataRepo) : super(ReportingInitial());
  final DataRepo dataRepo;
  Future<void> fetchPatientsWithSoapRequest(String sqlStr) async {
    emit(GettingSearchFields());
    var result = await dataRepo.fetchWithSoapRequest("getJson_select", sqlStr);
    result.fold((failure) {
      emit(
        GetSearchFieldsFailed(
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
          // final List<ChildInfo> decodedJson = jsonDecode(jsonString);
          // final List<ChildInfo> dataList = List<ChildInfo>.from(decodedJson);

          final List<dynamic> decodedJson = jsonDecode(jsonString);
          final List<FieldInfo> childInfoList = decodedJson
              .map((json) => FieldInfo.fromJson(json as Map<String, dynamic>))
              .toList();

          if (childInfoList.isNotEmpty) {
            emit(GetSearchFieldsSuccess(searchFields: childInfoList));
          }
        } else {
          int result = int.parse(jsonString);
          if (result > 0) {
          } else {}
        }
      } else {
        emit(
          GetSearchFieldsSuccess(
            searchFields: const [],
          ),
        );
      }
    });
  }
}




// "SELECT Name, dbo.getProcedureDesc(Procedure_id) as  Prodcedure, Count(*) as NoVisits, Visit_Date, dbo.getProcedureStatusDesc(Procedure_Status) as  Prodcedure_Status, Notes FROM Patients_Visits WHERE Visit_Date BETWEEN '2025-01-01' AND '2025-01-25' AND Procedure_id IN (2, 3) AND Procedure_Status IN (1, 2)"

// SELECT Name, dbo.getProcedureDesc(Procedure_id) as  Prodcedure, Count(*) as NoVisits, Visit_Date, dbo.getProcedureStatusDesc(Procedure_Status) as  Prodcedure_Status, Notes FROM Patients_Visits WHERE Visit_Date BETWEEN '2025-01-01' AND '2025-01-25'