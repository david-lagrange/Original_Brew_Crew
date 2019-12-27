import 'dart:convert';
import 'dart:io';

class AuthenticationService {
  //https://192.168.209.147:44303/api/users
  getData() async {
    print('Starting request...');
    HttpClient client = new HttpClient();
    client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    client
        .getUrl(Uri.parse('http://10.0.2.2:5000/api/users')) // produces a request object
        .then((request) => request.close()) // sends the request
        .then((response) =>
        response.transform(Utf8Decoder()).listen(print)); // transforms and prints the response

    print('Request complete.');
  }
}