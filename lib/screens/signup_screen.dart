import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yellow_admin/screens/login_screen.dart';

import '../controllers/auth_controller.dart';
import '../widgets/CustomeForms/email_form.dart';
import '../widgets/CustomeForms/password_form.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthController authController = Get.find<AuthController>();
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: authController.signupFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Logo and Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange[400]!, Colors.orange[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Yellow Achar',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your account',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Name Field
                _buildNameField(),
                const SizedBox(height: 16),
                
                // Email Field - Using your custom EmailForm
                EmailForm(
                  controller: authController.emailController,
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email, color: Colors.orange),
                ),
                const SizedBox(height: 16),
                
                // Password Field - Using your custom PasswordForm
                PasswordForm(
                  controller: authController.passwordController,
                ),
                const SizedBox(height: 16),
                
                // Confirm Password Field
                _buildConfirmPasswordField(),
                const SizedBox(height: 32),
                
                // Sign Up Button
                Obx(() => SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authController.isLoading.value
                        ? null
                        : authController.signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: authController.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                )),
                const SizedBox(height: 24),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.off(() => LoginScreen());
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
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
    );
  }

  // Custom Name Field to match your form style
  Widget _buildNameField() {
    return TextFormField(
      controller: authController.nameController,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16.0,
      ),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.person, color: Colors.orange),
        hintText: 'Enter your full name',
        hintStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
      validator: authController.validateName,
    );
  }

  // Custom Confirm Password Field to match your form style
  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: authController.confirmPasswordController,
      obscureText: _isObscure,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16.0,
      ),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.orange),
        hintText: 'Confirm your password',
        hintStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.orange,
          ),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),
      ),
      validator: authController.validateConfirmPassword,
    );
  }
}