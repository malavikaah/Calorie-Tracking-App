import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../data/ml_food_database.dart';

class LocalMLService {
  // Detection Engine (20 Indian Dishes)
  Interpreter? _detectionInterpreter;
  bool _isInitialized = false;

  static const String detectionModelPath = 'assets/model/best_float32.tflite';
  static const int detectionInputSize = 320; 

  static const List<String> detectionLabels = [
    "Chicken Curry", "Plain Omelette", "Spinach Paneer", "Appam", "Avial", 
    "Banana Chips", "Chapati Roti", "Chocolate Cake", "Fruit Salad", "Idli", 
    "Kulfi", "Marble Cake", "Masala Dosa", "Vada", "Chicken Biryani", 
    "Pancake", "Sambar", "Uttapam", "Lemonade", "Rice Puttu"
  ];

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) return;

    try {
      _detectionInterpreter = await Interpreter.fromAsset(detectionModelPath);
      _isInitialized = true;
      if (kDebugMode) print('Local ML Detection Service Active (20 Dishes)');
    } catch (e) {
      if (kDebugMode) print('ML Init Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> analyzeImageLocal(Uint8List imageBytes) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return [];

    try {
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return [];

      if (_detectionInterpreter != null) {
        return await _runDetection(originalImage);
      }
      return [];
    } catch (e) {
      if (kDebugMode) print('Inference Error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _runDetection(img.Image originalImage) async {
    img.Image resizedImage = img.copyResize(originalImage, width: detectionInputSize, height: detectionInputSize);
    var inputBuffer = Float32List(1 * detectionInputSize * detectionInputSize * 3);
    int bufferIndex = 0;
    for (int y = 0; y < detectionInputSize; y++) {
      for (int x = 0; x < detectionInputSize; x++) {
        final pixel = resizedImage.getPixel(x, y);
        inputBuffer[bufferIndex++] = pixel.r / 255.0;
        inputBuffer[bufferIndex++] = pixel.g / 255.0;
        inputBuffer[bufferIndex++] = pixel.b / 255.0;
      }
    }
    
    final input = inputBuffer.reshape([1, detectionInputSize, detectionInputSize, 3]);
    final outputTensor = _detectionInterpreter!.getOutputTensors().first;
    var output = List.filled(outputTensor.shape.reduce((a, b) => a * b), 0.0).reshape(outputTensor.shape);

    _detectionInterpreter!.run(input, output);

    List<Map<String, dynamic>> detections = [];
    bool isStandardShape = outputTensor.shape[1] == 24;

    for (int i = 0; i < 2100; i++) {
      double maxScore = 0.0;
      int classId = -1;
      
      for (int c = 0; c < 20; c++) {
        double score = isStandardShape ? output[0][c + 4][i] : output[0][i][c + 4];
        if (score > maxScore) {
          maxScore = score;
          classId = c;
        }
      }

      // Adjusted threshold to 0.80 for a balance of local speed and high accuracy
      if (maxScore > 0.80) {
        double cx = isStandardShape ? output[0][0][i] : output[0][i][0];
        double cy = isStandardShape ? output[0][1][i] : output[0][i][1];
        double w = isStandardShape ? output[0][2][i] : output[0][i][2];
        double h = isStandardShape ? output[0][3][i] : output[0][i][3];

        String label = detectionLabels[classId];
        var nutrition = MLFoodDatabase.getDetails(label);

        detections.add({
          'name': label,
          'confidence': maxScore,
          'box': [cx - w / 2, cy - h / 2, w, h],
          'calories': nutrition?['calories']?.toString() ?? '0',
          'carbs': nutrition?['carbs']?.toString() ?? '0',
          'protein': nutrition?['protein']?.toString() ?? '0',
          'fat': nutrition?['fat']?.toString() ?? '0',
          'healthAlert': '',
        });
      }
    }

    detections.sort((a, b) => b['confidence'].compareTo(a['confidence']));
    List<Map<String, dynamic>> finalDetections = [];
    for (var det in detections) {
      bool shouldAdd = true;
      for (var existing in finalDetections) {
        if (_calculateIoU(det['box'], existing['box']) > 0.4) {
          shouldAdd = false;
          break;
        }
      }
      if (shouldAdd) finalDetections.add(det);
      if (finalDetections.length >= 3) break; 
    }
    return finalDetections;
  }

  double _calculateIoU(List<double> box1, List<double> box2) {
    double x1 = box1[0], y1 = box1[1], w1 = box1[2], h1 = box1[3];
    double x2 = box2[0], y2 = box2[1], w2 = box2[2], h2 = box2[3];
    double intersectionX = (x1 > x2 ? x1 : x2);
    double intersectionY = (y1 > y2 ? y1 : y2);
    double intersectionW = (x1 + w1 < x2 + w2 ? x1 + w1 : x2 + w2) - intersectionX;
    double intersectionH = (y1 + h1 < y2 + h2 ? y1 + h1 : y2 + h2) - intersectionY;
    if (intersectionW <= 0 || intersectionH <= 0) return 0.0;
    double intersectionArea = intersectionW * intersectionH;
    double unionArea = (w1 * h1) + (w2 * h2) - intersectionArea;
    return intersectionArea / unionArea;
  }

  void dispose() {
    _detectionInterpreter?.close();
  }
}