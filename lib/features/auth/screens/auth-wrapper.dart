import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../home/screens/home_screen.dart';
import '../services/auth_services.dart';
import 'login_screen.dart';

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Future<bool> checkLoginStatus() async {
    AuthService authService = AuthService();
    return await authService.isTokenValid();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data == true) {
          return HomeScreen();
        } else {
          return Login();
        }
      },
    );
  }
}
