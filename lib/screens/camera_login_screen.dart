import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:smart_carts/base_lifecycle_observer.dart';

class CameraLoginScreen extends StatefulWidget {
  static const CameraLoginScreen _instance = CameraLoginScreen._internal();

  factory CameraLoginScreen() {
    return _instance;
  }

  const CameraLoginScreen._internal();

  @override
  _CameraLoginScreenState createState() => _CameraLoginScreenState();
}

class _CameraLoginScreenState extends State<CameraLoginScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  XFile? pictureFile;

  bool _blinkDetected = false;
  bool _eyePreviouslyOpen = true;
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(enableClassification: true),
  );
  Timer? _timer;

  int _blinkCount = 0;
  final int _requiredBlinks = 2;

  bool _dialogShown = false;
  bool _showAnalyzingText = true;

  bool _eyesDetected = false;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller.initialize();
    _startEyeBlinkDetection();
    setState(() {});
  }

  void _startEyeBlinkDetection() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!mounted || !_controller.value.isInitialized) {
        timer.cancel();
        return;
      }

      try {
        final XFile frame = await _controller.takePicture();
        final inputImage = InputImage.fromFilePath(frame.path);
        final faces = await _faceDetector.processImage(inputImage);

        if (faces.isEmpty) {
          _blinkCount = 0;
          _eyePreviouslyOpen = true;
          _eyesDetected = false;
          setState(() {
            _blinkDetected = false;
          });
          if (!_dialogShown) {
            _dialogShown = true;
            _showDialog(
              'Atención',
              'Por favor, mantén la mirada en la pantalla mientras se realiza el análisis.',
              autoDismiss: true,
            );
          }
        } else if (faces.length > 1) {
          _blinkCount = 0;
          _eyePreviouslyOpen = true;
          _eyesDetected = false;
          setState(() {
            _blinkDetected = false;
            _showAnalyzingText = true;
          });
          if (!_dialogShown) {
            _dialogShown = true;
            _showDialog(
              'Advertencia',
              'Se detectaron múltiples caras. Por favor, asegúrate de estar solo en la cámara.',
              autoDismiss: true,
            );
          }
        } else {
          final face = faces.first;
          final leftEyeOpenProb = face.leftEyeOpenProbability ?? -1.0;
          final rightEyeOpenProb = face.rightEyeOpenProbability ?? -1.0;

          _eyesDetected = leftEyeOpenProb >= 0.0 && rightEyeOpenProb >= 0.0;

          if (!_eyesDetected) {
            _blinkCount = 0;
            _eyePreviouslyOpen = true;
            setState(() {
              _blinkDetected = false;
            });
            if (!_dialogShown) {
              _dialogShown = true;
              _showDialog(
                'Atención',
                'Por favor, mantén la mirada en la pantalla mientras se realiza el análisis.',
                autoDismiss: true,
              );
            }
          } else {

            final eyesOpen = leftEyeOpenProb > 0.7 && rightEyeOpenProb > 0.7;
            final eyesClosed = leftEyeOpenProb < 0.3 && rightEyeOpenProb < 0.3;

            if (_eyePreviouslyOpen && eyesClosed) {
              _eyePreviouslyOpen = false;
            } else if (!_eyePreviouslyOpen && eyesOpen) {
              _eyePreviouslyOpen = true;
              _blinkCount++;

              setState(() {
                _blinkDetected = _blinkCount >= _requiredBlinks;
              });

              if (_blinkDetected && !_dialogShown) {
                _dialogShown = true;
                _showAnalyzingText = false; 
                _showDialog(
                  'Análisis completado',
                  'Ahora puedes tomar la foto.',
                  autoDismiss: true,
                );
              }
            } else {
              _eyePreviouslyOpen = eyesOpen;
            }
          }
        }
      } catch (e) {
        print('Error al capturar el fotograma: $e');
      }
    });
  }

  void _showDialog(String title, String content, {bool autoDismiss = false}) {
    showDialog(
      context: context,
      barrierDismissible: !autoDismiss,
      builder: (BuildContext context) {
        if (autoDismiss) {
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
              _dialogShown = false;
            }
          });
        }
        return AlertDialog(
          title: Text(title),
          content: Text(content),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<File?> _cropFace(XFile picture) async {
    final inputImage = InputImage.fromFilePath(picture.path);
    final faceDetector = GoogleMlKit.vision.faceDetector();
    final List<Face> faces = await faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      return null;
    }

    final face = faces.first;
    const margin = 20;
    final cropRect = Rect.fromLTRB(
      (face.boundingBox.left - margin).clamp(0, face.boundingBox.right),
      (face.boundingBox.top - margin).clamp(0, face.boundingBox.bottom),
      (face.boundingBox.right + margin).clamp(face.boundingBox.left, double.infinity),
      (face.boundingBox.bottom + margin).clamp(face.boundingBox.top, double.infinity),
    );

    final bytes = await picture.readAsBytes();
    final image = img.decodeImage(bytes);

    final croppedImage = img.copyCrop(
      image!,
      x: cropRect.left.toInt(),
      y: cropRect.top.toInt(),
      width: cropRect.width.toInt(),
      height: cropRect.height.toInt(),
    );

    final croppedFilePath = join(
      (await getTemporaryDirectory()).path,
      '${DateTime.now()}.png',
    );
    final croppedFile = File(croppedFilePath)..writeAsBytesSync(img.encodePng(croppedImage));

    return croppedFile;
  }

  @override
  Widget build(BuildContext context) {
    return BaseLifecycleObserver(
      child: Scaffold(
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              return Stack(
                children: [
                  Positioned.fill(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: CameraPreview(_controller),
                    ),
                  ),
                  if (_showAnalyzingText)
                    Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'Analizando que eres una persona real, por favor mantén la mirada en la pantalla',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            backgroundColor: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton.icon(
                        onPressed: _blinkDetected && _eyesDetected
                            ? () async {
                                try {
                                  await _initializeControllerFuture;
                                  pictureFile = await _controller.takePicture();

                                  final croppedFile = await _cropFace(pictureFile!);

                                  if (croppedFile != null) {
                                    Navigator.pop(context, croppedFile.path);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'No se detectó ninguna cara, por favor inténtalo de nuevo.')),
                                    );
                                  }
                                } catch (e) {
                                  print(e);
                                }
                              }
                            : null,
                        icon: const Icon(Icons.camera),
                        label: const Text('Tomar Foto'),
                      ),
                    ),
                  ),
                ],
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return const Center(child: Text('Error al inicializar la cámara'));
            }
          },
        ),
      ),
    );
  }
}
