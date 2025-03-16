import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/url_constant.dart';
import '../../../core/utils/apis.dart';
import '../../../widgets/notice_widget.dart';
import '../../home/screens/term_of_service.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ApiService _apiService = ApiService();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      print(userCredential);
      return userCredential.user;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  // Future<void> signUp({
  //   required BuildContext context,
  //   required String fullName,
  //   required String email,
  //   required String password,
  //   required String confirmPassword,
  //   required VoidCallback onStart,
  //   required VoidCallback onFinish,
  // }) async {
  //   onStart();
  //
  //   final data = {
  //     'full_name': fullName.trim(),
  //     'email': email.trim(),
  //     'password': password.trim(),
  //     'confirm_password': confirmPassword.trim(),
  //   };
  //
  //   try {
  //     final response = await _apiService.request(
  //       path: '/auth/register',
  //       method: 'POST',
  //       typeUrl: UrlConstant().baseUrl,
  //       currentPath: '/sign-up',
  //       data: data,
  //     );
  //
  //     if (response.statusCode == 201) {
  //       final responseData = jsonDecode(response.body);
  //       String? token = responseData["token"];
  //
  //       if (token == null) {
  //         throw Exception("Token is null. Please try again.");
  //       }
  //
  //       saveToken(token);
  //       showCustomNotice(context, 'Your account has been created successfully.', 'confirm');
  //
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (context) => TermOfService()),
  //       );
  //     } else {
  //       // Nếu phản hồi không thành công, phân tích phản hồi lỗi
  //       final responseData = jsonDecode(response.body);
  //       String errorMessage = responseData["message"] ?? "An unknown error occurred.";
  //
  //       // Xử lý riêng cho mã trạng thái 409
  //       if (response.statusCode == 409) {
  //         errorMessage = responseData["message"] ?? "This email is already in use. Please use a different email or log in.";
  //       }
  //
  //       showCustomNotice(context, errorMessage, "notice");
  //     }
  //   } on SocketException {
  //     showCustomNotice(
  //         context,
  //         "No internet connection. Please turn on Wi-Fi or mobile data.",
  //         "error");
  //   } on FormatException {
  //     showCustomNotice(
  //         context,
  //         "Server returned an invalid response. Please try again later.",
  //         "error");
  //   } catch (e) {
  //     // Cần kiểm tra xem e có phải là đối tượng Exception không
  //     String errorMessage = "An unexpected error occurred.";
  //     if (e is Exception) {
  //       errorMessage = e.toString();
  //     }
  //     showCustomNotice(context, errorMessage, "error");
  //   } finally {
  //     onFinish();
  //   }
  // }
  Future<void> signUp({
    required BuildContext context,
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required VoidCallback onStart,
    required VoidCallback onFinish,
  }) async {
    onStart();

    final data = {
      'full_name': fullName.trim(),
      'email': email.trim(),
      'password': password.trim(),
      'confirm_password': confirmPassword.trim(),
    };

    // Gọi API mà không cần xử lý ngoại lệ tại đây
    final response = await _apiService.request(
      path: '/auth/register',
      method: 'POST',
      typeUrl: UrlConstant().baseUrl,
      currentPath: '/sign-up',
      data: data,
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      String? token = responseData["token"];

      if (token == null) {
        throw Exception("Token is null. Please try again.");
      }

      saveToken(token);
      showCustomNotice(context, 'Your account has been created successfully.', 'confirm');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TermOfService()),
      );
    } else {
      // Phân tích mã trạng thái 409 hoặc những mã lỗi khác
      final responseData = jsonDecode(response.body);
      String errorMessage = responseData["message"] ?? "An unknown error occurred.";

      if (response.statusCode == 409) {
        errorMessage = "An account already exists with the same email address.";
      }

      showCustomNotice(context, errorMessage, "error");
    }

    onFinish(); // Sau khi hoàn thành
  }

  Future<dynamic> signIn(
      String email, String password, String currentPath) async {
    try {
      final response = await _apiService.request(
        path: '/auth/login',
        method: 'POST',
        typeUrl: UrlConstant().baseUrl,
        currentPath: currentPath,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.body.isEmpty) {
        return null;
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      String? token = responseData["token"];
      if (token == null) {
        print("Token is null");
        return null;
      }

      await saveToken(token);

      if (responseData.containsKey('data')) {
        return UserNormal.fromJson(responseData['data']);
      }
      return null;
    } on SocketException catch (_) {
      return "NO_INTERNET";
    } on FormatException catch (_) {
      return "INVALID_RESPONSE";
    } catch (e) {
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    await prefs.setString("auth_token", token);
    await prefs.setInt("token_saved_time", currentTime);
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");
    int? savedTime = prefs.getInt("token_saved_time");

    if (token == null || savedTime == null) {
      print("No token found!");
      return null;
    }

    print("Retrieved token: $token");

    int currentTime = DateTime.now().millisecondsSinceEpoch;
    int elapsedTime = (currentTime - savedTime) ~/ 1000;

    if (elapsedTime > 1500) {
      print("Token expired! Removing...");
      await prefs.remove("auth_token");
      await prefs.remove("token_saved_time");
      return null;
    }

    print("Token is valid!");
    return token;
  }

  Future<bool> isTokenValid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");
    int? savedTime = prefs.getInt("token_saved_time");

    if (token == null || savedTime == null) {
      print("No token found!");
      return false;
    }

    int currentTime = DateTime.now().millisecondsSinceEpoch;
    int elapsedTime = (currentTime - savedTime) ~/ 1000;

    if (elapsedTime > 1500) {
      print("Token expired! User needs to log in again.");
      await prefs.remove("auth_token");
      await prefs.remove("token_saved_time");
      return false;
    }

    return true;
  }

  Future<void> checkTokenAndProceed(BuildContext context) async {
    String? currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute == "/login") {
      return;
    }

    bool valid = await isTokenValid();
    if (!valid) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      print("Token is still valid!");
    }
  }

  // Add a new method to save the username in SharedPreferences
  Future<void> saveUserName(String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_name", username);
  }

// Modify getUserNameFromToken to save the username
  Future<String?> getUserNameFromToken(BuildContext context) async {
    try {
      String? token = await getToken();
      if (token == null) {
        print("No token found!");
        Navigator.pushNamed(context, '/login');
        return null;
      }

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      if (decodedToken.containsKey('name')) {
        String userName = decodedToken['name'];
        // Save the username
        await saveUserName(userName);
        return userName;
      } else {
        print("Token doesn't contain a username!");
        return null;
      }
    } catch (e) {
      print("Error decoding token: $e");
      return null;
    }
  }

  // Method to get username from SharedPreferences
  Future<String?> getUserNameFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_name");
  }
}
