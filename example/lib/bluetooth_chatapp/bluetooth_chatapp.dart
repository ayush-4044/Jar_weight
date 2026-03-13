import 'package:bluetooth_dart_plugin/bluetooth_dart_plugin.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothApp extends StatefulWidget {
  const BluetoothApp({super.key});
  @override
  State<BluetoothApp> createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  List<Map<dynamic, dynamic>> paired = [];
  List<Map<dynamic, dynamic>> available = [];
  List<Map<String, dynamic>> messages = [];
  bool isConnected = false;
  String status = "Idle";
  final TextEditingController _controller = TextEditingController();

  // 1. Auto-scroll mate ScrollController add karyo
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _setupListener();
  }

  // 2. Scroll ne bottom sudhi lai javanu function
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _setupListener() {
    BluetoothDartPlugin.scanStream.listen((event) {
      if (event['type'] == 'message') {
        setState(() => messages.add({"text": event['text'], "isMe": false}));
        _scrollToBottom();
      } else if (event['type'] == 'device') {
        setState(() {
          if (!available.any((d) => d['address'] == event['address'])) {
            available.add(event);
          }
        });
      }
    });
  }

  Future<void> _checkPermissions() async {
    await [Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location].request();
    _refreshPaired();
  }

  Future<void> _refreshPaired() async {
    final list = await BluetoothDartPlugin.getPairedDevices();
    setState(() => paired = list);
  }

  @override
  Widget build(BuildContext context) {
    if (isConnected) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Chat: $status"),
          actions: [
            IconButton(
              icon: const Icon(Icons.exposure_zero),
              tooltip: "Calibrate Zero Test",
              onPressed: () {
                BluetoothDartPlugin.sendMessage("Z");
                setState(() => messages.add({"text": "Sent Command: Z", "isMe": true}));
                _scrollToBottom();
              },
            )
          ],
        ),
        body: Column(children: [
          Expanded(
              child: ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (c, i) => _buildChatBubble(i)
              )
          ),
          _chatInput(),
        ]),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("BT: $status"),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshPaired),
            IconButton(icon: const Icon(Icons.sensors), onPressed: () async {
              setState(() => status = "Waiting...");
              await BluetoothDartPlugin.startServer();
              setState(() { isConnected = true; status = "Connected"; });
            }),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "PAIRED", icon: Icon(Icons.bluetooth_connected)),
              Tab(text: "AVAILABLE", icon: Icon(Icons.search)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _list(paired),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () => BluetoothDartPlugin.startScan(),
                    icon: const Icon(Icons.search),
                    label: const Text("Scan for Devices"),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
                  ),
                ),
                _list(available),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(int i) {
    return ListTile(
      title: Align(
        alignment: messages[i]['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: messages[i]['isMe'] ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(10)),
          child: Text(messages[i]['text'], style: TextStyle(color: messages[i]['isMe'] ? Colors.white : Colors.black)),
        ),
      ),
    );
  }

  Widget _list(List<Map<dynamic, dynamic>> l) => Expanded(child: ListView.builder(itemCount: l.length, itemBuilder: (c, i) => ListTile(
    leading: const Icon(Icons.bluetooth),
    title: Text(l[i]['name']),
    subtitle: Text(l[i]['address']),
    onTap: () async {
      setState(() => status = "Connecting...");
      await BluetoothDartPlugin.connectToDevice(l[i]['address']);
      setState(() { isConnected = true; status = "Connected"; });
    },
  )));

  Widget _chatInput() => Padding(padding: const EdgeInsets.all(8), child: Row(children: [
    Expanded(child: TextField(controller: _controller)),
    IconButton(icon: const Icon(Icons.send), onPressed: () {
      BluetoothDartPlugin.sendMessage(_controller.text);
      setState(() => messages.add({"text": _controller.text, "isMe": true}));
      _controller.clear();
      _scrollToBottom();
    })
  ]));
}



// import 'package:bluetooth_dart_plugin/bluetooth_dart_plugin.dart';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class BluetoothApp extends StatefulWidget {
//   const BluetoothApp({super.key});
//   @override
//   State<BluetoothApp> createState() => _BluetoothAppState();
// }
//
// class _BluetoothAppState extends State<BluetoothApp> {
//   List<Map<dynamic, dynamic>> paired = [];
//   List<Map<dynamic, dynamic>> available = [];
//   List<Map<String, dynamic>> messages = [];
//   bool isConnected = false;
//   String status = "Idle";
//   final TextEditingController _controller = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _checkPermissions();
//     _setupListener();
//   }
//
//   // --- Logic remains unchanged ---
//   void _setupListener() {
//     BluetoothDartPlugin.scanStream.listen((event) {
//       if (event['type'] == 'message') {
//         setState(() => messages.add({"text": event['text'], "isMe": false}));
//       } else if (event['type'] == 'device') {
//         setState(() {
//           if (!available.any((d) => d['address'] == event['address'])) {
//             available.add(event);
//           }
//         });
//       }
//     });
//   }
//
//   Future<void> _checkPermissions() async {
//     await [Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location].request();
//     _refreshPaired();
//   }
//
//   Future<void> _refreshPaired() async {
//     final list = await BluetoothDartPlugin.getPairedDevices();
//     setState(() => paired = list);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // If connected, show the chat screen
//     if (isConnected) {
//       return Scaffold(
//         appBar: AppBar(title: Text("Chat: $status")),
//         body: Column(children: [
//           Expanded(child: ListView.builder(itemCount: messages.length, itemBuilder: (c, i) => _buildChatBubble(i))),
//           _chatInput(),
//         ]),
//       );
//     }
//
//     // If not connected, show the Tabbed Device Picker
//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text("BT: $status"),
//           actions: [
//             IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshPaired),
//             IconButton(icon: const Icon(Icons.sensors), onPressed: () async {
//               setState(() => status = "Waiting...");
//               await BluetoothDartPlugin.startServer();
//               setState(() { isConnected = true; status = "Connected"; });
//             }),
//           ],
//           bottom: const TabBar(
//             tabs: [
//               Tab(text: "PAIRED", icon: Icon(Icons.bluetooth_connected)),
//               Tab(text: "AVAILABLE", icon: Icon(Icons.search)),
//             ],
//           ),
//         ),
//         body: TabBarView(
//           children: [
//             // Tab 1: Paired Devices
//             _list(paired),
//
//             // Tab 2: Available Devices with Scan Button
//             Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: ElevatedButton.icon(
//                     onPressed: () => BluetoothDartPlugin.startScan(),
//                     icon: const Icon(Icons.search),
//                     label: const Text("Scan for Devices"),
//                     style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
//                   ),
//                 ),
//                 _list(available),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Helper for chat bubbles
//   Widget _buildChatBubble(int i) {
//     return ListTile(
//       title: Align(
//         alignment: messages[i]['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
//         child: Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//               color: messages[i]['isMe'] ? Colors.blue : Colors.grey[300],
//               borderRadius: BorderRadius.circular(10)),
//           child: Text(messages[i]['text'], style: TextStyle(color: messages[i]['isMe'] ? Colors.white : Colors.black)),
//         ),
//       ),
//     );
//   }
//
//   // Existing list builder used in both tabs
//   Widget _list(List<Map<dynamic, dynamic>> l) => Expanded(child: ListView.builder(itemCount: l.length, itemBuilder: (c, i) => ListTile(
//     leading: const Icon(Icons.bluetooth),
//     title: Text(l[i]['name']),
//     subtitle: Text(l[i]['address']),
//     onTap: () async {
//       setState(() => status = "Connecting...");
//       await BluetoothDartPlugin.connectToDevice(l[i]['address']);
//       setState(() { isConnected = true; status = "Connected"; });
//     },
//   )));
//
//   Widget _chatInput() => Padding(padding: const EdgeInsets.all(8), child: Row(children: [
//     Expanded(child: TextField(controller: _controller)),
//     IconButton(icon: const Icon(Icons.send), onPressed: () {
//       BluetoothDartPlugin.sendMessage(_controller.text);
//       setState(() => messages.add({"text": _controller.text, "isMe": true}));
//       _controller.clear();
//     })
//   ]));
// }
