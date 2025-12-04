import 'package:tflite_flutter/tflite_flutter.dart';

class FraudDetector {
  Interpreter? _interpreter;

  /// Load the TFLite model
  Future<void> loadModel(String path) async {
    try {
      _interpreter = await Interpreter.fromAsset(path);
      print(
          "MODEL IS LOADED SUCESSFULY NAME $path: INTERPRETER: $_interpreter");
    } catch (e) {
      print(" FAILED TO LOAD MODEL: $e  ->NAME : $path ");
    }
  }

  /// Run prediction on a single transaction
  Future<double> predict(List<double> inputData) async {
    if (_interpreter == null) {
      throw Exception("Interpreter not initialized. Call loadModel() first.");
    }

    // Convert input to 2D (batch_size=1, features=N)
    var input = [inputData];

    // Prepare output buffer
    var output = List.filled(1 * 1, 0).reshape([1, 1]);

    // Run inference
    _interpreter!.run(input, output);

    // Extract result
    return output[0][0].toDouble();
  }
}
