import 'package:flutter/material.dart';

class PasswordForm extends StatefulWidget {
  final TextEditingController controller;

  const PasswordForm({super.key, required this.controller});

  @override
  _PasswordFormState createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _isObscure,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16.0,
      ),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock, color: Colors.orange),
        hintText: 'Enter your password',
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }
}