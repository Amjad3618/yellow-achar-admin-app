import 'package:flutter/material.dart';

class EmailForm extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Icon prefixIcon;

  const EmailForm({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16.0,
      ),
      decoration: InputDecoration(
        prefixIcon: prefixIcon,
        hintText: hintText,
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Enter a valid email address';
        }
        return null;
      },
    );
  }
}