import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';
import 'package:tmd/classifier.dart';

import 'tmd_platform_interface.dart';

class Tmd {
  /// The last detected transport modes.
  static List<TransportMode?>? _lastDetectedModes;

  /// The stream controller that returns TM changes to the outside.
  static StreamController<TransportMode?>? _streamController;

  /// The current accelerometer stream subscription.
  static Stream<AccelerometerEvent>? _accStream;

  /// The last `_queueLength` accelerometer events.
  static List<AccelerometerEvent>? _accEvents;

  /// The current gyro stream subscription.
  static Stream<GyroscopeEvent>? _gyrStream;

  /// The last `_queueLength` gyroscope events.
  static List<GyroscopeEvent>? _gyrEvents;

  /// The current magnetometer stream subscription.
  static Stream<MagnetometerEvent>? _magStream;

  /// The last `_queueLength` magnetometer events.
  static List<MagnetometerEvent>? _magEvents;

  /// The inference timer
  static Timer? _inferenceTimer;

  /// The TFLite model interpreter.
  static TmdClassifier? _classifier;

  static List<StreamSubscription<dynamic>>? _streamSubscriptions;

  /// Get the platform version.
  Future<String?> getPlatformVersion() =>
      TmdPlatform.instance.getPlatformVersion();

  /// Start listening for transport mode changes.
  static Future<Stream> startListeningForChanges({
    int nChangedForNotification = 5,
    Duration inferencePeriod = const Duration(seconds: 1),
  }) async {
    assert(nChangedForNotification > 0);
    assert(inferencePeriod.inMilliseconds > 0);

    // Clear all events.
    _lastDetectedModes = [];
    _accEvents = [];
    _gyrEvents = [];
    _magEvents = [];

    // Load the TFLite model interpreter.
    _classifier = await TmdClassifier.create();

    // We need ~100Hz sampling rate.
    const samplingPeriod = Duration(milliseconds: 10);

    // Start collecting IMU data.
    _accStream = accelerometerEventStream(samplingPeriod: samplingPeriod);
    _gyrStream = gyroscopeEventStream(samplingPeriod: samplingPeriod);
    _magStream = magnetometerEventStream(samplingPeriod: samplingPeriod);

    _streamSubscriptions = [
      _accStream!.listen((event) => _onAccEvent(event)),
      _gyrStream!.listen((event) => _onGyrEvent(event)),
      _magStream!.listen((event) => _onMagEvent(event)),
    ];

    // Create a stream to return.
    _streamController = StreamController<TransportMode?>();
    _inferenceTimer = Timer.periodic(inferencePeriod, (timer) async {
      if (_accEvents == null || _gyrEvents == null || _magEvents == null) {
        return;
      }
      final tm = await _classifier?.classify(
        accEvents: _accEvents!,
        magEvents: _magEvents!,
        gyrEvents: _gyrEvents!,
      );

      // Add to detected modes.
      _lastDetectedModes?.add(tm?.classLabel);

      // Notify only if the last `nChangedForNotification` modes
      // are the same, and the one before is different.
      if (_lastDetectedModes!.length < nChangedForNotification + 1) return;
      final lastN = _lastDetectedModes!.sublist(
        _lastDetectedModes!.length - nChangedForNotification,
      );
      final lastNSet = lastN.toSet();
      if (lastNSet.length != 1) return;
      if (_lastDetectedModes![
              _lastDetectedModes!.length - nChangedForNotification - 1] ==
          tm?.classLabel) return;

      // Notify.
      _streamController?.add(tm?.classLabel);
    });

    return _streamController!.stream;
  }

  /// Handle accelerometer events.
  static void _onAccEvent(AccelerometerEvent event) {
    if (_accEvents == null) return;
    if (_accEvents!.length < 500) {
      _accEvents!.add(event);
    } else {
      _accEvents!.removeAt(0);
      _accEvents!.add(event);
    }
  }

  /// Handle gyro events.
  static void _onGyrEvent(GyroscopeEvent event) {
    if (_gyrEvents == null) return;
    if (_gyrEvents!.length < 500) {
      _gyrEvents!.add(event);
    } else {
      _gyrEvents!.removeAt(0);
      _gyrEvents!.add(event);
    }
  }

  /// Handle magnetometer events.
  static void _onMagEvent(MagnetometerEvent event) {
    if (_magEvents == null) return;
    if (_magEvents!.length < 500) {
      _magEvents!.add(event);
    } else {
      _magEvents!.removeAt(0);
      _magEvents!.add(event);
    }
  }

  /// Stop listening for transport mode changes.
  static Future<void> stopListeningForChanges() async {
    _streamSubscriptions?.forEach((subscription) => subscription.cancel());
    _classifier?.close();
    _inferenceTimer?.cancel();
    _streamController?.close();
  }
}
