// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/repos/data_repo.dart';
import '../../../data/user_model.dart';
part 'login_cubit_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this.dataRepo) : super(GetUsersInitial());

  final DataRepo dataRepo;

  List<Map<String, dynamic>> driver = [];
  Future<void> fetchUsersWithSoapRequest(
      String userName, String password) async {
    emit(GettingUsers());
    var result = await dataRepo.fetchWithSoapRequest("getJson_select",
        "SELECT * FROM Patients_Users WHERE User_Name	= '$userName' AND Password='$password' ");
    result.fold((failure) {
      emit(GetUsersFailed(failure.errorMsg));
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
          final List<User> userList = decodedJson
              .map((json) => User.fromJson(json as Map<String, dynamic>))
              .toList();

          if (userList.isNotEmpty) {
            emit(GetUsersSuccess(user: userList[0]));
          } else {
            emit(GetUsersFailed("Wrong User Name or Password"));
          }
        } else {
          int result = int.parse(jsonString);
          if (result > 0) {
            emit(GetUsersFailed("Wrong User Name or Password"));
          } else {
            emit(GetUsersFailed("Error"));
          }
        }
      } else {
        emit(GetUsersFailed("Wrong User Name or Password"));
      }
    });
  }
}
