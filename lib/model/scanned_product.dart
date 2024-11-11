// lib/models/product.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  int quantity;
  final String tagUid;
  final String AuxProductID; 

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    required this.tagUid,
    required this.AuxProductID
  });

  factory Product.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: data['quantity'] ?? 1,
      tagUid: data['UIDresult'] ?? '',
      AuxProductID: data['productId'] ?? '1'
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'tagUid': tagUid,
      'productID' : AuxProductID,
    };
  }

  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Unknown',
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: data['quantity'] ?? 1,
      tagUid: data['tagUid'] ?? '',
      AuxProductID: data['productId'] ?? '1'
    );
  }
}
