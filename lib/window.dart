class LinearInterpolatedWindow {
  /// The values of the window.
  final List<double> interpolatedValues = [];

  /// The sampling rate of the window, in Hz.
  final double _samplingRate = 100;

  /// The window's length, in samples.
  final double _windowLength = 500;

  /// Open values that have not been incorporated into the window yet.
  final List<(int, double)> valuesToIncorporate = [];

  /// The current raster position of the window.
  int? rasterPosition;

  /// Create a new linear interpolated window.
  /// Note: If using multiple windows, the same reference timestamp
  /// should be used for all windows.
  LinearInterpolatedWindow();

  /// Add a new (timed) value to the window.
  void add(double value) {
    final now = DateTime.now().millisecondsSinceEpoch;
    valuesToIncorporate.add((now, value));
    // If the raster position is not set yet, this is the first value.
    // In this case, set the raster just after the current time.
    final msPerSample = 1000 ~/ _samplingRate;
    rasterPosition ??= now - (now % msPerSample) + msPerSample;
    // Need at least 2 values to interpolate.
    if (valuesToIncorporate.length < 2) return;
    // Iterate the raster position forward until it is larger than the
    // timestamp of the last value to incorporate.
    Set elementsToRemove = {};
    while (rasterPosition! < valuesToIncorporate.last.$1) {
      // Find values to interpolate.
      for (var i = 0; i < valuesToIncorporate.length - 1; i++) {
        final v1 = valuesToIncorporate[i];
        final v2 = valuesToIncorporate[i + 1];
        // If the raster position is between the two values, interpolate.
        if (v1.$1 <= rasterPosition! && rasterPosition! <= v2.$1) {
          final t = (rasterPosition! - v1.$1) / (v2.$1 - v1.$1);
          final v = v1.$2 + t * (v2.$2 - v1.$2);
          interpolatedValues.add(v);
          while (interpolatedValues.length > _windowLength) {
            interpolatedValues.removeAt(0);
          }
          elementsToRemove.add(i);
          break;
        }
      }
      // Move the raster position forward.
      rasterPosition = rasterPosition! + msPerSample;
    }
    // Remove values that have been interpolated.
    valuesToIncorporate.removeRange(0, elementsToRemove.length);
  }

  /// Clear the window.
  void clear() {
    interpolatedValues.clear();
    valuesToIncorporate.clear();
    rasterPosition = null;
  }
}
