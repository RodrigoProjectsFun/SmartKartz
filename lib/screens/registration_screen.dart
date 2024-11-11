import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_carts/routes/routes.dart';
import 'package:smart_carts/screens/camera_register_screen.dart';
import 'package:smart_carts/services/ml_service.dart';
import 'package:image/image.dart' as img;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:smart_carts/base_lifecycle_observer.dart';
import 'package:smart_carts/model/user.dart' as user;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _mlService = MLService();
  final _formKey = GlobalKey<FormState>();

  String? name;
  String? email;
  String? dni;
  String? firstName;
  String? lastName;
  List<double>? faceData;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _mlService.initializeInterpreter();
  }

  Future<void> _captureFace() async {
    final capturedImagePath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraRegisterScreen()),
    );

    if (capturedImagePath != null) {
      setState(() {
        _capturedImagePath = capturedImagePath;
      });

      final bytes = await File(capturedImagePath).readAsBytes();
      final image = img.decodeImage(bytes);

      final inputImage = InputImage.fromFilePath(capturedImagePath);
      final faceDetector = GoogleMlKit.vision.faceDetector();
      final List<Face> faces = await faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;
        final cropRect = Rect.fromLTRB(
          face.boundingBox.left,
          face.boundingBox.top,
          face.boundingBox.right,
          face.boundingBox.bottom,
        );

        final croppedFace = img.copyCrop(
          image!,
          x: cropRect.left.toInt(),
          y: cropRect.top.toInt(),
          width: cropRect.width.toInt(),
          height: cropRect.height.toInt(),
        );

        final faceFeatures = await _mlService.extractFaceData(croppedFace);
        setState(() {
          faceData = faceFeatures;
        });
      } else {
        _showErrorDialog('No se detectó ninguna cara, por favor intente de nuevo.');
      }
    }
  }

  void _parseName() {
    if (name != null) {
      final parts = name!.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        firstName = parts.first;
        lastName = parts.sublist(1).join(' ');
      } else {
        firstName = name;
        lastName = '';
      }
    }
  }

  Future<void> _registerUser() async {
    _parseName();
    if (_formKey.currentState!.validate() && faceData != null) {
      if (faceData!.every((element) => element == 0)) {
        _showErrorDialog(
          'La foto no es válida. Por favor, capture una nueva foto de su rostro.',
        );
        return;
      }

      try {
        final dniQuery = await _firestore
            .collection('users')
            .where('dni', isEqualTo: dni)
            .get();
        if (dniQuery.docs.isNotEmpty) {
          _showErrorDialog('El DNI ya está registrado.');
          return;
        }

        final nameQuery = await _firestore
            .collection('users')
            .where('name', isEqualTo: name)
            .get();
        if (nameQuery.docs.isNotEmpty) {
          _showErrorDialog('El nombre ya está registrado.');
          return;
        }

        // Esta funcion valida que existe un rostro 
        final usersSnapshot = await _firestore.collection('users').get();

        bool faceExists = false;
        for (var doc in usersSnapshot.docs) {
          var userData = doc.data();
          if (userData['faceData'] != null) {
            List<dynamic> existingFaceDataDynamic = userData['faceData'];
            List<double> existingFaceData = existingFaceDataDynamic.map((e) => e as double).toList();

            double distance = _calculateEuclideanDistance(faceData!, existingFaceData);
            if (distance < 1.0) { 
              faceExists = true;
              break;
            }
          }
        }

        if (faceExists) {
          _showErrorDialog('El rostro ya está registrado.');
          return;
        }

        try {
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: email!,
            password: dni!,
          );

          await userCredential.user!.sendEmailVerification();

          _showEmailVerificationDialog();
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            _showErrorDialog('El correo electrónico ya está registrado.');
          } else {
            _showErrorDialog(
                'Error al registrar el usuario. Por favor, inténtelo de nuevo.');
          }
        }
      } catch (e) {
        _showErrorDialog(
            'Error al verificar los datos. Por favor, inténtelo de nuevo.');
      }
    } else {
      _showErrorDialog(
          'Por favor, complete todos los campos y capture una foto de su rostro.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  double _calculateEuclideanDistance(List<double> vector1, List<double> vector2) {
    double sum = 0.0;
    for (int i = 0; i < vector1.length; i++) {
      sum += pow(vector1[i] - vector2[i], 2);
    }
    return sqrt(sum);
  }

  void _saveUserData() async {
    final newUser = user.User_model(
      id: _auth.currentUser!.uid,
      name: name!,
      email: email!,
      dni: dni!,
      firstName: firstName!,
      lastName: lastName!,
      faceData: faceData!,
    );
    await _firestore.collection('users').doc(newUser.id).set(newUser.toJson());

    Navigator.pushNamed(context, AppRoutes.customerMenu);
  }

void _showVerificationSuccessDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Correo verificado'),
      content: const Text('Su correo electrónico ha sido verificado exitosamente.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); 
            Navigator.pushNamed(context, AppRoutes.customerMenu); 
          },
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible:
          false, 
      builder: (context) => AlertDialog(
        title: const Text('Verificar correo electrónico'),
        content: const Text(
          'Se ha enviado un enlace de verificación a su correo electrónico. Por favor, verifique su correo y luego presione "He verificado mi correo".',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _auth.currentUser!
                  .reload(); 
              if (_auth.currentUser!.emailVerified) {
                Navigator.of(context).pop(); 
                _saveUserData(); 
                _showVerificationSuccessDialog(); 
              } else {
                _showErrorDialog(
                    'El correo electrónico aún no ha sido verificado.');
              }
            },
            child: const Text('He verificado mi correo'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _auth.currentUser!.sendEmailVerification();
                _showErrorDialog(
                    'Se ha reenviado el correo de verificación.');
              } catch (e) {
                _showErrorDialog(
                    'Error al reenviar el correo de verificación.');
              }
            },
            child: const Text('Reenviar correo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    return BaseLifecycleObserver(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: const Text('FORMULARIO DE REGISTRO',
              style: TextStyle(color: Colors.white)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        errorStyle: TextStyle(color: Colors.red, fontSize: 14),
                        errorBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      onChanged: (value) => name = value,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El campo "Nombre Completo" es obligatorio';
                        } else {
                          String trimmedValue = value.trim();
                          final parts = trimmedValue.split(RegExp(r'\s+'));
                          if (parts.length < 2) {
                            return 'Debe ingresar al menos nombre y apellido';
                          }
                          final RegExp nameRegExp = RegExp(
                              r"^[A-Za-zÁÉÍÓÚáéíóúüÜÑñ]+(?:[\s'-][A-Za-zÁÉÍÓÚáéíóúüÜÑñ]+)+$");
                          if (!nameRegExp.hasMatch(trimmedValue)) {
                            return 'El campo "Nombre Completo" contiene caracteres no válidos';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        errorStyle: TextStyle(color: Colors.red, fontSize: 14),
                        errorBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      onChanged: (value) => email = value,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El campo "Correo electrónico" es obligatorio';
                        } else {
                          String trimmedValue = value.trim();
                          final RegExp emailRegExp = RegExp(
                              r"^(?!.*\s)[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
                          if (!emailRegExp.hasMatch(trimmedValue)) {
                            return 'El campo "Correo electrónico" contiene un correo no válido';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Campo de DNI con validación mejorada
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'DNI',
                        errorStyle: TextStyle(color: Colors.red, fontSize: 14),
                        errorBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      onChanged: (value) => dni = value,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El campo "DNI" es obligatorio';
                        } else {
                          String trimmedValue = value.trim();
                          if (!RegExp(r'^\d{8}$').hasMatch(trimmedValue)) {
                            return 'El campo "DNI" debe tener exactamente 8 dígitos numéricos';
                          }
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _capturedImagePath == null
                            ? const Icon(
                                Icons.person,
                                color: Colors.black,
                                size: 100,
                              )
                            : Image.file(
                                File(_capturedImagePath!),
                                width: screenWidth * 0.3,
                                height: screenHeight * 0.2,
                                fit: BoxFit.cover,
                              ),
                        ElevatedButton(
                          onPressed: _captureFace,
                          child: const Text('Tomar foto de rostro'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                          ),
                          child: const Text('REGRESAR'),
                        ),
                        ElevatedButton(
                          onPressed: _registerUser,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('REGISTRAR'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
