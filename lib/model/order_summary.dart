// lib/models/order_summary.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_carts/model/scanned_product.dart';

class OrderSummary {
  final List<Product> products;
  final int totalQuantity;
  final double totalPrice;
  final DateTime timestamp;

  OrderSummary({
    required this.products,
    required this.totalQuantity,
    required this.totalPrice,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'products': products.map((product) => product.toMap()).toList(),
      'totalQuantity': totalQuantity,
      'totalPrice': totalPrice,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory OrderSummary.fromMap(Map<String, dynamic> data) {
    return OrderSummary(
      products: (data['products'] as List<dynamic>)
          .map((item) => Product.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalQuantity: data['totalQuantity'] ?? 0,
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
