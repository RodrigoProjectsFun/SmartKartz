// lib/models/order.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_summary.dart';

class Order {
  final String orderId;
  final OrderSummary orderSummary;
  final String customerId;
  final DateTime createdAt;

  Order({
    required this.orderId,
    required this.orderSummary,
    required this.customerId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'orderSummary': orderSummary.toMap(),
      'customerId': customerId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Order.fromMap(Map<String, dynamic> data) {
    return Order(
      orderId: data['orderId'] ?? '',
      orderSummary: OrderSummary.fromMap(data['orderSummary'] as Map<String, dynamic>),
      customerId: data['customerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
