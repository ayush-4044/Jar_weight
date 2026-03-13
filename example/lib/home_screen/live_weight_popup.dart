import 'dart:async';
import 'package:bluetooth_dart_plugin/bluetooth_dart_plugin.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../model/jar_model.dart';

class LiveWeightPopup extends StatefulWidget {
  final JarModel jar;
  final int jarIndex;
  const LiveWeightPopup({super.key, required this.jar, required this.jarIndex});

  @override
  State<LiveWeightPopup> createState() => _LiveWeightPopupState();
}

class _LiveWeightPopupState extends State<LiveWeightPopup> {
  StreamSubscription? _btSubscription;
  double currentWeight = 0.0;
  double capacity = 1.0;
  double latestRawWeight = 0.0;
  double tareOffset = 0.0;

  bool isEditing = false;
  late TextEditingController nameCtrl;
  late TextEditingController capacityCtrl;
  late DateTime editedDate;

  String? errorMessage1;
  String? errorMessage2;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    currentWeight = widget.jar.currentWeight;
    capacity = double.tryParse(widget.jar.capacity) ?? 1.0;

    nameCtrl = TextEditingController(text: widget.jar.name);
    capacityCtrl = TextEditingController(text: widget.jar.capacity);
    editedDate = DateTime.parse(widget.jar.expiryDate);

    _listenToLiveWeight();

  }

  void _listenToLiveWeight() {
    _btSubscription = BluetoothDartPlugin.scanStream.listen((event) {
      if (event['type'] == 'message') {
        String rawText = event['text'].toString().trim();
        List<String> parts = rawText.split(' ');
        if (parts.isNotEmpty) {
          double weightInGrams = double.tryParse(parts[0]) ?? 0.0;

          if (weightInGrams > 2.0) {
            if (mounted) {
              setState(() {
                currentWeight = double.parse((weightInGrams / 1000.0).toStringAsFixed(4));
              });
            }
          }
          if (mounted) {
            setState(() {
              latestRawWeight = double.parse((weightInGrams / 1000.0).toStringAsFixed(4));
              double calculatedWeight = latestRawWeight - tareOffset;
              currentWeight = calculatedWeight < 0 ? 0.0 : double.parse(calculatedWeight.toStringAsFixed(4));
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _btSubscription?.cancel();
    nameCtrl.dispose();
    capacityCtrl.dispose();
    super.dispose();
  }
  Future<void> _deleteJar() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList("jar_list") ?? [];

    if (widget.jarIndex >= 0 && widget.jarIndex < savedList.length) {
      savedList.removeAt(widget.jarIndex);
      await prefs.setStringList("jar_list", savedList);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }


  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Item"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteJar();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndClose() async {
    String finalName = nameCtrl.text.trim().isEmpty ? widget.jar.name : nameCtrl.text.trim();
    String finalCapacity = double.tryParse(capacityCtrl.text.trim()) != null
        ? capacityCtrl.text.trim()
        : widget.jar.capacity;

    double parsedCapacity = double.tryParse(finalCapacity) ?? 1.0;

    if (currentWeight > parsedCapacity) {
      setState(() {
        errorMessage1 = "Overweight! Weight (${currentWeight.toStringAsFixed(2)} Kg) exceeds capacity (${parsedCapacity.toStringAsFixed(2)} Kg).";
      });
      return;
    }
    if (currentWeight < 0.0) {
      setState(() {
        errorMessage2 = "Weight cannot be negative.";
      });
      return;
    }

    setState(() {
      errorMessage2 = null;
    });
    

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList("jar_list") ?? [];

    JarModel updatedJar = JarModel(
      name: finalName,
      capacity: finalCapacity,
      expiryDate: editedDate.toIso8601String(),
      addedOn: widget.jar.addedOn,
      currentWeight: currentWeight,
    );

    savedList[widget.jarIndex] = updatedJar.toJson();
    await prefs.setStringList("jar_list", savedList);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isConnected = BluetoothDartPlugin.isDeviceConnected;
    double percent = (currentWeight / capacity).clamp(0.0, 1.0);
    Color progressColor = percent < 0.40
        ? const Color(0xFFE14043)
        : (percent <= 0.65 ? const Color(0xFFFDB532) : const Color(0xFF3CB340));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,

      // Responsive Title Row
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: isEditing
                ? TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Jar Name", isDense: true),
            )
                : Text(
              nameCtrl.text,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),

          // Edit Button
          Row(
            children: [
              GestureDetector(
                onTap: isConnected ? () {
                  setState(() {
                    if (isEditing) {
                      capacity = double.tryParse(capacityCtrl.text) ?? capacity;
                    }
                    isEditing = !isEditing;
                  });
                } : null,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isConnected ? (isEditing ? Colors.green.shade100 : Colors.grey.shade200) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEditing ? Icons.check : Icons.edit,
                    color: isConnected ? (isEditing ? Colors.green : const Color(0xFF2F3E46)) : Colors.grey,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: 10,),
              GestureDetector(
                onTap: _showDeleteConfirmation,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                ),
              ),
              const SizedBox(width: 10),
            ],
          )
        ],
      ),

      // Scrollable content prevents overflow when keyboard appears
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // Warning if Bluetooth is disconnected
            if (!isConnected)
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text("Connect Bluetooth to edit or calibrate.", style: TextStyle(color: Colors.red, fontSize: 12))),
                  ],
                ),
              ),
            if (errorMessage1 != null)
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            errorMessage1!,
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)
                        )
                    ),
                  ],
                ),
              ),
            if (errorMessage2 != null)
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            errorMessage2!,
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)
                        )
                    ),
                  ],
                ),
              ),

            // Edit Mode Fields
            if (isEditing) ...[
              TextField(
                controller: capacityCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  if (errorMessage1 != null || errorMessage2 != null) {
                    setState(() {
                      errorMessage1 = null;
                      errorMessage2 = null;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: "Total Capacity (Kg)", isDense: true),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: editedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      editedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Expiry: ${editedDate.day.toString().padLeft(2,'0')}/${editedDate.month.toString().padLeft(2,'0')}/${editedDate.year}",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Icon(Icons.calendar_month, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(thickness: 1),
              const SizedBox(height: 10),
            ],

            // Current Weight Display
            Text(
              "${currentWeight.toStringAsFixed(2)} Kg",
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F3E46),
              ),
            ),

            // Dynamic capacity display (handles decimals properly)
            Text(
              capacity < 1.0
                  ? "of ${(capacity * 1000).toInt()} g (${((1.0 - percent) * 100).toInt()}% Remaining)"
                  : "of ${capacity.toStringAsFixed(2).replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "")} Kg (${((1.0 - percent) * 100).toInt()}% Remaining)",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Progress Bar
            LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),

            const SizedBox(height: 30),

            // Calibrate Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? const Color(0xFFD2E8F4) : Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 45), // Responsive width
              ),
              onPressed: isConnected ? () {
                setState(() {
                  tareOffset = tareOffset + currentWeight;
                  currentWeight = 0.0;
                });
              } : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.balance, color: isConnected ? Colors.black : Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Calibrate Zero",
                    style: TextStyle(
                      color: isConnected ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Dialog Actions
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            // Changed color to grey when disabled for better UI feedback
            backgroundColor: isConnected ? const Color(0xFF1F7A63) : Colors.grey.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: isConnected ? _saveAndClose : null,
          child: const Text("Save", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}