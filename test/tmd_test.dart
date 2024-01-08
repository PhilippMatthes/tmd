import 'package:flutter_test/flutter_test.dart';
import 'package:tmd/tmd.dart';
import 'package:tmd/tmd_platform_interface.dart';
import 'package:tmd/tmd_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockTmdPlatform with MockPlatformInterfaceMixin implements TmdPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final TmdPlatform initialPlatform = TmdPlatform.instance;

  test('$MethodChannelTmd is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTmd>());
  });

  test('getPlatformVersion', () async {
    Tmd tmdPlugin = Tmd();
    MockTmdPlatform fakePlatform = MockTmdPlatform();
    TmdPlatform.instance = fakePlatform;

    expect(await tmdPlugin.getPlatformVersion(), '42');
  });

  test('initializes the model', () async {
    await Tmd.init();
  });
}
