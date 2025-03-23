import 'package:flutter/material.dart';
import 'package:lokaloka/core/styles/colors.dart';
import 'package:lokaloka/features/auth/screens/sign_up_screen.dart';
import '../../../widgets/notice_widget.dart';
import '../services/auth_services.dart';

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
  String? _emailError;
  final TextEditingController _passwordController = TextEditingController();
  String? _passwordError;
  bool _obscurePassword = true;
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  String message = "";

  void _showError(BuildContext context, String message) {
    showCustomNotice(context, message, "error");
  }

  void _navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
          (_) => false,
    );
  }

  Future<void> login(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError(context, "Please enter both email and password.");
      return;
    }

    try {
      final result = await _authService.signIn(email, password, currentPath);

      switch (result) {
        case "NO_INTERNET":
          _showError(context, "No internet connection. Please check your network.");
          return;
        case "INVALID_RESPONSE":
          _showError(context, "Server error. Please try again later.");
          return;
        case null:
          setState(() => message = "Invalid email or password.");
          return;
        default:
          _navigateToHome(context);
      }
    } catch (e) {
      _showError(context, "An unexpected error occurred.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key('scaffold_login'),
      body: SafeArea(
        key: Key('safe_area_login'),
        child: Container(
          key: Key('background_container'),
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
              key: Key('column_login'),
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.topRight,
                  child: DropdownButton<String>(
                    key: Key('language_dropdown'),
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
                  key: Key('login_form_container'),
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
                            key: Key('sign_in_text'),
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
                          key: const Key('email_field'),
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: "Enter your email",
                            prefixIcon: const Icon(Icons.email, color: AppColors.orangeColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            errorText: _emailError,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _emailError = null;
                            });
                          },
                          validator: (value) {
                            String trimmedValue = value?.trim() ?? '';

                            if (trimmedValue.isEmpty) {
                              setState(() {
                                _emailError = "Please enter your email.";
                              });
                              return "";
                            }
                            if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                .hasMatch(trimmedValue)) {
                              setState(() {
                                _emailError = "Please enter a valid email address.";
                              });
                              return "";
                            }
                            return null;
                          },
                        ),

                        if (_emailError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 0, left: 10),
                            child: Text(
                              _emailError!,
                              key: const Key("email_error"),
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
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
                          key: const Key('password_field'),
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: "Enter your password",
                            prefixIcon: const Icon(Icons.lock, color: AppColors.orangeColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            errorText: _passwordError,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _passwordError = null;
                            });
                          },
                          validator: (value) {
                            String trimmedValue = value?.trim() ?? '';

                            if (trimmedValue.isEmpty) {
                              setState(() {
                                _passwordError = "Please enter your password.";
                              });
                              return "";
                            }
                            if (trimmedValue.contains(' ')) {
                              setState(() {
                                _passwordError = "Invalid email or password. Please try again.";
                              });
                              return "";
                            }
                            if (message.isNotEmpty) {
                              setState(() {
                                _passwordError = message;
                              });
                              return "";
                            }
                            return null;
                          },
                        ),

                        if (_passwordError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 0, left: 10),
                            child: Text(
                              _passwordError!,
                              key: const Key("password_error"),
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),

                        const SizedBox(height: 15),

                        // SizedBox(
                        //   width: double.infinity,
                        //   child: TextButton(
                        //     key: Key('forgot_password_button'),
                        //     onPressed: () {
                        //       Navigator.push(
                        //         context,
                        //         MaterialPageRoute(
                        //             builder: (context) => ForgotPassword()),
                        //       );
                        //     },
                        //     style: TextButton.styleFrom(
                        //       foregroundColor: Colors.red,
                        //     ),
                        //     child: const Text(
                        //       "Forgot password?",
                        //       style: TextStyle(fontSize: 16),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  key: Key('login_button'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await login(context);
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
                  key: Key('divider_or'),
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
                      key: Key('signup_navigate'),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignUpScreen()),
                        );
                      },
                      child: const Text(
                        key: Key("sign_up_button"),
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
