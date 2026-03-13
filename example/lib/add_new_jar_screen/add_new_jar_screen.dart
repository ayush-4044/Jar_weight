import 'package:bluetooth_dart_plugin/bluetooth_dart_plugin.dart';
import 'package:bluetooth_dart_plugin_example/wait_scale_screen/wait_scale_screen.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/texts.dart';

class AddNewJarScreen extends StatefulWidget {
  const AddNewJarScreen({super.key});

  @override
  State<AddNewJarScreen> createState() => _AddNewJarScreenState();
}

class _AddNewJarScreenState extends State<AddNewJarScreen> {
  int? selectedIndex = 0;
  final List<String> capacities = ["500g", "1 kg", "2 kg"];
  final List<double> capacityValues = [0.5, 1.0, 2.0];

  bool isDateError = false;
  DateTime? selectedDate;

  String? errorText1;
  String? errorTextCapacity;

  TextEditingController nameCtrl = TextEditingController();
  TextEditingController capacityCtrl = TextEditingController(text: "0.5");

  @override
  void dispose() {
    nameCtrl.dispose();
    capacityCtrl.dispose();
    super.dispose();
  }

  void submitDetails() {
    setState(() {
      // Item Name Validation
      if (nameCtrl.text.trim().isEmpty) {
        errorText1 = "Please Enter Item Name";
      } else {
        errorText1 = null;
      }

      // Capacity Validation
      double? parsedCapacity = double.tryParse(capacityCtrl.text.trim());
      if (capacityCtrl.text.trim().isEmpty) {
        errorTextCapacity = "Please Enter Capacity";
      } else if (parsedCapacity == null || parsedCapacity <= 0) {
        errorTextCapacity = "Enter a valid number (e.g. 1.5)";
      } else {
        errorTextCapacity = null;
      }

      // Expiry Date Validation
      if (selectedDate == null) {
        isDateError = true;
      } else {
        isDateError = false;
      }
    });

    if (errorText1 == null && errorTextCapacity == null && !isDateError) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WaitScaleScreen(
            itemName: nameCtrl.text.trim(),
            totalWeight: double.parse(capacityCtrl.text.trim()),
            expiryDate: selectedDate!,
          ),
        ),
      ).then((value) {
        if (value == true) {
          Navigator.pop(context, true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        // Changed to use percentage for safer responsive behavior
        toolbarHeight: height * 0.11,
        backgroundColor: ColorString.appBarColor,
        title: const Text(
          Texts.title2,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        // Fixed leading width to prevent layout shifts on large screens
        leadingWidth: 60,
        titleSpacing: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        // Added safe area padding for devices with bottom gestures/notches
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom > 0 ? 20 : 30,
          left: 15,
          right: 15,
          top: 10,
        ),
        child: InkWell(
          onTap: submitDetails,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: ColorString.appBarLeadingColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Color(0xFF2F3E46), offset: Offset(0, 2)),
              ],
            ),
            child: const Center(
              child: Text(
                "Complete",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                Texts.line2,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8), // Replaced dynamic height with fixed logical spacing
              const Text(
                Texts.line3,
                style: TextStyle(fontSize: 11.5, color: ColorString.textColor),
              ),
              const SizedBox(height: 20),

              // Calibrate Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorString.calibrateButtonColor,
                    // Responsive minimum size
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        color: Color(0xFFD2E8F4),
                        width: 0.7,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    if (BluetoothDartPlugin.isDeviceConnected) {
                      BluetoothDartPlugin.calibrateZero();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Jar calibrated to zero successfully!"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Cannot calibrate! Please connect Bluetooth first."),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.balance, color: Colors.black, size: 19),
                      SizedBox(width: 8),
                      Text(
                        Texts.calibrateZero,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// ITEM NAME
              const Text(
                "Item Name",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        offset: Offset(0, 2),
                        blurRadius: 1,
                        color: Color(0xFFCACACA),
                      ),
                      BoxShadow(
                        offset: Offset(0, 0),
                        blurRadius: 1,
                        color: Color(0xFFCACACA),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: TextField(
                      controller: nameCtrl,
                      onChanged: (value) {
                        if (value.trim().isNotEmpty && errorText1 != null) {
                          setState(() {
                            errorText1 = null;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 15),
                      ),
                    ),
                  ),
                ),
              ),

              if (errorText1 != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 8),
                  child: Text(
                    errorText1!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 25),

              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Capacity",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  Text(
                    "(Select or type below)",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // --- RESPONSIVE FIX FOR CAPACITY BUTTONS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Row(
                  children: List.generate(capacities.length, (index) {
                    final isSelected = selectedIndex == index;
                    return Expanded(
                      child: Padding(
                        // Adds spacing between buttons, but removes it from the last one
                        padding: EdgeInsets.only(right: index == capacities.length - 1 ? 0 : 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                              capacityCtrl.text = capacityValues[index].toString();
                              errorTextCapacity = null;
                            });
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEEF9FF)
                                  : const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color(0xFFCACACA),
                                width: 0.2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFFCACACA),
                                  blurRadius: 1,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              capacities[index],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2F3E46),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // ---------------------------------------------

              const SizedBox(height: 15),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        offset: Offset(0, 2),
                        blurRadius: 1,
                        color: Color(0xFFCACACA),
                      ),
                      BoxShadow(
                        offset: Offset(0, 0),
                        blurRadius: 1,
                        color: Color(0xFFCACACA),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: TextField(
                      controller: capacityCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        double? val = double.tryParse(value.trim());
                        int matchIndex = capacityValues.indexWhere((element) => element == val);

                        setState(() {
                          selectedIndex = matchIndex != -1 ? matchIndex : null;

                          if (value.trim().isNotEmpty && errorTextCapacity != null) {
                            errorTextCapacity = null;
                          }
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: "Or enter manually in Kg (e.g. 1.5)",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 15),
                        suffixText: "Kg",
                        suffixStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),

              if (errorTextCapacity != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 8),
                  child: Text(
                    errorTextCapacity!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 25),

              /// EXPIRY DATE
              const Text(
                "Expiry Date",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );

                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                          isDateError = false;
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [
                            BoxShadow(
                              offset: Offset(0, 2),
                              blurRadius: 1,
                              color: Color(0xFFCACACA),
                            ),
                            BoxShadow(
                              offset: Offset(0, 0),
                              blurRadius: 1,
                              color: Color(0xFFCACACA),
                            ),
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
                                color: selectedDate == null
                                    ? const Color(0xFFB2B2B2)
                                    : const Color(0xFF2F3E46),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_month,
                              color: Color(0xFFB2B2B2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (isDateError)
                    const Padding(
                      padding: EdgeInsets.only(top: 6, left: 8),
                      child: Text(
                        "Please select expiry date",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 15,)
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:bluetooth_dart_plugin/bluetooth_dart_plugin.dart';
// import 'package:bluetooth_dart_plugin_example/wait_scale_screen/wait_scale_screen.dart';
// import 'package:flutter/material.dart';
// import '../utils/colors.dart';
// import '../utils/texts.dart';
//
// class AddNewJarScreen extends StatefulWidget {
//   const AddNewJarScreen({super.key});
//
//   @override
//   State<AddNewJarScreen> createState() => _AddNewJarScreenState();
// }
//
// class _AddNewJarScreenState extends State<AddNewJarScreen> {
//   int? selectedIndex = 0;
//   final List<String> capacities = ["500g", "1 kg", "2 kg"];
//   final List<double> capacityValues = [0.5, 1.0, 2.0];
//
//   bool isDateError = false;
//   DateTime? selectedDate;
//
//   String? errorText1;
//   String? errorTextCapacity;
//
//   TextEditingController nameCtrl = TextEditingController();
//   TextEditingController capacityCtrl = TextEditingController(text: "0.5");
//
//   @override
//   void dispose() {
//     nameCtrl.dispose();
//     capacityCtrl.dispose();
//     super.dispose();
//   }
//
//   void submitDetails() {
//     setState(() {
//       // Item Name Validation
//       if (nameCtrl.text.trim().isEmpty) {
//         errorText1 = "Please Enter Item Name";
//       } else {
//         errorText1 = null;
//       }
//
//       // Capacity Validation
//       double? parsedCapacity = double.tryParse(capacityCtrl.text.trim());
//       if (capacityCtrl.text.trim().isEmpty) {
//         errorTextCapacity = "Please Enter Capacity";
//       } else if (parsedCapacity == null || parsedCapacity <= 0) {
//         errorTextCapacity = "Enter a valid number (e.g. 1.5)";
//       } else {
//         errorTextCapacity = null;
//       }
//
//       // Expiry Date Validation
//       if (selectedDate == null) {
//         isDateError = true;
//       } else {
//         isDateError = false;
//       }
//     });
//
//     if (errorText1 == null && errorTextCapacity == null && !isDateError) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => WaitScaleScreen(
//             itemName: nameCtrl.text.trim(),
//             totalWeight: double.parse(capacityCtrl.text.trim()),
//             expiryDate: selectedDate!,
//           ),
//         ),
//       ).then((value) {
//         if (value == true) {
//           Navigator.pop(context, true);
//         }
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var width = MediaQuery.of(context).size.width;
//     var height = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFFFFFFF),
//       appBar: AppBar(
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.only(
//             bottomLeft: Radius.circular(20),
//             bottomRight: Radius.circular(20),
//           ),
//         ),
//         toolbarHeight: height / 9,
//         backgroundColor: ColorString.appBarColor,
//         title: const Text(
//           Texts.title2,
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         leadingWidth: width / 5.9,
//         titleSpacing: 0,
//         leading: InkWell(
//           onTap: () {
//             Navigator.pop(context);
//           },
//           child: const Icon(
//             Icons.arrow_back_ios_new,
//             color: Colors.white,
//             size: 20,
//           ),
//         ),
//       ),
//
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.only(bottom: 40, left: 15, right: 15),
//         child: InkWell(
//           onTap: submitDetails,
//           child: Container(
//             height: 50,
//             decoration: BoxDecoration(
//               color: ColorString.appBarLeadingColor,
//               borderRadius: BorderRadius.circular(15),
//               boxShadow: const [
//                 BoxShadow(color: Color(0xFF2F3E46), offset: Offset(0, 2)),
//               ],
//             ),
//             child: const Center(
//               child: Text(
//                 "Complete",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                   color: Color(0xFFFFFFFF),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 Texts.line2,
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//               ),
//               SizedBox(height: height / 100),
//               const Text(
//                 Texts.line3,
//                 style: TextStyle(fontSize: 11.5, color: ColorString.textColor),
//               ),
//               SizedBox(height: height / 45),
//
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 1),
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: ColorString.calibrateButtonColor,
//                     minimumSize: Size(width, height / 18),
//                     shape: RoundedRectangleBorder(
//                       side: const BorderSide(
//                         color: Color(0xFFD2E8F4),
//                         width: 0.7,
//                       ),
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                   ),
//                   onPressed: () {
//                     if (BluetoothDartPlugin.isDeviceConnected) {
//                       BluetoothDartPlugin.calibrateZero();
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text("Jar calibrated to zero successfully!"),
//                           backgroundColor: Colors.green,
//                           behavior: SnackBarBehavior.floating,
//                           duration: Duration(seconds: 1),
//                         ),
//                       );
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text("Cannot calibrate! Please connect Bluetooth first."),
//                           backgroundColor: Colors.red,
//                           behavior: SnackBarBehavior.floating,
//                           duration: Duration(seconds: 2),
//                         ),
//                       );
//                     }
//                   },
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(Icons.balance, color: Colors.black, size: 19),
//                       SizedBox(width: width / 60),
//                       const Text(
//                         Texts.calibrateZero,
//                         style: TextStyle(
//                           color: Colors.black,
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: height / 30),
//
//               /// ITEM NAME
//               const Text(
//                 "Item Name",
//                 style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
//               ),
//               SizedBox(height: height / 100),
//
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 2),
//                 child: Container(
//                   width: double.infinity,
//                   height: 50,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     boxShadow: const [
//                       BoxShadow(
//                         offset: Offset(0, 2),
//                         blurRadius: 1,
//                         color: Color(0xFFCACACA),
//                       ),
//                       BoxShadow(
//                         offset: Offset(0, 0),
//                         blurRadius: 1,
//                         color: Color(0xFFCACACA),
//                       ),
//                     ],
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   child: Center(
//                     child: TextField(
//                       controller: nameCtrl,
//                       onChanged: (value) {
//                         if (value.trim().isNotEmpty && errorText1 != null) {
//                           setState(() {
//                             errorText1 = null;
//                           });
//                         }
//                       },
//                       decoration: const InputDecoration(
//                         border: OutlineInputBorder(borderSide: BorderSide.none),
//                         contentPadding: EdgeInsets.symmetric(horizontal: 15),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//
//               if (errorText1 != null)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 6, left: 8),
//                   child: Text(
//                     errorText1!,
//                     style: const TextStyle(color: Colors.red, fontSize: 12),
//                   ),
//                 ),
//
//               SizedBox(height: height / 40),
//
//               const Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Total Capacity",
//                     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
//                   ),
//                   Text(
//                     "(Select or type below)",
//                     style: TextStyle(fontSize: 12, color: Colors.grey),
//                   ),
//                 ],
//               ),
//               SizedBox(height: height / 100),
//
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 1.5),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: List.generate(capacities.length, (index) {
//                     final isSelected = selectedIndex == index;
//                     return GestureDetector(
//                       onTap: () {
//                         setState(() {
//                           selectedIndex = index;
//                           capacityCtrl.text = capacityValues[index].toString();
//                           errorTextCapacity = null;
//                         });
//                       },
//                       child: Container(
//                         width: 115,
//                         height: 50,
//                         alignment: Alignment.center,
//                         decoration: BoxDecoration(
//                           color: isSelected
//                               ? const Color(0xFFEEF9FF)
//                               : const Color(0xFFFFFFFF),
//                           borderRadius: BorderRadius.circular(15),
//                           border: Border.all(
//                             color: const Color(0xFFCACACA),
//                             width: 0.2,
//                           ),
//                           boxShadow: const [
//                             BoxShadow(
//                               color: Color(0xFFCACACA),
//                               blurRadius: 1,
//                               offset: Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Text(
//                           capacities[index],
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF2F3E46),
//                           ),
//                         ),
//                       ),
//                     );
//                   }),
//                 ),
//               ),
//
//               const SizedBox(height: 15),
//
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 2),
//                 child: Container(
//                   width: double.infinity,
//                   height: 50,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     boxShadow: const [
//                       BoxShadow(
//                         offset: Offset(0, 2),
//                         blurRadius: 1,
//                         color: Color(0xFFCACACA),
//                       ),
//                       BoxShadow(
//                         offset: Offset(0, 0),
//                         blurRadius: 1,
//                         color: Color(0xFFCACACA),
//                       ),
//                     ],
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   child: Center(
//                     child: TextField(
//                       controller: capacityCtrl,
//                       keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                       onChanged: (value) {
//                         double? val = double.tryParse(value.trim());
//                         int matchIndex = capacityValues.indexWhere((element) => element == val);
//
//                         setState(() {
//                           selectedIndex = matchIndex != -1 ? matchIndex : null;
//
//                           if (value.trim().isNotEmpty && errorTextCapacity != null) {
//                             errorTextCapacity = null;
//                           }
//                         });
//                       },
//                       decoration: const InputDecoration(
//                         hintText: "Or enter manually in Kg (e.g. 1.5)",
//                         hintStyle: TextStyle(color: Colors.grey),
//                         border: OutlineInputBorder(borderSide: BorderSide.none),
//                         contentPadding: EdgeInsets.symmetric(horizontal: 15),
//                         suffixText: "Kg",
//                         suffixStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//
//               if (errorTextCapacity != null)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 6, left: 8),
//                   child: Text(
//                     errorTextCapacity!,
//                     style: const TextStyle(color: Colors.red, fontSize: 12),
//                   ),
//                 ),
//
//               SizedBox(height: height / 40),
//
//               /// EXPIRY DATE
//               const Text(
//                 "Expiry Date",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//               ),
//               SizedBox(height: height / 90),
//
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   GestureDetector(
//                     onTap: () async {
//                       DateTime? picked = await showDatePicker(
//                         context: context,
//                         initialDate: DateTime.now(),
//                         firstDate: DateTime.now(),
//                         lastDate: DateTime(2100),
//                       );
//
//                       if (picked != null) {
//                         setState(() {
//                           selectedDate = picked;
//                           isDateError = false;
//                         });
//                       }
//                     },
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 1.5),
//                       child: Container(
//                         height: 50,
//                         padding: const EdgeInsets.symmetric(horizontal: 20),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFFFFFFF),
//                           borderRadius: BorderRadius.circular(15),
//                           boxShadow: const [
//                             BoxShadow(
//                               offset: Offset(0, 2),
//                               blurRadius: 1,
//                               color: Color(0xFFCACACA),
//                             ),
//                             BoxShadow(
//                               offset: Offset(0, 0),
//                               blurRadius: 1,
//                               color: Color(0xFFCACACA),
//                             ),
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
//                                 color: selectedDate == null
//                                     ? const Color(0xFFB2B2B2)
//                                     : const Color(0xFF2F3E46),
//                               ),
//                             ),
//                             const Icon(
//                               Icons.calendar_month,
//                               color: Color(0xFFB2B2B2),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   if (isDateError)
//                     const Padding(
//                       padding: EdgeInsets.only(top: 6, left: 8),
//                       child: Text(
//                         "Please select expiry date",
//                         style: TextStyle(color: Colors.red, fontSize: 12),
//                       ),
//                     ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }