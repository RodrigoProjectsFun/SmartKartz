import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;

class MLService {
  Interpreter? interpreter; 
  List<double>? predictedArray;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<void> initializeInterpreter() async {
  if (interpreter != null) return; 

  try {
    print('Initializing interpreter...');
    if (Platform.isAndroid) {
      print('Running on Android...');
      final delegate = GpuDelegateV2(
        options: GpuDelegateOptionsV2(
          isPrecisionLossAllowed: false,
        ),
      );
      print('GPU Delegate initialized.');
      final interpreterOptions = InterpreterOptions()..addDelegate(delegate);
      interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite', options: interpreterOptions);
    } else {
      print('Running on iOS...');
      interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite');
    }
    print('Model loaded successfully.');
  } catch (e) {
    print('Failed to load model.');
    print('Error: $e');
  }
}



Future<List<double>> extractFaceData(imglib.Image image) async {
  imglib.Image img = imglib.copyResizeCropSquare(image, size: 112);
  Float32List imageAsList = _imageToByteListFloat32(img);

  List input = imageAsList.reshape([1, 112, 112, 3]);
  List<List<double>> output = List.generate(1, (index) => List.filled(192, 0.0));

  interpreter?.run(input, output);

  List<double> flattenedOutput = List<double>.from(output.expand((i) => i));

  return flattenedOutput;
}


  Float32List _imageToByteListFloat32(imglib.Image image) {
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    List<List<List<int>>> imgArr = [];
    Uint8List decodedBytes = image.getBytes();

    for (int y = 0; y < image.height; y++) {
      imgArr.add([]);
      for (int x = 0; x < image.width; x++) {
        int red = decodedBytes[y * image.width * 3 + x * 3];
        int green = decodedBytes[y * image.width * 3 + x * 3 + 1];
        int blue = decodedBytes[y * image.width * 3 + x * 3 + 2];
        imgArr[y].add([red, green, blue]);
        buffer[pixelIndex++] = (red - 128) / 128;
        buffer[pixelIndex++] = (green - 128) / 128;
        buffer[pixelIndex++] = (blue - 128) / 128;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }
}
