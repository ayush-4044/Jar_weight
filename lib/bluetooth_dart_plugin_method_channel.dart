import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'bluetooth_dart_plugin_platform_interface.dart';

/// An implementation of [BluetoothDartPluginPlatform] that uses method channels.
class MethodChannelBluetoothDartPlugin extends BluetoothDartPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('bluetooth_dart_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
