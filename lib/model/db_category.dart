// models/db_category.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class db_category {
  final String categoryId;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  db_category({
    required this.categoryId,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory db_category.fromFirestore(String id, Map<String, dynamic> data) {
    return db_category(
      categoryId: id,
      name: data['name'],
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
