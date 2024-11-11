// lib/screens/customer_menu_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_carts/routes/routes.dart';
import 'package:smart_carts/base_lifecycle_observer.dart';

class CustomerMenuScreen extends StatefulWidget {
  const CustomerMenuScreen({Key? key}) : super(key: key);

  @override
  _CustomerMenuScreenState createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userName;

  List<Map<String, dynamic>> _recommendedProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchRecommendedProducts();
  }

  Future<void> _fetchUserName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _userName = userDoc['name'];
      });
    }
  }

  Future<void> _fetchRecommendedProducts() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot recommendDoc = await _firestore
          .collection('recommendProducts')
          .doc(user.uid)
          .get();

      if (!recommendDoc.exists) {
        print('No recommendations found for user ${user.uid}');
        return;
      }

      List<dynamic> recommendedProductIds = recommendDoc['recommendations'];

      List<Map<String, dynamic>> products = [];
      for (String productId in recommendedProductIds) {
        DocumentSnapshot productDoc = await _firestore
            .collection('products')
            .doc(productId)
            .get();

        if (productDoc.exists) {
          Map<String, dynamic> productData =
              productDoc.data() as Map<String, dynamic>;
          products.add(productData);
        } else {
          print('El producto $productId no existe');
        }
      }

      setState(() {
        _recommendedProducts = products;
      });
    } catch (e) {
      print('Error al obtener productos recomendados: $e');
    }
  }

  Future<void> _closeSession() async {
    await _auth.signOut();
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Está seguro que desea cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                await _closeSession();
                Navigator.of(context).pop();  
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (route) => false,
                );
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 400;

    return BaseLifecycleObserver(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: const Text('MENU DE CLIENTE',
              style: TextStyle(color: Colors.white)),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Center(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _userName != null
                                ? 'BIENVENIDO $_userName'
                                : 'Cargando...',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Image.asset(
                            'assets/logo.png',
                            height: 100,
                          ),
                          const SizedBox(height: 20),
                          if (_recommendedProducts.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Productos recomendados para ti:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 220,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _recommendedProducts.length,
                                    itemBuilder: (context, index) {
                                      final product = _recommendedProducts[index];
                                      return GestureDetector(
                                        onTap: () {
                                        },
                                        child: Container(
                                          width: 160,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Colors.grey.withOpacity(0.3),
                                                spreadRadius: 2,
                                                blurRadius: 5,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                product['imageUrl'] != null
                                                    ? Image.network(
                                                        product['imageUrl'],
                                                        height: 80,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Icon(
                                                        Icons.shopping_bag,
                                                        size: 80,
                                                        color: Colors.red,
                                                      ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  product['name'] ?? 'Producto',
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  'S/.${product['price'].toString()}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          if (isNarrow) ...[
                            ElevatedButton(
                              onPressed: _showLogoutConfirmationDialog,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('REGRESAR'),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, AppRoutes.shoppingCart);
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('ABRIR CARRO DE COMPRAS'),
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: _showLogoutConfirmationDialog,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('REGRESAR'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                        context, AppRoutes.shoppingCart);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('ABRIR CARRO DE COMPRAS'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
