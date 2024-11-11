// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/db_category.dart';
import '../model/db_product.dart';
import '../model/db_order.dart';
import 'package:firebase_auth/firebase_auth.dart';


class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<db_category>> fetchCategories() async {
    QuerySnapshot snapshot = await _firestore.collection('categories').get();

    return snapshot.docs.map((doc) {
      return db_category.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Future<List<db_Product>> fetchProducts() async {
    QuerySnapshot snapshot = await _firestore.collection('products').get();

    return snapshot.docs.map((doc) {
      return db_Product.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Future<List<db_order>> fetchOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    QuerySnapshot snapshot = await _firestore
        .collection('orders')
        .where('firebaseId', isEqualTo: user.uid)
        .get();

    return snapshot.docs.map((doc) {
      return db_order.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }
}