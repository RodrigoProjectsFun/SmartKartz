// lib/models/db_order.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final int quantity;

  OrderItem({required this.productId, required this.quantity});

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      productId: data['productId'],
      quantity: data['quantity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }
}

class db_order {
  final String orderId;
  final String firebaseId; // User's Firebase ID
  final DateTime createdAt;
  final String orderIntentId;
  final String paymentLink;
  final String status;
  final double totalAmount;
  final List<OrderItem> items;

  db_order({
    required this.orderId,
    required this.firebaseId,
    required this.createdAt,
    required this.orderIntentId,
    required this.paymentLink,
    required this.status,
    required this.totalAmount,
    required this.items,
  });

  factory db_order.fromFirestore(String id, Map<String, dynamic> data) {
    var itemsData = data['items'] as List<dynamic>;
    List<OrderItem> itemsList =
        itemsData.map((item) => OrderItem.fromMap(item)).toList();

    return db_order(
      orderId: id,
      firebaseId: data['firebaseId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      orderIntentId: data['orderIntentId'] ?? '',
      paymentLink: data['paymentLink'] ?? '',
      status: data['status'] ?? '',
      totalAmount: (data['totalAmount'] as num).toDouble(),
      items: itemsList,
    );
  }
}
