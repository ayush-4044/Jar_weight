import 'dart:async';
import 'package:bluetooth_dart_plugin/bluetooth_dart_plugin.dart';
import 'package:bluetooth_dart_plugin_example/utils/colors.dart';
import 'package:bluetooth_dart_plugin_example/utils/texts.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../model/jar_model.dart';
import 'add_jar_card.dart';
import 'jar_card.dart';
import 'live_weight_popup.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<JarModel> jarList = [];
  bool isConnecting = false;
  StreamSubscription? _disconnectListener;
  Timer? _connectionTimeout;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    requestPermissions();
    loadJar();
    _listenForDisconnect();

  }

  // --- Request Bluetooth & Location Permissions ---
  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothConnect]!.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bluetooth permission is required. Please enable it in Settings."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleDeviceDisconnect() {
    if (mounted && BluetoothDartPlugin.isDeviceConnected) {
      setState(() {
        BluetoothDartPlugin.isDeviceConnected = false;
      });
      _connectionTimeout?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Device Disconnected!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _resetConnectionTimer() {
    _connectionTimeout?.cancel();

    _connectionTimeout = Timer(const Duration(seconds: 4), () {
      _handleDeviceDisconnect();
    });
  }

  void _listenForDisconnect() {
    _disconnectListener = BluetoothDartPlugin.scanStream.listen((event) {
      if (event['type'] == 'disconnected' || event['state'] == 'disconnected') {
        _handleDeviceDisconnect();
      }
      else if (event['type'] == 'message') {
        if (BluetoothDartPlugin.isDeviceConnected) {
          _resetConnectionTimer();
        }
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _disconnectListener?.cancel();
    _connectionTimeout?.cancel();
    super.dispose();
  }

  // --- Load Saved Jars from SharedPreferences ---
  Future<void> loadJar() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList("jar_list") ?? [];
    setState(() {
      jarList = savedList.map((e) => JarModel.fromJson(e)).toList();
    });
  }

  // --- Bluetooth Connection Bottom Sheet ---
  Future<void> connectBluetooth() async {
    setState(() => isConnecting = true);

    try {
      List<Map<dynamic, dynamic>> paired = await BluetoothDartPlugin.getPairedDevices();
      setState(() => isConnecting = false);

      if (paired.isNotEmpty) {
        if (!mounted) return;

        // Responsive fix: Use constraints for bottom sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Select Weight Machine",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: paired.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.bluetooth, color: Color(0xFF1F7A63)),
                            title: Text(paired[index]['name']),
                            subtitle: Text(paired[index]['address']),
                            onTap: () async {
                              Navigator.pop(context);
                              setState(() => isConnecting = true);

                              try {
                                await BluetoothDartPlugin.connectToDevice(paired[index]['address']);
                                setState(() {
                                  BluetoothDartPlugin.isDeviceConnected = true;
                                  isConnecting = false;
                                });
                                _resetConnectionTimer();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Bluetooth Connected Successfully!"),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() => isConnecting = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Connection failed: $e")),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No paired Bluetooth devices found!"),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() => isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error fetching devices: $e"),
            duration: const Duration(seconds: 1),
          )
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // Media Query for responsive sizing
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        toolbarHeight: height * 0.11, // Responsive App Bar height (11% of screen)
        backgroundColor: ColorString.appBarColor,
        title: const Text(
          "My Pantry",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 22),
        ),
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: ColorString.appBarLeadingColor, width: 2),
            ),
            child: Center(child: Image.asset("assets/images/user.png", fit: BoxFit.cover)),
          ),
        ),
        actions: [

          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.white),
            onSelected: (value) {
              if (value == 'disconnect') {
                _handleDeviceDisconnect();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (BluetoothDartPlugin.isDeviceConnected)
                const PopupMenuItem<String>(
                  value: 'disconnect',
                  child: Row(
                    children: [
                      Icon(Icons.bluetooth_disabled, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Disconnect Device', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                )
              else
                const PopupMenuItem<String>(
                  enabled: false,
                  value: 'none',
                  child: Text('No device connected', style: TextStyle(color: Colors.grey)),
                ),
            ],
          ),
        ],
      ),

      // --- Bottom Navigation / Connect Button ---
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom > 0 ? 20 : 30,
          left: 15,
          right: 15,
          top: 10,
        ),
        child: BluetoothDartPlugin.isDeviceConnected
            ? Container(
          height: 50,
          decoration: BoxDecoration(
            color: ColorString.appBarLeadingColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bluetooth_connected, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Device Connected",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        )
            : OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            side: const BorderSide(color: Color(0xFF1F7A63), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: isConnecting ? null : connectBluetooth,
          child: isConnecting
              ? const SizedBox(
            height: 20, width: 20,
            child: CircularProgressIndicator(color: ColorString.appBarLeadingColor, strokeWidth: 2),
          )
              : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bluetooth, color: Color(0xFF1F7A63), size: 22),
              SizedBox(width: 10),
              Text(
                "Connect Bluetooth",
                style: TextStyle(color: Color(0xFF1F7A63), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(Texts.line1, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: width > 600 ? 1.5 : (height > 800 ? 0.95 : 1.10),
                ),
                itemCount: jarList.length + 1,
                itemBuilder: (context, index) {
                  if (index == jarList.length) {
                    return AddJarCard(onJarAdded: loadJar);
                  }

                  JarModel jar = jarList[index];
                  double percent = (jar.currentWeight / double.parse(jar.capacity)).clamp(0.0, 1.0);

                  Color progressColor = percent < 0.40
                      ? const Color(0xFFE14043)
                      : (percent <= 0.65 ? const Color(0xFFFDB532) : const Color(0xFF3CB340));

                  DateTime expiry = DateTime.parse(jar.expiryDate);
                  int daysLeft = expiry.difference(DateTime.now()).inDays;

                  String expiryText = daysLeft < 0 ? "Expired" : (daysLeft <= 3 ? "Expires in $daysLeft days" : "All Good");
                  bool isWarning = daysLeft <= 3;

                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) => LiveWeightPopup(
                          jar: jar,
                          jarIndex: index,
                        ),
                      ).then((value) {
                        if (value == true) loadJar();
                      });
                    },
                    child: JarCard(
                      title: jar.name,
                      weight: "${jar.currentWeight.toStringAsFixed(2)} Kg",
                      percent: percent,
                      percentText: "${(percent * 100).round()}%",
                      color: progressColor,
                      expiryText: expiryText,
                      isWarning: isWarning,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}