import 'package:flutter/material.dart';

class JarCard extends StatelessWidget {
  final String title, weight, percentText, expiryText;
  final double percent;
  final Color color;
  final bool isWarning;

  const JarCard({
    super.key,
    required this.title,
    required this.weight,
    required this.percent,
    required this.percentText,
    required this.color,
    required this.expiryText,
    required this.isWarning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFCACACA),
            blurRadius: 1,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0xFFCACACA),
            blurRadius: 0.5,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title and Percentage Box
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8), // Added spacing between title and percent
              // Responsive percentage box (removed fixed width/height)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    percentText,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Weight Display
          Text(
            weight,
            style: const TextStyle(color: Color(0xFF2F3E46), fontSize: 10),
          ),

          const SizedBox(height: 10),

          // Progress Bar
          LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation(color),
          ),

          // Spacer automatically pushes the bottom container to the very end of the card
          // This prevents bottom overflow errors on smaller screens
          const Spacer(),

          // Bottom Expiry Container
          // Replaced fixed width with double.infinity to fill available space responsively
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isWarning
                  ? const Color(0xFFFFE6E7)
                  : const Color(0xFFDEFFDF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isWarning)
                  const Icon(
                    Icons.warning_outlined,
                    color: Color(0xFFE14043),
                    size: 16, // Slightly reduced icon size to fit better
                  ),
                if (isWarning) const SizedBox(width: 4),

                // Flexible prevents long text from causing horizontal overflow
                Flexible(
                  child: Text(
                    expiryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11, // Slightly reduced font size for better fit
                      color: Color(0xFF2F3E46),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
//
// class JarCard extends StatelessWidget {
//   final String title, weight, percentText, expiryText;
//   final double percent;
//   final Color color;
//   final bool isWarning;
//
//   const JarCard({
//     super.key,
//     required this.title,
//     required this.weight,
//     required this.percent,
//     required this.percentText,
//     required this.color,
//     required this.expiryText,
//     required this.isWarning,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFFFFF),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0xFFCACACA),
//             blurRadius: 1,
//             offset: Offset(0, 2),
//           ),
//           BoxShadow(
//             color: Color(0xFFCACACA),
//             blurRadius: 0.5,
//             offset: Offset(0, 0),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Text(
//                   title,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//               ),
//               Container(
//                 width: 45,
//                 height: 20,
//                 padding: const EdgeInsets.only(left: 2),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Center(
//                   child: Text(
//                     percentText,
//                     style: TextStyle(
//                       color: color,
//                       fontSize: 13,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           Text(
//             weight,
//             style: const TextStyle(color: Color(0xFF2F3E46), fontSize: 10),
//           ),
//           const SizedBox(height: 10),
//           LinearProgressIndicator(
//             value: percent,
//             minHeight: 6,
//             borderRadius: BorderRadius.circular(10),
//             backgroundColor: const Color(0xFFF3F4F6),
//             valueColor: AlwaysStoppedAnimation(color),
//           ),
//           const SizedBox(height: 31),
//           Container(
//             width: 151,
//             height: 40,
//             padding: const EdgeInsets.symmetric(vertical: 8),
//             decoration: BoxDecoration(
//               color: isWarning
//                   ? const Color(0xFFFFE6E7)
//                   : const Color(0xFFDEFFDF),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Center(
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   if (isWarning)
//                     const Icon(
//                       Icons.warning_outlined,
//                       color: Color(0xFFE14043),
//                       size: 18,
//                     ),
//                   if (isWarning) const SizedBox(width: 4),
//                   Text(
//                     expiryText,
//                     style: const TextStyle(
//                       fontSize: 12,
//                       color: Color(0xFF2F3E46),
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
