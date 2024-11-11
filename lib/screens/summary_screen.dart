// summary_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_carts/model/order_summary.dart';
import 'package:smart_carts/model/order.dart' as customOrder;
import 'package:smart_carts/screens/payment_screen.dart';
import 'package:smart_carts/model/scanned_product.dart';

class SummaryScreen extends StatefulWidget {
  final String orderId;

  const SummaryScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _SummaryScreenState createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  customOrder.Order? order;
  bool isLoading = true;
  String? paymentLink;
  String? errorMessage;
  String? debugOrderId; 

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  void _fetchOrder() async {
    debugOrderId = widget.orderId; 
    try {
      print('Fetching order with ID: $debugOrderId'); 

      DocumentSnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (orderSnapshot.exists) {
        final data = orderSnapshot.data() as Map<String, dynamic>;

        if (!data.containsKey('items') ||
            !data.containsKey('firebaseId') ||
            !data.containsKey('paymentLink')) {
          setState(() {
            errorMessage = 'El pedido está incompleto. Faltan campos esenciales.';
            isLoading = false;
          });
          return;
        }

        List<dynamic> items = data['items'];
        String firebaseId = data['firebaseId'];

        List<Product> products = [];
        for (var item in items) {
          if (!item.containsKey('productId') || !item.containsKey('quantity')) {
            setState(() {
              errorMessage = 'Formato de producto inválido en el pedido. Faltan campos.';
              isLoading = false;
            });
            return;
          }

          String productId = item['productId'];
          int quantity = item['quantity'];

          DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .get();

          if (productSnapshot.exists) {
            final productData = productSnapshot.data() as Map<String, dynamic>;

            // Validar datos del producto
            if (!productData.containsKey('name') ||
                !productData.containsKey('price') ||
                !productData.containsKey('productId')) {
              setState(() {
                errorMessage = 'Datos de producto incompletos para el ID: $productId.';
                isLoading = false;
              });
              return;
            }

            try {
              Product product = Product(
                id: productId,
                name: productData['name'],
                price: (productData['price'] as num).toDouble(),
                quantity: quantity,
                tagUid: '',
                AuxProductID: productData['productId'],
              );
              products.add(product);
            } catch (e) {
              setState(() {
                errorMessage = 'Error al formatear el producto con ID: $productId. Detalle: $e';
                isLoading = false;
              });
              return;
            }
          } else {
            setState(() {
              errorMessage = 'Producto no encontrado con ID: $productId en Firestore.';
              isLoading = false;
            });
            return;
          }
        }

        // Calcular cantidad y precio total
        final totalQuantity = products.fold(0, (sum, product) => sum + product.quantity);
        final totalPrice = products.fold(0.0, (sum, product) => sum + product.price * product.quantity);

        final timestamp = data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now();

        final orderSummary = OrderSummary(
          products: products,
          totalQuantity: totalQuantity,
          totalPrice: totalPrice,
          timestamp: timestamp,
        );

        // Crear objeto Order
        order = customOrder.Order(
          orderId: widget.orderId,
          orderSummary: orderSummary,
          customerId: firebaseId,
          createdAt: timestamp,
        );
        paymentLink = data['paymentLink'];

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Pedido no encontrado para el ID de orden: $debugOrderId.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al obtener el pedido con ID: $debugOrderId. Detalle: $e';
        isLoading = false;
      });
    }
  }

  void _navigateToPayment() {
    if (paymentLink == null || order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace de pago no disponible.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          paymentLink: paymentLink!,
          orderId: widget.orderId, 
        ),
      ),
    );
  }

  Future<void> _showCancelConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar Orden'),
          content: const Text(
              '¿Estás seguro de que deseas cancelar la orden? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCELAR'),
              onPressed: () {
                Navigator.of(context).pop(); 
              },
            ),
            TextButton(
              child: const Text('CONFIRMAR'),
              onPressed: () async {
                Navigator.of(context).pop(); 
                if (widget.orderId.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(widget.orderId)
                        .delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pedido cancelado exitosamente.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al cancelar el pedido: $e')),
                    );
                  }
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de la Orden'),
        backgroundColor: Colors.red,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (order == null && errorMessage != null)
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ID de Orden: $debugOrderId',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
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
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        DataTable(
                          columns: const [
                            DataColumn(label: Text('Producto')),
                            DataColumn(label: Text('Precio')),
                            DataColumn(label: Text('Cantidad')),
                            DataColumn(label: Text('Total')),
                          ],
                          rows: order!.orderSummary.products.map((product) {
                            return DataRow(cells: [
                              DataCell(Text(product.name)),
                              DataCell(Text('${product.price.toStringAsFixed(2)} S/.')),
                              DataCell(Text(product.quantity.toString())),
                              DataCell(Text(
                                  '${(product.price * product.quantity).toStringAsFixed(2)} S/.')),
                            ]);
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cantidad Total: ${order!.orderSummary.totalQuantity}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Precio Total (sin IGV): ${order!.orderSummary.totalPrice.toStringAsFixed(2)} S/.',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'IGV (18%): ${(order!.orderSummary.totalPrice * 0.18).toStringAsFixed(2)} S/.',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Precio Final (con IGV): ${(order!.orderSummary.totalPrice * 1.18).toStringAsFixed(2)} S/.',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _showCancelConfirmationDialog,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('REGRESAR'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _navigateToPayment,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('GENERAR QR Y PAGAR'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
