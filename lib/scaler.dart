import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

mixin Scaler {
  List<double> transform(List<double> features);
}

class StandardScaler with Scaler {
  /// The standard deviation of the features.
  List<double> scales;

  /// The mean of the features.
  List<double> means;

  StandardScaler({
    required this.scales,
    required this.means,
  });

  /// Load the StandardScaler from a JSON config.
  factory StandardScaler.fromJson(Map<String, dynamic> json) {
    return StandardScaler(
      scales: List<double>.from(json['scales']),
      means: List<double>.from(json['means']),
    );
  }

  /// Load a StandardScaler from a file.
  static Future<StandardScaler> load(String path) async {
    final file = await rootBundle.loadString(path);
    final json = jsonDecode(file);
    return StandardScaler.fromJson(json);
  }

  /// Scale the features.
  @override
  List<double> transform(List<double> features) {
    final scaledFeatures = <double>[];
    for (var i = 0; i < features.length; i++) {
      scaledFeatures.add((features[i] - means[i]) / scales[i]);
    }
    return scaledFeatures;
  }
}

class PowerTransformer with Scaler {
  /// The lambdas of the features.
  List<double> lambdas;

  PowerTransformer({
    required this.lambdas,
  });

  /// Load the PowerTransformer from a JSON config.
  factory PowerTransformer.fromJson(Map<String, dynamic> json) {
    return PowerTransformer(
      lambdas: List<double>.from(json['lambdas']),
    );
  }

  /// Load a PowerTransformer from a file.
  static Future<PowerTransformer> load(String path) async {
    final file = await rootBundle.loadString(path);
    final json = jsonDecode(file);
    return PowerTransformer.fromJson(json);
  }

  /// Transform the features.
  @override
  List<double> transform(List<double> features) {
    final transformedFeatures = <double>[];
    for (var i = 0; i < features.length; i++) {
      final lambda = lambdas[i];

      if (lambda != 0 && features[i] >= 0) {
        transformedFeatures.add((pow(features[i] + 1, lambda) - 1) / lambda);
      } else if (lambda == 0 && features[i] >= 0) {
        transformedFeatures.add(log(features[i] + 1));
      } else if (lambda != 2 && features[i] < 0) {
        transformedFeatures
            .add(-((pow((-features[i] + 1), 2 - lambda) - 1)) / (2 - lambda));
      } else {
        transformedFeatures.add(-log(-features[i] + 1));
      }
    }
    return transformedFeatures;
  }
}
