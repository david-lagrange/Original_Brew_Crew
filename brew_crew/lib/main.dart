import 'package:flutter/material.dart';
import 'package:brew_crew/services/authentication_service.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  AuthenticationService authenticationService = AuthenticationService();
  @override
  Widget build(BuildContext context) {
    authenticationService.getData();
    return MaterialApp(
      home: Container(
        child: Text('Home Screen'),
      ),
    );
  }
}

