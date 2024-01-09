import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tmd/classes.dart';
import 'package:tmd/scaler.dart';

class TmdClassificationResult {
  /// The class index.
  final int classIndex;

  /// The class label.
  final TransportMode classLabel;

  /// The confidence score.
  final double confidence;

  /// Create a new classification result.
  const TmdClassificationResult({
    required this.classIndex,
    required this.classLabel,
    required this.confidence,
  });
}

class TmdClassifier {
  /// The class mapping.
  static const _classMapping = {
    0: TransportMode.unknown,
    1: TransportMode.still,
    2: TransportMode.walking,
    3: TransportMode.run,
    4: TransportMode.bike,
    5: TransportMode.car,
    6: TransportMode.bus,
    7: TransportMode.train,
    8: TransportMode.subway,
  };

  /// The TFLite model interpreter.
  final IsolateInterpreter _interpreter;

  /// The accelerometer scalers.
  final List<Scaler> _accScalers;

  /// The gyro scalers.
  final List<Scaler> _gyrScalers;

  /// The magnetometer scalers.
  final List<Scaler> _magScalers;

  TmdClassifier({
    required IsolateInterpreter interpreter,
    required List<Scaler> accScalers,
    required List<Scaler> gyrScalers,
    required List<Scaler> magScalers,
  })  : _interpreter = interpreter,
        _accScalers = accScalers,
        _gyrScalers = gyrScalers,
        _magScalers = magScalers;

  /// Create the TmdClassifier.
  static Future<TmdClassifier> create() async {
    // Load the TFLite model interpreter.
    const path = 'packages/tmd/assets/model.tflite';
    final syncInterpreter = await Interpreter.fromAsset(path);
    syncInterpreter.allocateTensors();
    final interpreter = await IsolateInterpreter.create(
      address: syncInterpreter.address,
    );
    final accScalers = [
      await PowerTransformer.load('packages/tmd/assets/acc_mag.scaler.json'),
      await StandardScaler.load('packages/tmd/assets/acc_mag.scaler.json'),
    ];
    final gyrScalers = [
      await PowerTransformer.load('packages/tmd/assets/gyr_mag.scaler.json'),
      await StandardScaler.load('packages/tmd/assets/gyr_mag.scaler.json'),
    ];
    final magScalers = [
      await PowerTransformer.load('packages/tmd/assets/acc_mag.scaler.json'),
      await StandardScaler.load('packages/tmd/assets/acc_mag.scaler.json'),
    ];
    return TmdClassifier(
      interpreter: interpreter,
      accScalers: accScalers,
      gyrScalers: gyrScalers,
      magScalers: magScalers,
    );
  }

  /// Classify the given IMU sensor input.
  Future<TmdClassificationResult?> classify({
    required List<double> accMag,
    required List<double> magMag,
    required List<double> gyrMag,
  }) async {
    // We need at least 500 samples.
    // The order must be: [accelerometer, magnetometer, gyro].
    if (accMag.length != 500) return null;
    if (magMag.length != 500) return null;
    if (gyrMag.length != 500) return null;

    // Apply scalers
    for (Scaler scaler in _accScalers) {
      accMag = scaler.transform(accMag);
    }
    for (Scaler scaler in _magScalers) {
      magMag = scaler.transform(magMag);
    }
    for (Scaler scaler in _gyrScalers) {
      gyrMag = scaler.transform(gyrMag);
    }

    // Reshape to (n_timesteps x n_features)
    List input = [];
    for (var i = 0; i < 500; i++) {
      input.add([accMag[i], magMag[i], gyrMag[i]]);
    }

    // Run the model.
    List output = [List.filled(9, 0.0)];
    await _interpreter.run([input], output);
    output = output[0];

    // Find the class with the highest confidence.
    var maxConfidence = 0.0;
    var maxIndex = 0;
    for (var i = 0; i < output.length; i++) {
      if (output[i] > maxConfidence) {
        maxConfidence = output[i];
        maxIndex = i;
      }
    }

    // Return the classification result.
    return TmdClassificationResult(
      classIndex: maxIndex,
      classLabel: _classMapping[maxIndex] ?? TransportMode.unknown,
      confidence: maxConfidence,
    );
  }

  /// Close the TmdClassifier.
  Future<void> close() async {
    await _interpreter.close();
  }
}
