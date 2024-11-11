// models/db_Product.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class db_Product {
  final String productId;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final DateTime createdAt;

  db_Product({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.createdAt,
  });

  factory db_Product.fromFirestore(String id, Map<String, dynamic> data) {
    return db_Product(
      productId: id,
      name: data['name'],
      description: data['description'],
      price: (data['price'] as num).toDouble(),
      categoryId: data['categoryId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
