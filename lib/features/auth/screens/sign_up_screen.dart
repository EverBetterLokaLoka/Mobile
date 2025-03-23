import 'package:flutter/material.dart';
import 'package:lokaloka/features/auth/screens/login_screen.dart';
import '../../../core/styles/colors.dart';
import '../../../widgets/notice_widget.dart';
import '../../home/screens/term_of_service.dart';
import '../services/auth_services.dart';

class SignUp extends StatelessWidget {
  const SignUp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: const SignUpScreen(),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  @override
  void initState() {
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  String? _fullNameError;
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;
  final TextEditingController _passwordController = TextEditingController();
  String? _passwordError;
  final TextEditingController _passwordConfirmController = TextEditingController();
  String? _confirmPasswordError;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  late final Map<String, dynamic> responseData;
  String messageReturn = "";

  Future<void> _signUp(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final authService = AuthService();

    String message = await authService.signUp(
      context: context,
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _passwordConfirmController.text,
      onStart: () => setState(() => _isLoading = true),
      onFinish: () => setState(() => _isLoading = false),
    );
    messageReturn = message;
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  _buildSignUpForm(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Sign Up",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.orangeColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            key: const Key('full_name_field'),
            label: "Full Name",
            controller: _fullNameController,
            hintText: "Enter your full name",
            icon: const Icon(Icons.person, color: AppColors.orangeColor),
            errorText: _fullNameError,
            onChanged: (value) {
              setState(() {
                _fullNameError = null; // Xóa lỗi khi nhập
              });
            },
          ),
          _buildEmailField(),
          _buildPasswordField("Password", _passwordController),
          _buildConfirmPasswordField(),
          const SizedBox(height: 20),
          ElevatedButton(
            key: Key('sign_up_button'),
            onPressed: () => _signUp(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orangeColor,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 75),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Sign up",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          _buildSocialLogin(),
          ElevatedButton.icon(
            key: Key('google_sign_up_button'),
            onPressed: () async {
              final user = await AuthService().signInWithGoogle();
              if (user != null) {
                showCustomNotice(context,
                    "Your account has been created successfully.", "confirm");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TermOfService(),
                  ),
                );
              } else {
                print("Sign up fail.");
              }
            },
            icon: Image.asset("assets/images/gg.png", height: 24),
            label: const Text(
              "Sign up with Google",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSignInOption(),
        ],
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
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
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTextField({
    required Key key,
    required String label,
    required TextEditingController controller,
    required String hintText,
    required Icon icon,
    required String? errorText, // Thêm tham số lỗi
    required Function(String?) onChanged, // Hàm xử lý lỗi khi nhập
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text("$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
            const Text("*", style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 5),
        TextFormField(
          key: key,
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: icon,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: onChanged, // Xóa lỗi khi nhập
          validator: (value) {
            String trimmedValue = value?.trim() ?? '';

            if (trimmedValue.isEmpty) {
              setState(() {
                _fullNameError = "Please enter your full name";
              });
              return "";
            }
            if (!RegExp(r'^[a-zA-ZÀ-ỹ\s]+$').hasMatch(trimmedValue)) {
              setState(() {
                _fullNameError = "Only letters and spaces are allowed.";
              });
              return "";
            }
            return null;
          },
        ),

        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 0, left: 10),
            child: Text(
              errorText,
              key: Key("${key}_error"),
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text("Email ", style: TextStyle(fontWeight: FontWeight.bold)),
            const Text("*", style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 5),
        Padding(
          padding: EdgeInsets.all(0),
          child: TextFormField(
            key: const Key('email_field'),
            controller: _emailController,
            decoration: InputDecoration(
              hintText: "Enter your email",
              prefixIcon: const Icon(Icons.email_rounded, color: AppColors.orangeColor),
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
              if (messageReturn.isNotEmpty) {
                setState(() {
                  _emailError = messageReturn.length > 40
                      ? messageReturn.replaceAllMapped(
                      RegExp(r'(.{40})'), (match) => '${match.group(0)}\n')
                      : messageReturn;
                });
                return "";
              }
              return null;
            },
          ),
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
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text(" *", style: TextStyle(color: Colors.red)),
        ]),
        const SizedBox(height: 5),
        TextFormField(
          key: const Key('password_field'),
          controller: controller,
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
            errorText: _passwordError, // Hiển thị lỗi dưới TextField
          ),
          onChanged: (value) {
            setState(() {
              _passwordError = null; // Xóa lỗi khi nhập
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
            if (trimmedValue.length < 8 || trimmedValue.length > 16) {
              setState(() {
                _passwordError = "Password must be between 8 and 16 characters.";
              });
              return "";
            }
            if (trimmedValue.contains(' ')) {
              setState(() {
                _passwordError = "Password cannot contain spaces.";
              });
              return "";
            }
            if (!RegExp(r'[A-Z]').hasMatch(trimmedValue)) {
              setState(() {
                _passwordError = "Password must contain at least one uppercase letter.";
              });
              return "";
            }
            if (!RegExp(r'[a-z]').hasMatch(trimmedValue)) {
              setState(() {
                _passwordError = "Password must contain at least one lowercase letter.";
              });
              return "";
            }
            if (!RegExp(r'[0-9]').hasMatch(trimmedValue)) {
              setState(() {
                _passwordError = "Password must contain at least one numeric digit.";
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
              softWrap: true,
            ),
          ),
      ],
    );
  }


  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          const Text("Confirm Password ", style: TextStyle(fontWeight: FontWeight.bold)),
          const Text("*", style: TextStyle(color: Colors.red)),
        ]),
        const SizedBox(height: 5),
        TextFormField(
          key: const Key('confirm_password_field'),
          controller: _passwordConfirmController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            hintText: "Confirm your password",
            prefixIcon: const Icon(Icons.lock, color: AppColors.orangeColor),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            errorText: _confirmPasswordError, // Hiển thị lỗi dưới TextField
          ),
          onChanged: (value) {
            setState(() {
              _confirmPasswordError = null; // Xóa lỗi khi nhập lại
            });
          },
          validator: (value) {
            String trimmedValue = value?.trim() ?? '';

            if (trimmedValue.isEmpty) {
              setState(() {
                _confirmPasswordError = "Please enter your confirm password.";
              });
              return "";
            }
            if (trimmedValue.contains(" ")) {
              setState(() {
                _confirmPasswordError = "Password cannot contain spaces.";
              });
              return "";
            }
            if (trimmedValue != _passwordController.text) {
              setState(() {
                _confirmPasswordError = "Passwords do not match. Please try again.";
              });
              return "";
            }
            return null;
          },
        ),

        if (_confirmPasswordError != null)
          Padding(
            padding: const EdgeInsets.only(top: 0, left: 10),
            child: Text(
              _confirmPasswordError!,
              key: const Key("confirm_password_error"),
              style: const TextStyle(color: Colors.red, fontSize: 12),
              softWrap: true,
            ),
          ),
      ],
    );
  }

  Widget _buildSignInOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account? "),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Login()),
            );
          },
          child: const Text(
            key: Key("sign_in_button"),
            "Sign in.",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}