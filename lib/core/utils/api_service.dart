import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final envBaseUrl = dotenv.env['BASE_URL'];
  final envPass05 = dotenv.env['PASS05'];
  final envPass = dotenv.env['PASS'];
  final Dio dio;
  ApiService(this.dio);

  Future<http.Response> getSoapRequest(
      {required String action,
      //required String password,
      required String newName,
      required String currentFolder,
      required String filePath,
      required String imageBytes,
      required String sqlStr}) async {
    final url = Uri.parse(envBaseUrl!);
    final soapAction = 'http://tempuri.org/$action';
    final headers = {
      'Content-Type': 'text/xml; charset=utf-8',
      'SOAPAction': soapAction,
    };

    final body = '''
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <$action xmlns="http://tempuri.org/">
      <password>$envPass</password>
      <CurrentFolder>$currentFolder</CurrentFolder>
      <NewFolder>$newName</NewFolder>
      <FilePath>$filePath</FilePath>
      <image_Base64String>$imageBytes</image_Base64String>
      <SQlStr>$sqlStr</SQlStr>
    </$action>
  </soap:Body>
</soap:Envelope>
''';
    final response = await http.post(url, headers: headers, body: body);
    return response;
  }

  Future<http.Response> sqlSoapRequest(
      {required String action,
      //required String password,
      required String sqlStr}) async {
    final url = Uri.parse(envBaseUrl!);
    final soapAction = 'http://tempuri.org/$action';
    final headers = {
      'Content-Type': 'text/xml; charset=utf-8',
      'SOAPAction': soapAction,
    };

    final body = '''
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <$action xmlns="http://tempuri.org/">
      <password>$envPass05</password>
      <SQlStr>$sqlStr</SQlStr>
    </$action>
  </soap:Body>
</soap:Envelope>
''';
    final response = await http.post(url, headers: headers, body: body);
    return response;
  }
}
