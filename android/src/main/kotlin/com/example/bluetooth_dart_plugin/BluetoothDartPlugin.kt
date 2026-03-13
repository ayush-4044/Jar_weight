package com.example.bluetooth_dart_plugin

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import java.io.IOException
import java.util.*

class BluetoothDartPlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var methodChannel: MethodChannel
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private var connectedSocket: BluetoothSocket? = null
    private val MY_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "bluetooth_dart_plugin/method")
        methodChannel.setMethodCallHandler(this)

        val eventChannel = EventChannel(binding.binaryMessenger, "bluetooth_dart_plugin/scan")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, events: EventChannel.EventSink?) { eventSink = events }
            override fun onCancel(args: Any?) { eventSink = null }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPairedDevices" -> {
                val paired = bluetoothAdapter?.bondedDevices?.map {
                    mapOf("name" to (it.name ?: "Unknown"), "address" to it.address)
                } ?: listOf()
                result.success(paired)
            }
            "startScan" -> {
                val filter = IntentFilter(BluetoothDevice.ACTION_FOUND)
                context?.registerReceiver(object : BroadcastReceiver() {
                    override fun onReceive(context: Context?, intent: Intent?) {
                        if (BluetoothDevice.ACTION_FOUND == intent?.action) {
                            val device = intent.getParcelableExtra<BluetoothDevice>(BluetoothDevice.EXTRA_DEVICE)
                            device?.let {
                                val data = mapOf("type" to "device", "name" to (it.name ?: "Unknown"), "address" to it.address)
                                Handler(Looper.getMainLooper()).post { eventSink?.success(data) }
                            }
                        }
                    }
                }, filter)
                bluetoothAdapter?.startDiscovery()
                result.success(true)
            }
            "startServer" -> {
                Thread {
                    try {
                        val server = bluetoothAdapter?.listenUsingRfcommWithServiceRecord("ChatApp", MY_UUID)
                        val socket = server?.accept()
                        connectedSocket = socket
                        server?.close()
                        listenForMessages()
                        Handler(Looper.getMainLooper()).post { result.success("Connected") }
                    } catch (e: IOException) {
                        Handler(Looper.getMainLooper()).post { result.error("ERR", e.message, null) }
                    }
                }.start()
            }
            "connectToDevice" -> {
                val address = call.argument<String>("address")
                val device = bluetoothAdapter?.getRemoteDevice(address)
                Thread {
                    try {
                        connectedSocket = device?.createRfcommSocketToServiceRecord(MY_UUID)
                        connectedSocket?.connect()
                        listenForMessages()
                        Handler(Looper.getMainLooper()).post { result.success("Connected") }
                    } catch (e: IOException) {
                        Handler(Looper.getMainLooper()).post { result.error("ERR", e.message, null) }
                    }
                }.start()
            }
            "sendMessage" -> {
                val msg = call.argument<String>("message") ?: ""
                try {
                    connectedSocket?.outputStream?.write(msg.toByteArray())
                    result.success(true)
                } catch (e: IOException) { result.error("ERR", e.message, null) }
            }
            else -> result.notImplemented()
        }
    }

    private fun listenForMessages() {
        val buffer = ByteArray(1024)
        Thread {
            while (connectedSocket != null) {
                try {
                    val bytes = connectedSocket?.inputStream?.read(buffer) ?: -1
                    if (bytes > 0) {
                        val text = String(buffer, 0, bytes)
                        Handler(Looper.getMainLooper()).post {
                            eventSink?.success(mapOf("type" to "message", "text" to text))
                        }
                    }
                } catch (e: IOException) { break }
            }
        }.start()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        connectedSocket?.close()
    }
}