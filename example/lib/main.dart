import 'package:flutter/material.dart';
import 'dart:async';

import 'package:tmd/classes.dart';
import 'package:tmd/tmd.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// A custom line painter for the IMU data.
class LinePainter extends CustomPainter {
  /// The IMU data to draw.
  final List<double> data;

  /// The color of the line.
  final Color color;

  /// The maximum value of the data.
  final double max;

  /// The minimum value of the data.
  final double min;

  /// Create a new line painter.
  LinePainter({
    required this.data,
    required this.color,
    required this.max,
    required this.min,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final n = data.length;
    final dx = width / (n - 1);
    final dy = height / (max - min);
    for (var i = 0; i < n; i++) {
      final x = i * dx;
      final y = height - (data[i] - min) * dy;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LinePainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

const colorMapping = {
  TransportMode.unknown: Colors.grey,
  TransportMode.still: Colors.blue,
  TransportMode.walking: Colors.orange,
  TransportMode.run: Colors.red,
  TransportMode.bike: Colors.green,
  TransportMode.car: Colors.purple,
  TransportMode.bus: Colors.yellow,
  TransportMode.train: Colors.pink,
  TransportMode.subway: Colors.teal,
};

const iconMapping = {
  TransportMode.unknown: Icons.help,
  TransportMode.still: Icons.accessibility_new,
  TransportMode.walking: Icons.directions_walk,
  TransportMode.run: Icons.directions_run,
  TransportMode.bike: Icons.directions_bike,
  TransportMode.car: Icons.directions_car,
  TransportMode.bus: Icons.directions_bus,
  TransportMode.train: Icons.train,
  TransportMode.subway: Icons.subway,
};

class _MyAppState extends State<MyApp> {
  /// The transport mode to display.
  TransportMode _currentTransportMode = TransportMode.unknown;

  /// The transport mode detection object.
  final TMD _tmd = TMD();

  /// The last transport modes.
  final List<TransportMode?> _modesLog = [];

  /// The timestamps when the last transport mode was detected.
  final List<DateTime> _timeLog = [];

  /// A callback for when the transport mode changes.
  void _onTransportModeChange(TransportMode? newMode) {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    final mode = newMode ?? TransportMode.unknown;

    _modesLog.add(mode);
    _timeLog.add(DateTime.now());
    while (_modesLog.length > 20 || _timeLog.length > 20) {
      _modesLog.removeAt(0);
      _timeLog.removeAt(0);
    }

    setState(() => _currentTransportMode = mode);
  }

  @override
  void initState() {
    super.initState();
    initTransportModeDetection();
  }

  Future<void> initTransportModeDetection() async {
    // TMD starts listening to the IMU sensors and
    // looks for a changing transport mode.
    final stream = await _tmd.startListeningForChanges(
      // Notify only if a new transport mode was detected that many
      // consecutive times. This will improve the stability at the
      // expense of a less frequent notification.
      nChangedForNotification: 5,
      // The inference period defines how often the transport mode
      // is inferred. This will also affect the notification frequency.
      // Note that the inference period also impacts the battery life.
      // It is recommended to not go below 0.5 seconds.
      inferencePeriod: const Duration(milliseconds: 1000),
    );
    stream.listen(_onTransportModeChange);
  }

  @override
  void dispose() {
    super.dispose();
    // Stop listening to the IMU sensors and discard the TFLite model.
    _tmd.stopListeningForChanges();
  }

  @override
  Widget build(BuildContext context) {
    var columnElements = <Widget>[];

    for (var i = _modesLog.length - 1; i >= 0; i--) {
      final mode = _modesLog[i];
      final time = _timeLog[i];

      columnElements.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: i == _modesLog.length - 1
                ? colorMapping[mode]!.withOpacity(0.1)
                : colorMapping[mode]!.withOpacity(0.1),
          ),
          child: Row(
            children: [
              Icon(
                iconMapping[mode],
                color: colorMapping[mode],
              ),
              const SizedBox(width: 4),
              Text(
                mode?.description ?? 'unknown',
                style: TextStyle(
                  color: colorMapping[mode],
                  fontSize: 20,
                ),
              ),
              Expanded(child: Container()),
              Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      );

      if (i != 0) {
        final timediffInS = -(_timeLog[i - 1].difference(time).inSeconds);
        // Scale between 0 and 600s.
        double scaledTimediffInS = (timediffInS / 600).clamp(0, 1);
        double height = 24 + (100 * scaledTimediffInS);
        columnElements.add(
          Row(
            children: [
              Container(
                height: height,
                width: 4,
                margin: const EdgeInsets.only(left: 22, top: 4, bottom: 4),
                decoration: BoxDecoration(
                  color: colorMapping[_modesLog[i - 1]]!.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  'for $timediffInS seconds',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: colorMapping[_currentTransportMode],
          title: const Text(
            'Detecting transport mode...',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: columnElements),
        ),
      ),
    );
  }
}
