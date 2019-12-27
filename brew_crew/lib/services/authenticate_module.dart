import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info/device_info.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticateModule{

  final String _applicationId = "my_application_id";

  final String _storageKeyMobileToken = "token";

  final String _urlBase = "http://10.0.2.2:5000";

  final String _serverApi = "/api/";

  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  String _deviceIdentity = "";

  Future<String> _getDeviceIdentity() async {
    if(_deviceIdentity == ''){
      try{
        if (Platform.isAndroid){
          AndroidDeviceInfo info = await _deviceInfoPlugin.androidInfo;
          _deviceIdentity = '${info.device}-${info.id}';
        }else if (Platform.isIOS){
          IosDeviceInfo info = await _deviceInfoPlugin.iosInfo;
          _deviceIdentity = '${info.model}-${info.identifierForVendor}';
        }
      } on PlatformException {
        _deviceIdentity = 'unkown';
      }
    }
  }

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<String> _getMobileToken() async {
    final SharedPreferences prefs = await _prefs;

    return prefs.getString(_storageKeyMobileToken) ?? '';
  }

  Future<bool> _setMobileToken(String token) async {
    final SharedPreferences prefs = await _prefs;

    return prefs.setString(_storageKeyMobileToken, token);
  }

  Future<String> handShake() async {
    String _status = "ERROR";

    return ajaxGet("handshake").then((String responseBody) async {
      Map response = json.decode(responseBody);
      _status = response['status'];
      switch (_status) {
        case 'REQUIRES_AUTHENTICATION':
          await _setMobileToken(response['data']);
          break;

        case 'INVALID':
          await _setMobileToken('');
          break;
      }
      return _status;
    }).catchError(() {
      return 'ERROR';
    });
  }

  Future<String> ajaxGet(String serviceName) async {
    var responseBody = '{"data": "", "status": "NOK"}';
    try{
      var response = await http.get(_urlBase + '/$_serverApi$serviceName',
          headers: {
            'X-DEVICE-ID': await _getDeviceIdentity(),
            'X-TOKEN': await _getMobileToken(),
            'X-APP-ID': _applicationId
          });

      if (response.statusCode == 200) {
        responseBody = response.body;
      }
    } catch(e){
      throw new Exception('AJAX ERROR');
    }
    return responseBody;

  }

  Future<Map> ajaxPost(String serviceName, Map data) async {
    var responseBody = json.decode('{"data": "", "status": "NOK"}');
    try {
      var response = await http.post(_urlBase + '/$_serverApi$serviceName',
          body: json.encode(data),
          headers: {
            'X-DEVICE-ID': await _getDeviceIdentity(),
            'X-TOKEN': await _getMobileToken(),
            'X-APP-ID': _applicationId,
            'Content-Type': 'application/json; charset=utf-8'
          });
      if (response.statusCode == 200) {
        responseBody = json.decode(response.body);

        //
        // If we receive a new token, let's save it
        //
        if (responseBody["status"] == "TOKEN") {
          await _setMobileToken(responseBody["data"]);

          // TODO: rerun the Post request
        }
      }
    } catch (e) {
      // An error was received
      throw new Exception("AJAX ERROR");
    }
    return responseBody;
  }
}