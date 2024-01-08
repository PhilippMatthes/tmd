import 'dart:math';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
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

enum TransportMode {
  unknown,
  still,
  walking,
  run,
  bike,
  car,
  bus,
  train,
  subway,
}

/// The index of the class mapped to a human readable label.
final Map<int, TransportMode> _classMapping = {
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

class TmdClassifier {
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

  /// Close the TmdClassifier.
  Future<void> close() async {
    await _interpreter.close();
  }

  /// Classify the given IMU sensor input.
  Future<TmdClassificationResult?> classify({
    required List<AccelerometerEvent> accEvents,
    required List<MagnetometerEvent> magEvents,
    required List<GyroscopeEvent> gyrEvents,
  }) async {
    // We need at least 500 samples.
    // The order must be: [accelerometer, magnetometer, gyro].
    if (accEvents.length != 500) return null;
    if (magEvents.length != 500) return null;
    if (gyrEvents.length != 500) return null;

    List<double> accMag = [];
    List<double> magMag = [];
    List<double> gyrMag = [];

    for (var i = 0; i < 500; i++) {
      accMag.add(sqrt(
        accEvents[i].x * accEvents[i].x +
            accEvents[i].y * accEvents[i].y +
            accEvents[i].z * accEvents[i].z,
      ));
      magMag.add(sqrt(
        magEvents[i].x * magEvents[i].x +
            magEvents[i].y * magEvents[i].y +
            magEvents[i].z * magEvents[i].z,
      ));
      gyrMag.add(sqrt(
        gyrEvents[i].x * gyrEvents[i].x +
            gyrEvents[i].y * gyrEvents[i].y +
            gyrEvents[i].z * gyrEvents[i].z,
      ));
    }

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
}
