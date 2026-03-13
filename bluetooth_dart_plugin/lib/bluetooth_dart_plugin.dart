import 'dart:async';
import 'package:flutter/services.dart';

class BluetoothDartPlugin {
  static const MethodChannel _methodChannel = MethodChannel('bluetooth_dart_plugin/method');
  static const EventChannel _eventChannel = EventChannel('bluetooth_dart_plugin/scan');
  static bool isDeviceConnected = false;

  static double currentRawWeight = 0.0;
  static double tareOffset = 0.0;

  static double get finalDisplayWeight {
    double weight = currentRawWeight - tareOffset;
    return weight < 0 ? 0.0 : weight;
  }

  static void calibrateZero() {
    tareOffset = currentRawWeight;
  }

  static Stream<dynamic> get scanStream => _eventChannel.receiveBroadcastStream();

  static Future<List<Map<dynamic, dynamic>>> getPairedDevices() async {
    final List<dynamic>? devices = await _methodChannel.invokeMethod('getPairedDevices');
    return devices?.cast<Map<dynamic, dynamic>>() ?? [];
  }

  static Future<void> startScan() async => await _methodChannel.invokeMethod('startScan');

  static Future<bool> pairDevice(String address) async {
    final bool? success = await _methodChannel.invokeMethod('pairDevice', {'address': address});
    return success ?? false;
  }

  static Future<void> startServer() async => await _methodChannel.invokeMethod('startServer');

  static Future<void> connectToDevice(String address) async =>
      await _methodChannel.invokeMethod('connectToDevice', {'address': address});

  static Future<void> sendMessage(String message) async =>
      await _methodChannel.invokeMethod('sendMessage', {'message': message});
}