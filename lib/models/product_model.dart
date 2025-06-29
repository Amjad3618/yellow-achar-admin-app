import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  String id;
  String name;
  String description;
  double price;
  double? discountPrice;
  int stock;
  String category;
  String categoryname;

  List<String> images;
  bool isActive;
  bool isFeatured;
  bool isOnSale;
  DateTime createdAt;
  DateTime updatedAt;
  String adminId; // ID of admin who created/updated the product
  Map<String, dynamic> specifications;
  double rating;
  int reviewCount;
  String sku; // Stock Keeping Unit
  String status; // draft, published, archived

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.stock,
    required this.category,
    required this.categoryname,
    
    this.images = const [],
  
    this.isActive = true,
    this.isFeatured = false,
    this.isOnSale = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.adminId,
    this.specifications = const {},
    this.rating = 0.0,
    this.reviewCount = 0,
    this.sku = '',
   
    Map<String, String>? dimensions,
    this.status = 'draft',
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Method to convert ProductModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'stock': stock,
      'category': category,
      'categoryname': categoryname,
      
     
      'images': images,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isOnSale': isOnSale,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'adminId': adminId,
      'specifications': specifications,
      'rating': rating,
      'reviewCount': reviewCount,
      'sku': sku,
      'status': status,
    };
  }

  // Method to create ProductModel from Firestore JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discountPrice']?.toDouble(),
      stock: json['stock'] ?? 0,
      category: json['category'] ?? '',
      categoryname: json['categoryname'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      isActive: json['isActive'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      isOnSale: json['isOnSale'] ?? false,
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      adminId: json['adminId'] ?? '',
      specifications: Map<String, dynamic>.from(json['specifications'] ?? {}),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      sku: json['sku'] ?? '',
      dimensions: Map<String, String>.from(json['dimensions'] ?? 
          {'height': '0', 'width': '0', 'length': '0'}),
      status: json['status'] ?? 'draft',
    );
  }

  // Factory constructor for creating a new product
  factory ProductModel.create({
    required String name,
    required String description,
    required double price,
    required int stock,
    required String category,
    required String categoryname,
    required String adminId,
    double? discountPrice,
    String? subCategory,
    String? brand,
    List<String>? images,
    List<String>? tags,
    Map<String, dynamic>? specifications,
    String? sku,
    double? weight,
    Map<String, String>? dimensions,
  }) {
    return ProductModel(
      id: '', // Will be set when saved to Firestore
      name: name,
      description: description,
      price: price,
      discountPrice: discountPrice,
      stock: stock,
      category: category,
      categoryname: categoryname,
      
      images: images ?? [],
     
      adminId: adminId,
      specifications: specifications ?? {},
      sku: sku ?? '',
    
      dimensions: dimensions ?? {'height': '0', 'width': '0', 'length': '0'},
    );
  }

  // Method to update product data
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? discountPrice,
    int? stock,
    String? category,
    String? subCategory,
    String? brand,
    List<String>? images,
    List<String>? tags,
    bool? isActive,
    bool? isFeatured,
    bool? isOnSale,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminId,
    Map<String, dynamic>? specifications,
    double? rating,
    int? reviewCount,
    String? sku,
    double? weight,
    Map<String, String>? dimensions,
    String? status,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      categoryname: categoryname,
     
      images: images ?? this.images,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isOnSale: isOnSale ?? this.isOnSale,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(), // Always update the timestamp
      adminId: adminId ?? this.adminId,
      specifications: specifications ?? this.specifications,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      sku: sku ?? this.sku,
     
      status: status ?? this.status,
    );
  }

  // Helper methods
  bool get hasDiscount => discountPrice != null && discountPrice! > 0 && discountPrice! < price;
  
  double get finalPrice => hasDiscount ? discountPrice! : price;
  
  double get discountPercentage => hasDiscount 
      ? ((price - discountPrice!) / price * 100).roundToDouble() 
      : 0.0;
  
  bool get isInStock => stock > 0;
  
  bool get isLowStock => stock > 0 && stock <= 10;
  
  bool get isOutOfStock => stock <= 0;

  // Method to add/remove from featured
  ProductModel toggleFeatured() {
    return copyWith(isFeatured: !isFeatured, updatedAt: DateTime.now());
  }

  // Method to add/remove from sale
  ProductModel toggleSale() {
    return copyWith(isOnSale: !isOnSale, updatedAt: DateTime.now());
  }

  // Method to activate/deactivate product
  ProductModel toggleActive() {
    return copyWith(isActive: !isActive, updatedAt: DateTime.now());
  }

  // Method to update stock
  ProductModel updateStock(int newStock) {
    return copyWith(stock: newStock, updatedAt: DateTime.now());
  }

  // Method to update rating
  ProductModel updateRating(double newRating, int newReviewCount) {
    return copyWith(
      rating: newRating, 
      reviewCount: newReviewCount, 
      updatedAt: DateTime.now()
    );
  }

  // Method to publish product
  ProductModel publish() {
    return copyWith(status: 'published', isActive: true, updatedAt: DateTime.now());
  }

  // Method to archive product
  ProductModel archive() {
    return copyWith(status: 'archived', isActive: false, updatedAt: DateTime.now());
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, price: $price, stock: $stock, category: $category, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}