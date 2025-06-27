class BannerModel {
  final String id;
  final String name;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Factory constructor to create from JSON
  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: json['updatedAt']?.toDate() ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
    };
  }

  // Factory constructor to create new banner
  factory BannerModel.create({
    required String name,
    required String imageUrl,
    String? id,
  }) {
    return BannerModel(
      id: id ?? '',
      name: name,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Copy with method for updates
  BannerModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return BannerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Toggle active status
  BannerModel toggleActive() {
    return copyWith(
      isActive: !isActive,
      updatedAt: DateTime.now(),
    );
  }
}