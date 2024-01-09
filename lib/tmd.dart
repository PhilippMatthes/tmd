import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';
import 'package:tmd/classes.dart';
import 'package:tmd/classifier.dart';
import 'package:tmd/window.dart';

class TMD {
  /// The last detected transport modes.
  final List<TransportMode?> _lastDetectedModes = [];

  /// The last notified transport modes.
  final List<TransportMode?> _lastNotifiedModes = [];

  /// The stream controller that returns TM changes to the outside.
  StreamController<TransportMode?>? _streamController;

  /// The window for the accelerometer values.
  final LinearInterpolatedWindow _accWindow = LinearInterpolatedWindow();

  /// The window for the gyro values.
  final LinearInterpolatedWindow _gyrWindow = LinearInterpolatedWindow();

  /// The window for the magnetometer values.
  final LinearInterpolatedWindow _magWindow = LinearInterpolatedWindow();

  /// The inference timer
  Timer? _inferenceTimer;

  /// The TFLite model interpreter.
  TmdClassifier? _classifier;

  /// The stream subscriptions to the IMU sensors.
  List<StreamSubscription> _streamSubscriptions = [];

  /// Create a new handle to the TMD.
  TMD();

  /// Start listening for transport mode changes.
  Future<Stream<TransportMode?>> startListeningForChanges({
    int nChangedForNotification = 5,
    Duration inferencePeriod = const Duration(seconds: 1),
  }) async {
    assert(nChangedForNotification > 0);
    assert(nChangedForNotification < 500);
    assert(inferencePeriod.inMilliseconds > 0);

    // Clear all events.
    _lastDetectedModes.clear();
    _lastNotifiedModes.clear();
    _accWindow.clear();
    _gyrWindow.clear();
    _magWindow.clear();

    // Load the TFLite model interpreter.
    _classifier = await TmdClassifier.create();

    // Start collecting IMU data at ~100Hz.
    const samplingPeriod = Duration(milliseconds: 10);
    _streamSubscriptions = [
      accelerometerEventStream(samplingPeriod: samplingPeriod)
          .listen((event) => _onAccEvent(event)),
      gyroscopeEventStream(samplingPeriod: samplingPeriod)
          .listen((event) => _onGyrEvent(event)),
      magnetometerEventStream(samplingPeriod: samplingPeriod)
          .listen((event) => _onMagEvent(event)),
    ];

    // Create a stream to return.
    _streamController = StreamController<TransportMode?>();
    _inferenceTimer = Timer.periodic(inferencePeriod, (timer) async {
      final tm = await _classifier?.classify(
        accMag: _accWindow.interpolatedValues,
        magMag: _magWindow.interpolatedValues,
        gyrMag: _gyrWindow.interpolatedValues,
      );

      // Add to detected modes.
      _lastDetectedModes.add(tm?.classLabel);
      while (_lastDetectedModes.length > 500) {
        _lastDetectedModes.removeAt(0); // Just to not run out of memory.
      }

      // Notify only if the last `nChangedForNotification` modes are the same.
      if (_lastDetectedModes.length < nChangedForNotification + 1) return;
      final lastN = _lastDetectedModes.sublist(
        _lastDetectedModes.length - nChangedForNotification,
      );
      final lastNSet = lastN.toSet();
      if (lastNSet.length != 1) return;

      // Notify only if this mode is different from the last notified mode.
      if (_lastNotifiedModes.isNotEmpty &&
          _lastNotifiedModes.last == lastNSet.first) return;

      // Notify.
      _streamController?.add(tm?.classLabel);
      _lastNotifiedModes.add(tm?.classLabel);
    });

    return _streamController!.stream;
  }

  /// Handle accelerometer events.
  void _onAccEvent(AccelerometerEvent event) {
    _accWindow
        .add(sqrt(event.x * event.x + event.y * event.y + event.z * event.z));
  }

  /// Handle gyro events.
  void _onGyrEvent(GyroscopeEvent event) {
    _gyrWindow
        .add(sqrt(event.x * event.x + event.y * event.y + event.z * event.z));
  }

  /// Handle magnetometer events.
  void _onMagEvent(MagnetometerEvent event) {
    _magWindow
        .add(sqrt(event.x * event.x + event.y * event.y + event.z * event.z));
  }

  /// Stop listening for transport mode changes.
  Future<void> stopListeningForChanges() async {
    for (var subscription in _streamSubscriptions) {
      await subscription.cancel();
    }
    _classifier?.close();
    _inferenceTimer?.cancel();
    _streamController?.close();
    _streamSubscriptions.clear();
    _lastDetectedModes.clear();
    _lastNotifiedModes.clear();
    _accWindow.clear();
    _gyrWindow.clear();
    _magWindow.clear();
  }
}
