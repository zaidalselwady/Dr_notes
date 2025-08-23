import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:http/http.dart' as http;

import '../errors/errors.dart';
import '../utils/api_service.dart';
import 'data_repo.dart';

class DataRepoImpl implements DataRepo {
  ApiService apiService;
  DataRepoImpl(this.apiService);

  @override
  Future<Either<Failure, http.Response>> soapRequest(
      {required String action,
      required String newName,
      required String currentFolder,
      required String filePath,
      required String imageBytes,
      required String sqlStr}) async {
    try {
      var data = await apiService.getSoapRequest(
          action: action,
          //password: "OptimalPass",
          newName: newName,
          currentFolder: currentFolder,
          filePath: filePath,
          imageBytes: imageBytes,
          sqlStr: "");

      return right(data);
    } catch (error) {
      if (error is DioException) {
        return left(ServerFailure.fromDioError(error));
      }
      return left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, http.Response>> fetchWithSoapRequest(
      String action, String sqlStr) async {
    try {
      var data = await apiService.sqlSoapRequest(
          action: action,
          /*password: "OptimalPass_optimaljo05",*/ sqlStr: sqlStr);

      return right(data);
    } catch (error) {
      if (error is DioException) {
        return left(ServerFailure.fromDioError(error));
      }
      return left(ServerFailure(error.toString()));
      //edit erros
    }
  }
}

