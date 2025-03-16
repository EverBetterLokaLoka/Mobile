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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
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
              "Full Name",
              _fullNameController,
              "Enter your fullname",
              Icon(Icons.perm_identity_rounded, color: AppColors.orangeColor)),
          _buildEmailField(),
          _buildPasswordField("Password", _passwordController),
          _buildConfirmPasswordField(),
          const SizedBox(height: 20),
          ElevatedButton(
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

  Widget _buildTextField(String label, TextEditingController controller,
      String hintText, Icon icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text("$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("*", style: TextStyle(color: Colors.red))
        ]),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: icon,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter your full name";
            }
            if (value.contains(" ")) {
              return "Please enter your full name.";
            }
            if (!RegExp(r'^[a-zA-ZÀ-ỹ]+$').hasMatch(value)) {
              return "Only letters are allowed.";
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text("Email ", style: TextStyle(fontWeight: FontWeight.bold)),
          Text("*", style: TextStyle(color: Colors.red))
        ]),
        const SizedBox(height: 5),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: "Enter your email",
            prefixIcon:
                const Icon(Icons.email_rounded, color: AppColors.orangeColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter your email.";
            }
            if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                .hasMatch(value)) {
              return "Please enter a valid email address.";
            }
            if (messageReturn.isNotEmpty) {
              return messageReturn.length > 40
                  ? messageReturn.replaceAllMapped(
                      RegExp(r'(.{40})'), (match) => '${match.group(0)}\n')
                  : messageReturn;
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            " *",
            style: TextStyle(color: Colors.red),
          )
        ]),
        const SizedBox(height: 5),
        TextFormField(
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
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter your $label";
            }
            if (value.length < 8 || value.length > 16) {
              return "Password must be between 8 \nand 16 characters.";
            }
            if (value.contains(' ')) {
              return "Please enter your password.";
            }
            if (!RegExp(r'[A-Z]').hasMatch(value)) {
              return "Password must contain at least one uppercase letter.";
            }
            if (!RegExp(r'[a-z]').hasMatch(value)) {
              return "Password must contain at least one lowercase letter.";
            }
            if (!RegExp(r'[0-9]').hasMatch(value)) {
              return "Password must contain at least one numeric digit.";
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text("Confirm Password ",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            "*",
            style: TextStyle(color: Colors.red),
          )
        ]),
        const SizedBox(height: 5),
        TextFormField(
          controller: _passwordConfirmController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            hintText: "Confirm your password",
            prefixIcon: const Icon(Icons.lock, color: AppColors.orangeColor),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter your confirm password.";
            } else if (value.contains(" ")) {
              return "Please enter your confirm password.";
            } else if (value.isEmpty) {
              return "Must contain characters.";
            } else if (value != _passwordController.text) {
              return "Passwords do not match. Please try again.";
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
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
