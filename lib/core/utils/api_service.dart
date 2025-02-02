import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final baseUrl = 'http://10.100.3.254:5000/';

  final Dio dio;
  ApiService(this.dio);
  static const config = {
    'Driver': '{ODBC Driver 17 for SQL Server}',
    'user': 'messam',
    'password': 'Hello12@',
    'server': '108.181.191.132',
    'database': 'optimaljo'
  };

  Future<http.Response> getSoapRequest(
      {required String action,
      required String password,
      required String newName,
      required String currentFolder,
      required String filePath,
      required String imageBytes,
      required String sqlStr}) async {
    final url = Uri.parse('https://www.optimaljo.com/freshuploader.asmx');
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
      <password>$password</password>
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
      required String password,
      required String sqlStr}) async {
    final url = Uri.parse('http://www.optimaljo.com/freshuploader.asmx');
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
      <password>$password</password>
      <SQlStr>$sqlStr</SQlStr>
    </$action>
  </soap:Body>
</soap:Envelope>
''';
    final response = await http.post(url, headers: headers, body: body);
    return response;
  }

}
