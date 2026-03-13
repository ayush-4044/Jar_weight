import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

import '../add_new_jar_screen/add_new_jar_screen.dart';

class AddJarCard extends StatelessWidget {
  final VoidCallback onJarAdded;

  const AddJarCard({super.key, required this.onJarAdded});

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      borderType: BorderType.RRect,
      color: const Color(0xFFCACACA),
      dashPattern: const [4, 4],
      strokeWidth: 1,
      radius: const Radius.circular(15),
      child: GestureDetector(
        // IMPORTANT UX FIX: Makes the entire transparent container area clickable,
        // not just the visible pixels of the Icon and Text.
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Navigate to AddNewJarScreen and wait for the result
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddNewJarScreen()),
          ).then((value) {
            // If value is true (meaning a jar was successfully added), trigger the callback
            if (value == true) onJarAdded();
          });
        },
        child: Container(
          // Expands to fill the available GridView tile space
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle, size: 24, color: Color(0xFFCACACA)),
                SizedBox(height: 6),
                Text(
                  "Add Jar",
                  style: TextStyle(color: Color(0xFFCACACA), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}