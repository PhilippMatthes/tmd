import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'tmd_method_channel.dart';

abstract class TmdPlatform extends PlatformInterface {
  /// Constructs a TmdPlatform.
  TmdPlatform() : super(token: _token);

  static final Object _token = Object();

  static TmdPlatform _instance = MethodChannelTmd();

  /// The default instance of [TmdPlatform] to use.
  ///
  /// Defaults to [MethodChannelTmd].
  static TmdPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TmdPlatform] when
  /// they register themselves.
  static set instance(TmdPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
