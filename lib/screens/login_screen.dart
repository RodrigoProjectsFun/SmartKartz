import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_carts/routes/routes.dart';
import 'package:smart_carts/screens/camera_login_screen.dart';
import 'package:smart_carts/services/ml_service.dart';
import 'package:image/image.dart' as img;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _capturedImagePath;
  final MLService _mlService = MLService();
  String? _phoneDeviceId;

  @override
  void initState() {
    super.initState();
    _mlService.initializeInterpreter();
  }

 
  Future<void> _captureImage(BuildContext context) async {
    final capturedImagePath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>  CameraLoginScreen(),
      ),
    );

    if (capturedImagePath != null) {
      setState(() {
        _capturedImagePath = capturedImagePath;
      });
    }
  }

  Future<void> _showErrorDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); 
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _validateFace(BuildContext context) async {
    if (_capturedImagePath == null) {
      await _showErrorDialog(
        'Foto no Capturada',
        'Por favor, capture una imagen primero.',
      );
      return;
    }

    try {
      final inputImage = InputImage.fromFilePath(_capturedImagePath!);
      final faceDetector = GoogleMlKit.vision.faceDetector();
      final List<Face> faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        await _showErrorDialog(
          'Cara No Detectada',
          'No se detectó ninguna cara en la imagen capturada. Por favor, intente de nuevo.',
        );
        return;
      }

      final face = faces.first;
      final cropRect = Rect.fromLTRB(
        face.boundingBox.left,
        face.boundingBox.top,
        face.boundingBox.right,
        face.boundingBox.bottom,
      );

      final bytes = await File(_capturedImagePath!).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        // Caso 3: Error al procesar la imagen
        await _showErrorDialog(
          'Error de Imagen',
          'Hubo un problema al procesar la imagen capturada. Por favor, intente de nuevo.',
        );
        return;
      }

      final croppedFace = img.copyCrop(
        image,
        x: cropRect.left.toInt(),
        y: cropRect.top.toInt(),
        width: cropRect.width.toInt(),
        height: cropRect.height.toInt(),
      );

      final faceFeatures = await _mlService.extractFaceData(croppedFace);

      final matchedUser = await findMatchingUser(faceFeatures);

      if (matchedUser != null) {
        await _loginWithEmailAndPassword(matchedUser['email'], matchedUser['dni']);
        await _updateSessionStatus();
      } else {
        // Caso 4: Cara no reconocida
        await _showErrorDialog(
          'Cara No Reconocida',
          'La cara no fue reconocida. Por favor, intente de nuevo.',
        );
      }
    } catch (e) {
      print(e);
      // Caso 5: Error general al validar la cara
      await _showErrorDialog(
        'Error de Validación',
        'Ocurrió un error al validar la cara. Por favor, inténtelo de nuevo.',
      );
    }
  }




  Future<void> _loginWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Usuario ha iniciado sesión: ${userCredential.user?.email}');
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.customerMenu, (Route<dynamic> route) => false);
    } catch (e) {
      print('Inicio de sesión fallido: $e');
      await _showErrorDialog(
        'Inicio de Sesión Fallido',
        'El inicio de sesión falló. Por favor, inténtelo de nuevo.',
      );
    }
  }

  Future<Map<String, dynamic>?> findMatchingUser(List<double> faceFeatures) async {
    final firestore = FirebaseFirestore.instance;
    final querySnapshot = await firestore.collection('users').get();

    for (var doc in querySnapshot.docs) {
      final storedFeatures = List<double>.from(doc['faceData']);
      final distance = _calculateEuclideanDistance(storedFeatures, faceFeatures);
      if (distance < 1.0) {
        return doc.data();
      }
    }
    return null;
  }

  double _calculateEuclideanDistance(List<double> a, List<double> b) {
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += (a[i] - b[i]) * (a[i] - b[i]);
    }
    return sqrt(sum);
  }

  Future<void> _updateSessionStatus() async {
    if (_phoneDeviceId == null) return;

    final firestore = FirebaseFirestore.instance;
    final querySnapshot = await firestore
        .collection('session')
        .where('phone_device', isEqualTo: _phoneDeviceId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      if (doc['active'] == false) {
        await firestore.collection('session').doc(doc.id).update({'active': true});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final isNarrow = screenWidth < 400;

    double buttonSpacing = isPortrait ? screenWidth * 0.02 : screenWidth * 0.05;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('INICIAR SESIÓN', style: TextStyle(color: Colors.white)),
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
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _capturedImagePath == null
                            ? const Icon(
                                Icons.person,
                                color: Colors.black,
                                size: 150,
                              )
                            : Image.file(
                                File(_capturedImagePath!),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                        const SizedBox(height: 32),
                        Column(
                          children: [
                            Wrap(
                              spacing: buttonSpacing,
                              runSpacing: buttonSpacing,
                              alignment: WrapAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isPortrait ? screenWidth * 0.05 : screenWidth * 0.02,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('REGRESAR'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    _captureImage(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isPortrait ? screenWidth * 0.05 : screenWidth * 0.02,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('TOMAR FOTO'),
                                ),
                                if (!isNarrow)
                                  ElevatedButton(
                                    onPressed: () {
                                      _validateFace(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.red,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isPortrait ? screenWidth * 0.05 : screenWidth * 0.02,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('VALIDAR FOTO'),
                                  ),
                              ],
                            ),
                            if (isNarrow)
                              Padding(
                                padding: EdgeInsets.only(top: buttonSpacing),
                                child: ElevatedButton(
                                  onPressed: () {
                                    _validateFace(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isPortrait ? screenWidth * 0.05 : screenWidth * 0.02,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('VALIDAR FOTO'),
                                ),
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
        },
      ),
    );
  }
}
