/// The transport modes.
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

/// Descriptions for the TransportMode.
extension TransportModeDescription on TransportMode {
  /// The description of the transport mode.
  String get description {
    switch (this) {
      case TransportMode.unknown:
        return 'Unknown';
      case TransportMode.still:
        return 'Still';
      case TransportMode.walking:
        return 'Walking';
      case TransportMode.run:
        return 'Run';
      case TransportMode.bike:
        return 'Bike';
      case TransportMode.car:
        return 'Car';
      case TransportMode.bus:
        return 'Bus';
      case TransportMode.train:
        return 'Train';
      case TransportMode.subway:
        return 'Subway';
    }
  }
}
