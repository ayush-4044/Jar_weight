import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bluetooth_dart_plugin_method_channel.dart';

abstract class BluetoothDartPluginPlatform extends PlatformInterface {
  /// Constructs a BluetoothDartPluginPlatform.
  BluetoothDartPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static BluetoothDartPluginPlatform _instance = MethodChannelBluetoothDartPlugin();

  /// The default instance of [BluetoothDartPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelBluetoothDartPlugin].
  static BluetoothDartPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BluetoothDartPluginPlatform] when
  /// they register themselves.
  static set instance(BluetoothDartPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
