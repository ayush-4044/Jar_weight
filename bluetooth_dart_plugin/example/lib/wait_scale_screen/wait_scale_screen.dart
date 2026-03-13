import 'dart:async';
import 'package:bluetooth_dart_plugin/bluetooth_dart_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../model/jar_model.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class WaitScaleScreen extends StatefulWidget {
  final String itemName;
  final double totalWeight;
  final DateTime expiryDate;

  const WaitScaleScreen({
    super.key,
    required this.itemName,
    required this.totalWeight,
    required this.expiryDate,
  });

  @override
  State<WaitScaleScreen> createState() => _WaitScaleScreenState();
}

class _WaitScaleScreenState extends State<WaitScaleScreen> {
  StreamSubscription? _btSubscription;
  double currentWeight = 0.0;
  int _zeroCount = 0;
  final TextEditingController weightController = TextEditingController();

  bool isItemError = false;
  bool isDateError = false;
  bool isDateError1 = false;

  DateTime? selectedDate = DateTime.now();
  late DateTime selectedDate1;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    selectedDate1 = widget.expiryDate;
    _listenToLiveWeight();

  }

  // --- Listen to Bluetooth Live Weight Data ---
  void _listenToLiveWeight() {
    _btSubscription = BluetoothDartPlugin.scanStream.listen((event) {
      if (event['type'] == 'disconnected' || event['state'] == 'disconnected') {
        if (mounted) {
          setState(() {
            BluetoothDartPlugin.isDeviceConnected = false;
          });
        }
      } else if (event['type'] == 'message') {
        String rawText = event['text'].toString().trim();

        List<String> parts = rawText.split(' ');
        if (parts.isNotEmpty) {
          double weightInGrams = double.tryParse(parts[0]) ?? 0.0;

          if (weightInGrams <= 2.0) {
            _zeroCount++;

            if (_zeroCount >= 3) {
              if (mounted) {
                setState(() {
                  currentWeight = 0.0;
                  weightController.text = "0.000";
                });
              }
            }
          } else {
            _zeroCount = 0;

          if (mounted) {
            setState(() {
              currentWeight = double.parse((weightInGrams / 1000.0).toStringAsFixed(4));
              weightController.text = currentWeight.toStringAsFixed(3);
            });
          }
        }
      }
    }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _btSubscription?.cancel();
    weightController.dispose();
    super.dispose();
  }

  // --- Save Jar Details to Local Storage ---
  Future<void> saveJar() async {
    if (selectedDate == null) {
      setState(() { isDateError = true; });
      return;
    }
    if (currentWeight < 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Weight cannot be negative!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    if (currentWeight == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please place the item on the scale to get weight before saving!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (currentWeight > widget.totalWeight) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Overweight! Current weight (${currentWeight.toStringAsFixed(2)} Kg) exceeds jar capacity (${widget.totalWeight.toStringAsFixed(2)} Kg)."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jarList = prefs.getStringList("jar_list") ?? [];

    JarModel jar = JarModel(
      name: widget.itemName,
      capacity: widget.totalWeight.toString(),
      expiryDate: selectedDate1.toIso8601String(),
      addedOn: selectedDate!.toIso8601String(),
      currentWeight: currentWeight,
    );

    jarList.add(jar.toJson());
    await prefs.setStringList("jar_list", jarList);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isConnected = BluetoothDartPlugin.isDeviceConnected;

    bool isOverweight = currentWeight > widget.totalWeight;
    Color ringColor = isOverweight ? Colors.red : const Color(0xFF1F7A63);

    double percent = currentWeight / widget.totalWeight;
    percent = percent.clamp(0.0, 1.0);

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
        // Changed to percentage height for consistent look
        toolbarHeight: height * 0.11,
        backgroundColor: ColorString.appBarColor,
        title: Text(
          widget.itemName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        // Used fixed width to prevent layout issues on larger screens like tablets
        leadingWidth: 60,
        titleSpacing: 0,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        ),
        actionsPadding: const EdgeInsets.only(right: 15),
      ),

      // --- Bottom Navigation Save Button ---
      bottomNavigationBar: Padding(
        // Added safe area logic for iOS bottom notch
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom > 0 ? 20 : 30,
          left: 15,
          right: 15,
          top: 10,
        ),
        child: InkWell(
          // onTap: saveJar,

          onTap: isConnected ? saveJar : () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Cannot save! Please connect Bluetooth to get weight."),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: isConnected ? ColorString.appBarLeadingColor : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Color(0xFF2F3E46), offset: Offset(0, 2))],
            ),
            child: const Center(
              child: Text(
                "Save & Back to Home",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFFFFFF)),
              ),
            ),
          ),
        ),
      ),

      // SafeArea added for the main body
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Connection Warning
                if (!isConnected)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade300)
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bluetooth_disabled, color: Colors.red),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Bluetooth is disconnected! You cannot add this item without capturing weight.",
                            style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                /// Circular Progress Bar
                Center(
                  child: SizedBox(
                    height: 180,
                    width: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        /// Background Ring
                        SizedBox(
                          height: 160,
                          width: 160,
                          child: CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 22,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD9D9D9)),
                          ),
                        ),

                        /// Active Progress Ring
                        SizedBox(
                          height: 160,
                          width: 160,
                          child: CircularProgressIndicator(
                            value: percent,
                            strokeWidth: 22,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                          ),
                        ),

                        /// Center Value Display
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${currentWeight.toStringAsFixed(2)} Kg",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2F3E46),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.totalWeight < 1.0
                                  ? "of ${(widget.totalWeight * 1000).toInt()} g"
                                  : "of ${widget.totalWeight.toStringAsFixed(2).replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "")} Kg",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF949494),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// Percentage Text
                Center(
                  child: Text(
                    "${(percent * 100).toInt()}% Remaining",
                    style: const TextStyle(fontSize: 14, color: Color(0xFF949494)),
                  ),
                ),

                const SizedBox(height: 30),

                /// Current Weight Input Display
                const Text(
                  "Current Weight",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF949494),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(offset: Offset(0, 2), blurRadius: 1, color: Color(0xFFCACACA)),
                      BoxShadow(offset: Offset(0, 0), blurRadius: 1, color: Color(0xFFCACACA)),
                    ],
                  ),
                  child: TextField(
                    controller: weightController,
                    readOnly: true,
                    // readOnly: false,
                    onChanged: (value){
                      setState(() {
                        currentWeight = double.tryParse(value)?? 0.0;
                      });
                    },
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: "Waiting for weight...",
                      hintStyle: TextStyle(color: Color(0xFF949494)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (currentWeight > widget.totalWeight)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          "Overweight! Capacity is only ${widget.totalWeight} Kg",
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w600
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 15),

                /// Added On Date Picker
                const Text(
                  "Added On",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF949494),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );

                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                        isDateError = false;
                      });
                    }
                  },
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(offset: Offset(0, 2), blurRadius: 1, color: Color(0xFFCACACA)),
                        BoxShadow(offset: Offset(0, 0), blurRadius: 1, color: Color(0xFFCACACA)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate == null
                              ? "dd / mm / yyyy"
                              : "${selectedDate!.day.toString().padLeft(2, '0')} / "
                              "${selectedDate!.month.toString().padLeft(2, '0')} / "
                              "${selectedDate!.year}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: selectedDate == null ? const Color(0xFFB2B2B2) : const Color(0xFF2F3E46),
                          ),
                        ),
                        const Icon(Icons.calendar_month, color: Color(0xFFB2B2B2)),
                      ],
                    ),
                  ),
                ),

                if (isDateError)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 8),
                    child: Text("Please select added date", style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),

                const SizedBox(height: 15),

                /// Expiry Date Picker
                const Text(
                  "Expiry Date",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF949494),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate1,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );

                    if (picked != null) {
                      setState(() {
                        selectedDate1 = picked;
                        isDateError1 = false;
                      });
                    }
                  },
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(offset: Offset(0, 2), blurRadius: 1, color: Color(0xFFCACACA)),
                        BoxShadow(offset: Offset(0, 0), blurRadius: 1, color: Color(0xFFCACACA)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${selectedDate1.day.toString().padLeft(2, '0')} / "
                              "${selectedDate1.month.toString().padLeft(2, '0')} / "
                              "${selectedDate1.year}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2F3E46),
                          ),
                        ),
                        const Icon(Icons.calendar_month, color: Color(0xFFB2B2B2)),
                      ],
                    ),
                  ),
                ),

                if (isDateError1)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 8),
                    child: Text("Please select expiry date", style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// import 'dart:async';
// import 'package:bluetooth_dart_plugin/bluetooth_dart_plugin.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../model/jar_model.dart';
// import 'package:flutter/material.dart';
// import '../utils/colors.dart';
//
// class WaitScaleScreen extends StatefulWidget {
//   final String itemName;
//   final double totalWeight;
//   final DateTime expiryDate;
//   const WaitScaleScreen({
//     super.key,
//     required this.itemName,
//     required this.totalWeight,
//     required this.expiryDate,
//   });
//
//   @override
//   State<WaitScaleScreen> createState() => _WaitScaleScreenState();
// }
//
// class _WaitScaleScreenState extends State<WaitScaleScreen> {
//   StreamSubscription? _btSubscription;
//   double currentWeight = 0.0;
//   final TextEditingController weightController = TextEditingController();
//
//   bool isItemError = false;
//   bool isDateError = false;
//   bool isDateError1 = false;
//
//   DateTime? selectedDate = DateTime.now();
//   late DateTime selectedDate1;
//
//   @override
//   void initState() {
//     super.initState();
//     selectedDate1 = widget.expiryDate;
//     _listenToLiveWeight();
//   }
//
//   void _listenToLiveWeight() {
//     _btSubscription = BluetoothDartPlugin.scanStream.listen((event) {
//       if (event['type'] == 'disconnected' || event['state'] == 'disconnected') {
//         if (mounted) {
//           setState(() {
//             BluetoothDartPlugin.isDeviceConnected = false;
//           });
//         }
//       }
//       else if (event['type'] == 'message') {
//         String rawText = event['text'].toString().trim();
//
//         List<String> parts = rawText.split(' ');
//         if (parts.isNotEmpty) {
//           double weightInGrams = double.tryParse(parts[0]) ?? 0.0;
//           if (mounted) {
//             setState(() {
//               currentWeight = double.parse((weightInGrams / 1000.0).toStringAsFixed(4));
//               weightController.text = currentWeight.toStringAsFixed(3);
//             });
//           }
//         }
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _btSubscription?.cancel();
//     weightController.dispose();
//     super.dispose();
//   }
//
//   Future<void> saveJar() async {
//     if (selectedDate == null) {
//       setState(() { isDateError = true; });
//       return;
//     }
//
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<String> jarList = prefs.getStringList("jar_list") ?? [];
//
//     JarModel jar = JarModel(
//       name: widget.itemName,
//       capacity: widget.totalWeight.toString(),
//       expiryDate: selectedDate1.toIso8601String(),
//       addedOn: selectedDate!.toIso8601String(),
//       currentWeight: currentWeight,
//     );
//
//     jarList.add(jar.toJson());
//     await prefs.setStringList("jar_list", jarList);
//
//     Navigator.pop(context, true);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     bool isConnected = BluetoothDartPlugin.isDeviceConnected;
//     double percent = currentWeight / widget.totalWeight;
//     percent = percent.clamp(0.0, 1.0);
//
//     var width = MediaQuery.of(context).size.width;
//     var height = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.only(
//             bottomLeft: Radius.circular(20),
//             bottomRight: Radius.circular(20),
//           ),
//         ),
//         toolbarHeight: height / 9,
//         backgroundColor: ColorString.appBarColor,
//         title: Text(
//           widget.itemName,
//           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
//         ),
//         leadingWidth: width / 5.9,
//         titleSpacing: 0,
//         leading: InkWell(
//           onTap: () => Navigator.pop(context),
//           child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
//         ),
//         actionsPadding: EdgeInsets.only(right: width / 50),
//       ),
//
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.only(bottom: 40, left: 15, right: 15),
//         child: InkWell(
//           onTap: isConnected ? saveJar : () {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text("Cannot save! Please connect Bluetooth to get weight."),
//                 backgroundColor: Colors.red,
//                 behavior: SnackBarBehavior.floating,
//               ),
//             );
//           },
//           child: Container(
//             height: 50,
//             decoration: BoxDecoration(
//               color: isConnected ? ColorString.appBarLeadingColor : Colors.grey.shade400,
//               borderRadius: BorderRadius.circular(15),
//               boxShadow: const [BoxShadow(color: Color(0xFF2F3E46), offset: Offset(0, 2))],
//             ),
//             child: const Center(
//               child: Text(
//                 "Save & Back to Home",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFFFFFF)),
//               ),
//             ),
//           ),
//         ),
//       ),
//
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//
//                 if (!isConnected)
//                   Container(
//                     margin: const EdgeInsets.only(bottom: 20),
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                         color: Colors.red.shade50,
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: Colors.red.shade300)
//                     ),
//                     child: const Row(
//                       children: [
//                         Icon(Icons.bluetooth_disabled, color: Colors.red),
//                         SizedBox(width: 10),
//                         Expanded(
//                           child: Text(
//                             "Bluetooth is disconnected! You cannot add this item without capturing weight.",
//                             style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                 /// Circular Progress
//                 Center(
//                   child: SizedBox(
//                     height: 180,
//                     width: 180,
//                     child: Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         /// Background Ring
//                         SizedBox(
//                           height: 160,
//                           width: 160,
//                           child: CircularProgressIndicator(
//                             value: 1,
//                             strokeWidth: 22,
//                             backgroundColor: Colors.grey.shade300,
//                             valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD9D9D9)),
//                           ),
//                         ),
//
//                         /// Progress Ring
//                         SizedBox(
//                           height: 160,
//                           width: 160,
//                           child: CircularProgressIndicator(
//                             value: percent,
//                             strokeWidth: 22,
//                             strokeCap: StrokeCap.round,
//                             backgroundColor: Colors.transparent,
//                             valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1F7A63)),
//                           ),
//                         ),
//
//                         /// Center Text
//                         Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               "${currentWeight.toStringAsFixed(2)} Kg",
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF2F3E46),
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//
//                             Text(
//                               widget.totalWeight < 1.0
//                                   ? "of ${(widget.totalWeight * 1000).toInt()} g"
//                                   : "of ${widget.totalWeight.toStringAsFixed(2).replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "")} Kg",
//                               style: const TextStyle(
//                                 fontSize: 12,
//                                 color: Color(0xFF949494),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: height / 50),
//
//                 /// Percentage Text
//                 Center(
//                   child: Text(
//                     "${(percent * 100).toInt()}% Remaining",
//                     style: const TextStyle(fontSize: 14, color: Color(0xFF949494)),
//                   ),
//                 ),
//
//                 /// current weight
//                 SizedBox(height: height / 30),
//                 const Text(
//                   "Current Weight",
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Color(0xFF949494),
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       height: 50,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFFFFFFF),
//                         borderRadius: BorderRadius.circular(15),
//                         boxShadow: const [
//                           BoxShadow(offset: Offset(0, 2), blurRadius: 1, color: Color(0xFFCACACA)),
//                           BoxShadow(offset: Offset(0, 0), blurRadius: 1, color: Color(0xFFCACACA)),
//                         ],
//                       ),
//                       child: TextField(
//                         controller: weightController,
//                         readOnly: true,
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                         decoration: const InputDecoration(
//                           hintText: "Waiting for weight...",
//                           hintStyle: TextStyle(color: Color(0xFF949494)),
//                           contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                           border: InputBorder.none,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 /// add date
//                 const SizedBox(height: 15),
//                 const Text(
//                   "Added On",
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Color(0xFF949494),
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     GestureDetector(
//                       onTap: () async {
//                         final DateTime? picked = await showDatePicker(
//                           context: context,
//                           initialDate: selectedDate ?? DateTime.now(),
//                           firstDate: DateTime(2000),
//                           lastDate: DateTime.now(),
//                         );
//
//                         if (picked != null) {
//                           setState(() {
//                             selectedDate = picked;
//                             isDateError = false;
//                           });
//                         }
//                       },
//                       child: Container(
//                         height: 50,
//                         padding: const EdgeInsets.symmetric(horizontal: 20),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFFFFFFF),
//                           borderRadius: BorderRadius.circular(15),
//                           boxShadow: const [
//                             BoxShadow(offset: Offset(0, 2), blurRadius: 1, color: Color(0xFFCACACA)),
//                             BoxShadow(offset: Offset(0, 0), blurRadius: 1, color: Color(0xFFCACACA)),
//                           ],
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               selectedDate == null
//                                   ? "dd / mm / yyyy"
//                                   : "${selectedDate!.day.toString().padLeft(2, '0')} / "
//                                   "${selectedDate!.month.toString().padLeft(2, '0')} / "
//                                   "${selectedDate!.year}",
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: selectedDate == null ? const Color(0xFFB2B2B2) : const Color(0xFF2F3E46),
//                               ),
//                             ),
//                             const Icon(Icons.calendar_month, color: Color(0xFFB2B2B2)),
//                           ],
//                         ),
//                       ),
//                     ),
//
//                     if (isDateError)
//                       const Padding(
//                         padding: EdgeInsets.only(top: 6, left: 8),
//                         child: Text("Please select added date", style: TextStyle(color: Colors.red, fontSize: 12)),
//                       ),
//                   ],
//                 ),
//
//                 /// Expiry date
//                 const SizedBox(height: 15),
//                 const Text(
//                   "Expiry Date",
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Color(0xFF949494),
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     GestureDetector(
//                       onTap: () async {
//                         DateTime? picked = await showDatePicker(
//                           context: context,
//                           initialDate: selectedDate1,
//                           firstDate: DateTime.now(),
//                           lastDate: DateTime(2100),
//                         );
//
//                         if (picked != null) {
//                           setState(() {
//                             selectedDate1 = picked;
//                             isDateError1 = false;
//                           });
//                         }
//                       },
//                       child: Container(
//                         height: 50,
//                         padding: const EdgeInsets.symmetric(horizontal: 20),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFFFFFFF),
//                           borderRadius: BorderRadius.circular(15),
//                           boxShadow: const [
//                             BoxShadow(offset: Offset(0, 2), blurRadius: 1, color: Color(0xFFCACACA)),
//                             BoxShadow(offset: Offset(0, 0), blurRadius: 1, color: Color(0xFFCACACA)),
//                           ],
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               "${selectedDate1.day.toString().padLeft(2, '0')} / "
//                                   "${selectedDate1.month.toString().padLeft(2, '0')} / "
//                                   "${selectedDate1.year}",
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF2F3E46),
//                               ),
//                             ),
//                             const Icon(Icons.calendar_month, color: Color(0xFFB2B2B2)),
//                           ],
//                         ),
//                       ),
//                     ),
//
//                     if (isDateError1)
//                       const Padding(
//                         padding: EdgeInsets.only(top: 6, left: 8),
//                         child: Text("Please select expiry date", style: TextStyle(color: Colors.red, fontSize: 12)),
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }