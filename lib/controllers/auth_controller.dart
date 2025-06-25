import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/user_model.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();
  
  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'acharadmin';
  
  // Observable variables
  Rxn<User> firebaseUser = Rxn<User>();
  RxBool isLoading = false.obs;
  
  // Text controllers for forms
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  // Form keys
  final signupFormKey = GlobalKey<FormState>();
  final loginFormKey = GlobalKey<FormState>();
  
  @override
  void onInit() {
    super.onInit();
    // Listen to authentication state changes
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _setInitialScreen);
  }
  
  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
  
  // Set initial screen based on authentication state
  _setInitialScreen(User? user) {
    // Add a small delay to ensure proper navigation
    Future.delayed(Duration(milliseconds: 100), () {
      if (user == null) {
        // User is not logged in
        Get.offAllNamed('/login');
      } else {
        // User is logged in
        Get.offAllNamed('/home');
      }
    });
  }
  
  // Sign up with email and password
  Future<void> signUp() async {
    if (!signupFormKey.currentState!.validate()) return;
    
    try {
      isLoading.value = true;
      
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      
      // Update user display name
      await userCredential.user?.updateDisplayName(nameController.text.trim());
      
      // Create admin user document in Firestore
      await _createAdminUserDocument(userCredential.user!);
      
      // Send email verification
      await userCredential.user?.sendEmailVerification();
      
      Get.snackbar(
        'Success',
        'Admin account created successfully! Please check your email for verification.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
      
      // Clear form fields
      _clearControllers();
      
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Error',
        _getErrorMessage(e.code),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Sign in with email and password
  Future<void> signIn() async {
    if (!loginFormKey.currentState!.validate()) return;
    
    try {
      isLoading.value = true;
      
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      
      // Check if user is admin
      bool isAdmin = await isUserAdmin(userCredential.user!.uid);
      
      if (!isAdmin) {
        // Sign out immediately if not admin
        await _auth.signOut();
        Get.snackbar(
          'Access Denied',
          'You do not have admin privileges to access this application.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 4),
        );
        return;
      }
      
      // Update last login for admin
      await _updateAdminLastLogin(userCredential.user!.uid);
      
      Get.snackbar(
        'Success',
        'Welcome back, Admin!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
      );
      
      // Clear form fields
      _clearControllers();
      
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Error',
        _getErrorMessage(e.code),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _clearControllers();
      Get.snackbar(
        'Success',
        'Admin logged out successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error signing out. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    }
  }
  
  // Create admin user document in Firestore
 Future<void> _createAdminUserDocument(User user) async {
  try {
    final userModel = UserModel.fromFirebaseUser(
      user.uid,
      nameController.text.trim(),
      user.email!,
    );
    
    await _firestore.collection(_collectionName).doc(user.uid).set(userModel.toJson());
  } catch (e) {
    print('Error creating admin document: $e');
    throw e;
  }
}
  // Update admin last login
  Future<void> _updateAdminLastLogin(String uid) async {
    try {
      await _firestore.collection(_collectionName).doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }
  
  // Get admin user data
  Future<DocumentSnapshot?> getAdminUserData(String uid) async {
    try {
      return await _firestore.collection(_collectionName).doc(uid).get();
    } catch (e) {
      print('Error getting admin data: $e');
      return null;
    }
  }
  
  // Update admin profile
  Future<void> updateAdminProfile({
    required String uid,
    String? name,
    String? profileImage,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      
      if (name != null && name.isNotEmpty) {
        updateData['name'] = name;
      }
      
      if (profileImage != null && profileImage.isNotEmpty) {
        updateData['profileImage'] = profileImage;
      }
      
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection(_collectionName).doc(uid).update(updateData);
      
      Get.snackbar(
        'Success',
        'Profile updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    }
  }
  
  // Check if user is admin
  Future<bool> isUserAdmin(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collectionName).doc(uid).get();
      return doc.exists && doc.data() != null;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar(
        'Success',
        'Password reset email sent. Please check your inbox.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Error',
        _getErrorMessage(e.code),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    }
  }
  
  // Clear all controllers
  void _clearControllers() {
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    confirmPasswordController.clear();
  }
  
  // Get user-friendly error messages
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
  
  // Email validator
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
  
  // Password validator
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
  
  // Name validator
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }
  
  // Confirm password validator
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }
}