// import 'package:flutter/material.dart';
//
// class EmergencyMonitoringWidget extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Colors.redAccent, Colors.deepOrangeAccent],
//         ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.redAccent.withOpacity(0.3),
//             blurRadius: 15,
//             spreadRadius: 5,
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Text(
//             "Emergency Monitoring",
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: () {
//               // Implement monitoring start action
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(15),
//               ),
//             ),
//             child: Text(
//               "Start Monitoring",
//               style: TextStyle(color: Colors.redAccent),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
