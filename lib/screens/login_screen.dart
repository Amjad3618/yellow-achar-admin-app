import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:yellow_admin/screens/home_screen.dart';
import '../widgets/CustomeTextAndBtns/custome_elevated_btn.dart';
import '../widgets/CustomeTextAndBtns/custome_text.dart';
import '../widgets/CustomeForms/email_form.dart';
import '../widgets/CustomeForms/password_form.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate login process
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
        Get.to(HomeScreen());
      });

      // Add your login logic here
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login successful!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const CustomText("Login"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
              
                  // Welcome text
                  const CustomText(
                    "Welcome Back!",
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in to your account",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
              
                  const SizedBox(height: 40),
              
                  // Email field
                  EmailForm(
                    controller: _emailController,
                    hintText: "Enter your email",
                    prefixIcon: const Icon(Icons.email, color: Colors.orange),
                  ),
              
                  const SizedBox(height: 20),
              
                  // Password field
                  PasswordForm(controller: _passwordController),
              
                  const SizedBox(height: 16),
              
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Handle forgot password
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ),
              
                  const SizedBox(height: 30),
              
                  // Login button
                 CustomElevatedButton(
                    text: "Login",
                    onPressed: _isLoading ? null : _handleLogin,
                    isLoading: _isLoading,
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                  ),
              
                  const SizedBox(height: 30),
              
                  // Sign up option
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.to(SignupScreen());
                      
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
