import 'package:flutter/material.dart';
import 'features/auth/screens/auth-wrapper.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/services/auth_services.dart';
import 'routes/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Travel AI App',
      theme: ThemeData(fontFamily: 'Roboto', primarySwatch: Colors.blue),
      home: AuthWrapper(),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
