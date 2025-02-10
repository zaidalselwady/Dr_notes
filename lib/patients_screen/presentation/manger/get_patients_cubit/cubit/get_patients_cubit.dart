import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:hand_write_notes/information_screen/data/child_info_model.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;
import '../../../../../core/repos/data_repo.dart';

part 'get_patients_state.dart';

class GetPatientsCubit extends Cubit<GetPatientsState> {
  GetPatientsCubit(this.dataRepo) : super(GetPatientsInitial());
  final DataRepo dataRepo;
  List<PatientInfo> patientsCopy = [];
  Future<void> fetchPatientsWithSoapRequest(String sqlStr) async {
    emit(GettingPatients());
    var result = await dataRepo.fetchWithSoapRequest("getJson_select", sqlStr);
    result.fold((failure) {
      emit(
        GetPatientsFaild(
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
          final List<PatientInfo> childInfoList = decodedJson
              .map((json) => PatientInfo.fromJson(json as Map<String, dynamic>))
              .toList();

          if (childInfoList.isNotEmpty) {
            patientsCopy = filteresdPatientsList = childInfoList;
            emit(GetPatientsSuccess(patients: childInfoList));
          } else {
            emit(GetPatientsSuccess(patients: const []));
          }
        } else {
          int result = int.parse(jsonString);
          if (result > 0) {
          } else {}
        }
      } else {
        emit(
          GetPatientsSuccess(
            patients: const [],
          ),
        );
      }
    });
  }

  List<PatientInfo> filteresdPatientsList = [];
  void filtering(String enteredKeyword, List<PatientInfo> patients) {
    List<PatientInfo> results = [];
    if (enteredKeyword.isEmpty) {
      emit(GettingPatients());
      results = patients;
      filteresdPatientsList = results;
      emit(
        GetPatientsSuccess(patients: filteresdPatientsList),
      );
    } else if (RegExp(r"^[a-zA-Z\u0600-\u06FF\s]+$").hasMatch(enteredKeyword)) {
      emit(GettingPatients());
      results = patients.where((user) {
        String name = user.name.toLowerCase();
        String firstName = user.firstName.toLowerCase();
        String middleName = user.midName.toLowerCase();
        String lastName = user.lastName.toLowerCase();

        return name.contains(enteredKeyword.toLowerCase().trim()) ||
            firstName.contains(enteredKeyword.toLowerCase().trim()) ||
            middleName.contains(enteredKeyword.toLowerCase().trim()) ||
            lastName.contains(enteredKeyword.toLowerCase().trim());
      }).toList();
      filteresdPatientsList = results;
      emit(
        GetPatientsSuccess(patients: filteresdPatientsList),
      );
    } else {
      emit(GettingPatients());
      results = patients
          .where(
            (user) => user.phone.contains(
              enteredKeyword,
            ),
          )
          .toList();
      filteresdPatientsList = results;
      emit(
        GetPatientsSuccess(patients: filteresdPatientsList),
      );
    }
  }

  // void filtering(String enteredKeyword, List<PatientInfo> allPatients) {
  //   emit(GettingPatients());
  //   List<PatientInfo> results = [];
  //   if (enteredKeyword.isEmpty) {
  //     results = allPatients;
  //     filteresdPatientsList = results;
  //   } else if (RegExp(r"^[a-zA-Z\u0600-\u06FF\s]+$").hasMatch(enteredKeyword)) {
  //     results = allPatients
  //         .where((user) => user.name.toLowerCase().contains(
  //               enteredKeyword.toLowerCase().trim(),
  //             ))
  //         .toList();
  //     filteresdPatientsList = results;
  //   } else {
  //     results = allPatients
  //         .where((user) => user.phone.contains(enteredKeyword))
  //         .toList();
  //     filteresdPatientsList = results;
  //   }
  //   emit(GetPatientsSuccess(patients: filteresdPatientsList));
  // }
}
