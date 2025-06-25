import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  String id;
  String name;
  String description;
  String? parentId; // For subcategories
  String imageUrl;
  String iconUrl;
  bool isActive;
  bool isFeatured;
  int sortOrder;
  DateTime createdAt;
  DateTime updatedAt;
  String adminId; // ID of admin who created/updated the category
  Map<String, dynamic> metadata; // Additional category-specific data
  String slug; // URL-friendly version of name
  List<String> tags;
  String status; // draft, published, archived
  int productCount; // Number of products in this category

  CategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.parentId,
    this.imageUrl = '',
    this.iconUrl = '',
    this.isActive = true,
    this.isFeatured = false,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.adminId,
    this.metadata = const {},
    this.slug = '',
    this.tags = const [],
    this.status = 'draft',
    this.productCount = 0,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Method to convert CategoryModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parentId': parentId,
      'imageUrl': imageUrl,
      'iconUrl': iconUrl,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'adminId': adminId,
      'metadata': metadata,
      'slug': slug,
      'tags': tags,
      'status': status,
      'productCount': productCount,
    };
  }

  // Method to create CategoryModel from Firestore JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      parentId: json['parentId'],
      imageUrl: json['imageUrl'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      isActive: json['isActive'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      adminId: json['adminId'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      slug: json['slug'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      status: json['status'] ?? 'draft',
      productCount: json['productCount'] ?? 0,
    );
  }

  // Factory constructor for creating a new category
  factory CategoryModel.create({
    required String name,
    required String adminId,
    String? description,
    String? parentId,
    String? imageUrl,
    String? iconUrl,
    int? sortOrder,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) {
    return CategoryModel(
      id: '', // Will be set when saved to Firestore
      name: name,
      description: description ?? '',
      parentId: parentId,
      imageUrl: imageUrl ?? '',
      iconUrl: iconUrl ?? '',
      sortOrder: sortOrder ?? 0,
      adminId: adminId,
      metadata: metadata ?? {},
      slug: _generateSlug(name),
      tags: tags ?? [],
    );
  }

  // Method to update category data
  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? parentId,
    String? imageUrl,
    String? iconUrl,
    bool? isActive,
    bool? isFeatured,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminId,
    Map<String, dynamic>? metadata,
    String? slug,
    List<String>? tags,
    String? status,
    int? productCount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      imageUrl: imageUrl ?? this.imageUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(), // Always update the timestamp
      adminId: adminId ?? this.adminId,
      metadata: metadata ?? this.metadata,
      slug: slug ?? this.slug,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      productCount: productCount ?? this.productCount,
    );
  }

  // Helper methods
  bool get isSubCategory => parentId != null && parentId!.isNotEmpty;
  
  bool get isMainCategory => parentId == null || parentId!.isEmpty;
  
  bool get hasProducts => productCount > 0;
  
  bool get isEmpty => productCount == 0;

  // Method to generate URL-friendly slug from name
  static String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), '-') // Replace spaces with hyphens
        .replaceAll(RegExp(r'-+'), '-') // Replace multiple hyphens with single
        .replaceAll(RegExp(r'^-|-$'), ''); // Remove leading/trailing hyphens
  }

  // Method to update slug based on current name
  CategoryModel updateSlug() {
    return copyWith(slug: _generateSlug(name), updatedAt: DateTime.now());
  }

  // Method to add/remove from featured
  CategoryModel toggleFeatured() {
    return copyWith(isFeatured: !isFeatured, updatedAt: DateTime.now());
  }

  // Method to activate/deactivate category
  CategoryModel toggleActive() {
    return copyWith(isActive: !isActive, updatedAt: DateTime.now());
  }

  // Method to update product count
  CategoryModel updateProductCount(int newCount) {
    return copyWith(productCount: newCount, updatedAt: DateTime.now());
  }

  // Method to increment product count
  CategoryModel incrementProductCount() {
    return copyWith(productCount: productCount + 1, updatedAt: DateTime.now());
  }

  // Method to decrement product count
  CategoryModel decrementProductCount() {
    return copyWith(
      productCount: productCount > 0 ? productCount - 1 : 0, 
      updatedAt: DateTime.now()
    );
  }

  // Method to publish category
  CategoryModel publish() {
    return copyWith(status: 'published', isActive: true, updatedAt: DateTime.now());
  }

  // Method to archive category
  CategoryModel archive() {
    return copyWith(status: 'archived', isActive: false, updatedAt: DateTime.now());
  }

  // Method to move category (change parent)
  CategoryModel moveTo(String? newParentId) {
    return copyWith(parentId: newParentId, updatedAt: DateTime.now());
  }

  // Method to update sort order
  CategoryModel updateSortOrder(int newOrder) {
    return copyWith(sortOrder: newOrder, updatedAt: DateTime.now());
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, parentId: $parentId, isActive: $isActive, productCount: $productCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}