// shopping_cart_screen.dart

import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_carts/model/models.dart';
import 'package:smart_carts/routes/routes.dart';
import 'package:smart_carts/base_lifecycle_observer.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({Key? key}) : super(key: key);

  @override
  _ShoppingCartScreenState createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  String? firebaseUid;
  List<Product> products = [];
  bool isProcessing = false;

  StreamSubscription<QuerySnapshot>? _shoppingCartSubscription;

  @override
  void initState() {
    super.initState();
    _getFirebaseUid();
    _listenToShoppingCart();
  }

  void _getFirebaseUid() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        firebaseUid = user.uid;
      });
    }
  }

  void _listenToShoppingCart() {
    if (firebaseUid != null) {
      _shoppingCartSubscription = FirebaseFirestore.instance
          .collection('shoppingcart')
          .snapshots()
          .listen((snapshot) {
        final Map<String, Product> productMap = {};
        for (var doc in snapshot.docs) {
          final product = Product.fromDocument(doc);

          if (productMap.containsKey(product.name)) {
            productMap[product.name]!.quantity += product.quantity;
          } else {
            productMap[product.name] = product;
          }
        }

        setState(() {
          products = productMap.values.toList();
        });
      }, onError: (error) {
        print('Error listening to shopping cart: $error');
      });
    }
  }

  Future<String?> _waitForOrderCreation(
      String orderIntentId, Duration timeout) async {
    final startTime = DateTime.now();
    while (DateTime.now().difference(startTime) < timeout) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('orderIntentId', isEqualTo: orderIntentId)
          .where('status', isEqualTo: 'pending') 
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final orderDoc = snapshot.docs.first;
        return orderDoc.id;
      }

      await Future.delayed(const Duration(seconds: 1));
    }
    return null; 
  }

  void _generateOrderIntent() async {
    if (products.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Atención'),
            content: const Text(
                'El carrito está vacío. Agrega al menos un producto para proceder al pago.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
      return;
    }

    bool confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirmar orden'),
              content: const Text(
                  '¿Está seguro que desea generar la orden con los productos seleccionados?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return; 
    }

    setState(() {
      isProcessing = true;
    });

    if (firebaseUid == null) {
      setState(() {
        isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    final orderIntentId =
        FirebaseFirestore.instance.collection('orderintent').doc().id;

    final productIds = products.map((product) {
      return {
        'productId': product.AuxProductID,
        'quantity': product.quantity,
      };
    }).toList();

    try {
      await FirebaseFirestore.instance
          .collection('orderintent')
          .doc(orderIntentId)
          .set({
        'firebaseId': firebaseUid!,
        'productIds': productIds,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final orderId = await _waitForOrderCreation(
          orderIntentId, const Duration(seconds: 30));

      if (orderId != null) {
        await _clearShoppingCart();

        Navigator.pushNamed(
          context,
          AppRoutes.summary,
          arguments: orderId,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo procesar la orden. Intente de nuevo.')),
        );
      }

      setState(() {
        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear la intención de pedido: $e')),
      );
    }
  }

  Future<void> _clearShoppingCart() async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      var querySnapshot = await FirebaseFirestore.instance
          .collection('shoppingcart')
          .get();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing shopping cart: $e');
    }
  }

  @override
  void dispose() {
    _shoppingCartSubscription?.cancel();
    _clearShoppingCart();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (firebaseUid == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: const Text('CARRO DE COMPRAS',
              style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BaseLifecycleObserver(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: const Text('CARRO DE COMPRAS',
              style: TextStyle(color: Colors.white)),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Carrito de Compras',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  products.isEmpty
                      ? const Text(
                          'No hay productos en el carrito de compras',
                          style: TextStyle(fontSize: 16),
                        )
                      : Column(
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 12.0,
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Nombre',
                                      style:
                                          TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Precio',
                                      style:
                                          TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Cantidad',
                                      style:
                                          TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Total',
                                      style:
                                          TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                                rows: products.map((product) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        SizedBox(
                                          width: 150,
                                          child: Text(
                                            product.name,
                                            style:
                                                const TextStyle(fontSize: 14),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${product.price.toStringAsFixed(2)} S/.',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          product.quantity.toString(),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${(product.price * product.quantity).toStringAsFixed(2)} S/.',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Subtotal: ${products.fold(0.0, (sum, product) => sum + product.price * product.quantity).toStringAsFixed(2)} S/.',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('REGRESAR'),
                      ),
                      ElevatedButton(
                        onPressed: isProcessing
                            ? null
                            : () {
                                _generateOrderIntent();
                              },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              isProcessing ? Colors.grey : Colors.red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isProcessing
                            ? const Text('Procesando...')
                            : const Text('IR A PAGAR'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
