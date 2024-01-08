import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tmd_platform_interface.dart';

/// An implementation of [TmdPlatform] that uses method channels.
class MethodChannelTmd extends TmdPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tmd');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
