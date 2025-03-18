import 'package:flutter/material.dart';
import 'features/auth/services/auth_services.dart';
import 'routes/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  AuthService authService = AuthService();
  bool isLoggedIn = await authService.isTokenValid();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    print(isLoggedIn);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Travel AI App',
      theme: ThemeData(fontFamily: 'Roboto', primarySwatch: Colors.blue),
      initialRoute: isLoggedIn ? '/home' : '/login',
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}