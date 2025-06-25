import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String name;
  String email;
  String role;
  bool isActive;
  DateTime? createdAt;
  DateTime? lastLogin;
  DateTime? updatedAt;
  String profileImage;
  Map<String, bool> permissions;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'admin',
    this.isActive = true,
    this.createdAt,
    this.lastLogin,
    this.updatedAt,
    this.profileImage = '',
    Map<String, bool>? permissions,
  }) : permissions = permissions ?? {
    'canManageProducts': true,
    'canManageOrders': true,
    'canManageUsers': true,
    'canViewAnalytics': true,
  };

  // Method to convert UserModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'profileImage': profileImage,
      'permissions': permissions,
    };
  }

  // Method to create UserModel from Firestore JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'admin',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate() 
          : null,
      lastLogin: json['lastLogin'] != null 
          ? (json['lastLogin'] as Timestamp).toDate() 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] as Timestamp).toDate() 
          : null,
      profileImage: json['profileImage'] ?? '',
      permissions: Map<String, bool>.from(json['permissions'] ?? {}),
    );
  }

  // Method to create UserModel from Firebase Auth User
  factory UserModel.fromFirebaseUser(String uid, String name, String email) {
    return UserModel(
      uid: uid,
      name: name,
      email: email,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );
  }

  // Method to update user data
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? updatedAt,
    String? profileImage,
    Map<String, bool>? permissions,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImage: profileImage ?? this.profileImage,
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, role: $role, isActive: $isActive)';
  }
}