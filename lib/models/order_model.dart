import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final String productImage;
  final double productPrice;
  final double finalPrice;
  final int quantity;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String customerAddress;
  final double subtotal;
  final double totalAmount;
  final DateTime orderDate;
  final String status;

  OrderModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.finalPrice,
    required this.quantity,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.customerAddress,
    required this.subtotal,
    required this.totalAmount,
    required this.orderDate,
    this.status = 'pending',
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      productPrice: (map['productPrice'] ?? 0).toDouble(),
      finalPrice: (map['finalPrice'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      customerName: map['customerName'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerAddress: map['customerAddress'] ?? '',
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      orderDate: map['orderDate'] is Timestamp 
          ? (map['orderDate'] as Timestamp).toDate()
          : DateTime.parse(map['orderDate'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,
      'finalPrice': finalPrice,
      'quantity': quantity,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'subtotal': subtotal,
      'totalAmount': totalAmount,
      'orderDate': Timestamp.fromDate(orderDate),
      'status': status,
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? productId,
    String? productName,
    String? productImage,
    double? productPrice,
    double? finalPrice,
    int? quantity,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? customerAddress,
    double? subtotal,
    double? totalAmount,
    DateTime? orderDate,
    String? status,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      productPrice: productPrice ?? this.productPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      quantity: quantity ?? this.quantity,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      subtotal: subtotal ?? this.subtotal,
      totalAmount: totalAmount ?? this.totalAmount,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
    );
  }
}