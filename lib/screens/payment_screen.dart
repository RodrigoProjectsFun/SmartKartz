// lib/screens/payment_screen.dart

import 'package:flutter/material.dart';
import 'package:smart_carts/screens/payment_confirmation_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:path/path.dart' as pathAlias; 

class PaymentScreen extends StatefulWidget {
  final String paymentLink;
  final String orderId;

  const PaymentScreen({
    Key? key,
    required this.paymentLink,
    required this.orderId,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Uint8List? qrImageBytes;
  bool isQrLoading = true;
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    _initializePaymentScreen();
  }

  Future<void> _initializePaymentScreen() async {
    await _generateQrCodeImage();
    _listenForPaymentConfirmation();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }


  Future<void> _generateQrCodeImage() async {
    try {
      final qrPainter = QrPainter(
        data: widget.paymentLink,
        version: QrVersions.auto,
        gapless: false,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );

      final image = await qrPainter.toImage(200);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      setState(() {
        qrImageBytes = pngBytes;
        isQrLoading = false;
      });
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar el QR: $e')),
      );
      setState(() {
        isQrLoading = false;
      });
    }
  }

  void _listenForPaymentConfirmation() {
    const String confirmationCollection = 'paymentConfirmations';
    const String statusSucceeded = 'succeeded';

    _subscription = FirebaseFirestore.instance
        .collection(confirmationCollection)
        .where('orderId', isEqualTo: widget.orderId)
        .where('status', isEqualTo: statusSucceeded)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .update({'status': 'completed'}); 

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PaymentConfirmationScreen(),
          ),
        );
      }
    }, onError: (error) {
      print('Error al escuchar la colección de confirmaciones: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al escuchar pagos: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    Widget qrSection;
    if (isQrLoading) {
      qrSection = const Center(child: CircularProgressIndicator());
    } else if (qrImageBytes == null) {
      qrSection = const Center(
        child: Text(
          'No se pudo generar el código QR.',
          style: TextStyle(color: Colors.red, fontSize: 18),
        ),
      );
    } else {
      qrSection = screenWidth < 600
          ? Column(
              children: [
                Image.memory(
                  qrImageBytes!,
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Escanea el código QR con tu cámara.',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '2. Presiona el enlace y dirígete a la página de pago.',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '3. Ya puedes pagar.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.memory(
                  qrImageBytes!,
                  width: 150,
                  height: 150,
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Escanea el código QR con tu cámara.',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '2. Presiona el enlace y dirígete a la página de pago.',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '3. Ya puedes pagar.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'REALIZAR PAGO',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: widget.paymentLink.isNotEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        qrSection,
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
                    )
                  : const Center(
                      child: Text(
                        'Enlace de pago no disponible',
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
