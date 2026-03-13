import 'package:flutter_test/flutter_test.dart';
import 'package:bluetooth_dart_plugin/bluetooth_dart_plugin.dart';
import 'package:bluetooth_dart_plugin/bluetooth_dart_plugin_platform_interface.dart';
import 'package:bluetooth_dart_plugin/bluetooth_dart_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBluetoothDartPluginPlatform
    with MockPlatformInterfaceMixin
    implements BluetoothDartPluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final BluetoothDartPluginPlatform initialPlatform = BluetoothDartPluginPlatform.instance;

  test('$MethodChannelBluetoothDartPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBluetoothDartPlugin>());
  });

  test('getPlatformVersion', () async {
    BluetoothDartPlugin bluetoothDartPlugin = BluetoothDartPlugin();
    MockBluetoothDartPluginPlatform fakePlatform = MockBluetoothDartPluginPlatform();
    BluetoothDartPluginPlatform.instance = fakePlatform;

    expect(await bluetoothDartPlugin.getPlatformVersion(), '42');
  });
}
