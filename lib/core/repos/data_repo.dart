import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;

import '../errors/errors.dart';

abstract class DataRepo {
  Future<Either<Failure, http.Response>> soapRequest(
      {int? isSignature,
      required String action,
      required String newName,
      required String currentFolder,
      required String filePath,
      required String imageBytes,
      required String sqlStr});
  Future<Either<Failure, http.Response>> fetchWithSoapRequest(
      String action, String sqlStr);
}
