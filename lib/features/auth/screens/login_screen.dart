import 'package:flutter/material.dart';
import 'package:lokaloka/core/styles/colors.dart';
import 'package:lokaloka/features/auth/screens/sign_up_screen.dart';
import '../../../widgets/notice_widget.dart';
import '../services/auth_services.dart';
import 'forgot_password_screen.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String currentPath = "/login";

  @override
  void initState() {
    super.initState();
  }

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  String message ="";

  Future<void> login(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      return;
    }

    var data = await _authService.signIn(email, password, currentPath);

    if (data == "NO_INTERNET") {
      showCustomNotice(context, "No internet connection. Please check your Wi-Fi or mobile data.", "error");
      return;
    }

    if (data == "INVALID_RESPONSE") {
      showCustomNotice(context, "Server error! Please try again later.", "error");
      return;
    }

    if (data != null) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (Route<dynamic> route) => false);
    } else {
      message = "Invalid email or password. Please try again.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/SC_000_Background.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.topRight,
                  child: DropdownButton<String>(
                    value: "English",
                    icon:
                    const Icon(Icons.arrow_drop_down, color: Colors.white),
                    items: <String>["English", "Vietnamese"]
                        .map((String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: const TextStyle(color: Colors.white)),
                    ))
                        .toList(),
                    onChanged: (String? newValue) {},
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Center(
                          child: Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.orangeColor,
                            ),
                          ),
                        ),
                        const Center(
                          child: Text(
                            "Explore the world! Let’s explore together!",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(children: [
                          const Text("Email ",
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                          Text("*", style: TextStyle(color: Colors.red))
                        ]),
                        const SizedBox(height: 5),
                        TextFormField(
                          key: Key('email_field'),
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: "Enter your email",
                            prefixIcon: const Icon(Icons.email,
                                color: AppColors.orangeColor),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your email.";
                            }
                            if (value.contains(' ')) {
                              return "Please enter your email.";
                            }
                            if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                .hasMatch(value)) {
                              return "Please enter a valid email address.";
                            }
                            if (value.isEmpty) {
                              return "Must contain characters.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        Row(children: [
                          const Text("Password ",
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                          Text("*", style: TextStyle(color: Colors.red))
                        ]),
                        const SizedBox(height: 5),
                        TextFormField(
                          key: Key('password_field'),
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: "Enter your password",
                            prefixIcon: const Icon(Icons.lock,
                                color: AppColors.orangeColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your password.";
                            }
                            if (value.contains(' ')) {
                              return "Invalid email or password. Please try again.";
                            }
                            if(message.isNotEmpty){
                              return message;
                            }
                            if (value.isEmpty) {
                              return "Must contain characters.";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 15),

                        // Forgot Password Button
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            key: Key('forgot_password_button'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ForgotPassword()),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text(
                              "Forgot password?",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  key: Key('login_button'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      login(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangeColor,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 75),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Sign in",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: const [
                    Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("OR"),
                    ),
                    Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  key: Key('google_login_button'),
                  onPressed: () async {
                    final user = await AuthService().signInWithGoogle();
                    if (user != null) {
                      print("Login successful: ${user.displayName}");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("Welcome, ${user.displayName}!")),
                      );
                      Navigator.pushNamed(context, '/home');
                    } else {
                      print("Login failed.");
                    }
                  },
                  icon: Image.asset("assets/images/gg.png", height: 24),
                  label: const Text(
                    "Sign in with Google",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpScreen()),
                        );
                      },
                      child: const Text(
                        "Sign up.",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginResponseScreen extends StatelessWidget {
  final String responseBody;

  const LoginResponseScreen(this.responseBody, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Response")),
      body: Center(
        child: Text(responseBody),
      ),
    );
  }
}