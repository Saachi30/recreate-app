// import 'package:flutter/material.dart';
// import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
// import 'package:vector_math/vector_math_64.dart' as vector;

// class RenewableEnergyAR extends StatefulWidget {
//   const RenewableEnergyAR({Key? key}) : super(key: key);

//   @override
//   _RenewableEnergyARState createState() => _RenewableEnergyARState();
// }

// class _RenewableEnergyARState extends State<RenewableEnergyAR> {
//   ArCoreController? arCoreController;
//   Map<String, ArCoreNode> nodes = {};
  
//   @override
//   void dispose() {
//     arCoreController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Renewable Energy AR View'),
//         backgroundColor: Colors.green,
//       ),
//       body: Stack(
//         children: [
//           ArCoreView(
//             onArCoreViewCreated: _onArCoreViewCreated,
//             enableTapRecognizer: true,
//           ),
//           Positioned(
//             bottom: 20,
//             left: 0,
//             right: 0,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _buildARButton(
//                   'Add Solar Panel',
//                   Icons.wb_sunny,
//                   Colors.orange,
//                   () => _addSolarPanel(),
//                 ),
//                 _buildARButton(
//                   'Add Wind Turbine',
//                   Icons.air,
//                   Colors.blue,
//                   () => _addWindTurbine(),
//                 ),
//                 _buildARButton(
//                   'Add Energy Stats',
//                   Icons.bar_chart,
//                   Colors.green,
//                   _addEnergyStats,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildARButton(
//     String label,
//     IconData icon,
//     Color color,
//     VoidCallback onPressed,
//   ) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon, color: Colors.white),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//       ),
//     );
//   }

//   void _onArCoreViewCreated(ArCoreController controller) {
//     arCoreController = controller;
//     arCoreController!.onNodeTap = (name) => _onNodeTapped(name);
//     arCoreController!.onPlaneTap = _handleTapOnPlane;
//   }

//   Future<void> _handleTapOnPlane(List<ArCoreHitTestResult> hits) async {
//     if (hits.isEmpty) return;
    
//     final hit = hits.first;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Add Renewable Energy Object'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.wb_sunny, color: Colors.orange),
//               title: const Text('Solar Panel'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _addSolarPanel(hitResult: hit);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.air, color: Colors.blue),
//               title: const Text('Wind Turbine'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _addWindTurbine(hitResult: hit);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _addSolarPanel({ArCoreHitTestResult? hitResult}) async {
//     final material = ArCoreMaterial(
//       color: Colors.blue,
//       metallic: 1.0,
//     );

//     final cube = ArCoreCube(
//       materials: [material],
//       size: vector.Vector3(0.2, 0.02, 0.2),
//     );

//     final position = hitResult?.pose?.translation ?? vector.Vector3(0, 0, -1.5);
//     final rotation = hitResult?.pose?.rotation ?? vector.Vector4(0, 0, 0, 0);

//     final node = ArCoreNode(
//       shape: cube,
//       position: position,
//       rotation: rotation,
//       name: 'solar_panel_${DateTime.now().millisecondsSinceEpoch}',
//     );

//     arCoreController?.addArCoreNode(node);
    
//     // Add info node above the solar panel
//     final infoPosition = vector.Vector3(
//       position.x,
//       position.y + 0.1,
//       position.z,
//     );
    
//     // Create info display using a cube with colored material
//     final infoMaterial = ArCoreMaterial(
//       color: Colors.white,
//     );
    
//     final infoShape = ArCoreCube(
//       materials: [infoMaterial],
//       size: vector.Vector3(0.3, 0.15, 0.01),
//     );

//     final infoNode = ArCoreNode(
//       shape: infoShape,
//       position: infoPosition,
//       rotation: rotation,
//       name: 'info_solar_${DateTime.now().millisecondsSinceEpoch}',
//     );

//     arCoreController?.addArCoreNode(infoNode);
//   }

//   Future<void> _addWindTurbine({ArCoreHitTestResult? hitResult}) async {
//     final baseMaterial = ArCoreMaterial(
//       color: Colors.grey,
//       metallic: 1.0,
//     );

//     final base = ArCoreCylinder(
//       materials: [baseMaterial],
//       radius: 0.05,
//       height: 0.5,
//     );

//     final position = hitResult?.pose?.translation ?? vector.Vector3(0, 0, -1.5);
//     final rotation = hitResult?.pose?.rotation ?? vector.Vector4(0, 0, 0, 0);

//     final node = ArCoreNode(
//       shape: base,
//       position: position,
//       rotation: rotation,
//       name: 'wind_turbine_${DateTime.now().millisecondsSinceEpoch}',
//     );

//     arCoreController?.addArCoreNode(node);
    
//     // Add blades as a rotating node
//     final bladeMaterial = ArCoreMaterial(
//       color: Colors.white,
//       metallic: 1.0,
//     );

//     final blade = ArCoreCube(
//       materials: [bladeMaterial],
//       size: vector.Vector3(0.5, 0.1, 0.02),
//     );

//     final bladePosition = vector.Vector3(
//       position.x,
//       position.y + 0.5, // Top of cylinder
//       position.z,
//     );

//     final bladeNode = ArCoreRotatingNode(
//       shape: blade,
//       position: bladePosition,
//       rotation: vector.Vector4(0, 0, 0, 0),
//       degreesPerSecond: 60,
//       name: 'turbine_blade_${DateTime.now().millisecondsSinceEpoch}',
//     );

//     arCoreController?.addArCoreNode(bladeNode);
//   }

//   void _addEnergyStats() {
//     final position = vector.Vector3(0, 0, -1);
    
//     // Create stats display using a cube with colored material
//     final statsMaterial = ArCoreMaterial(
//       color: Colors.white,
//     );
    
//     final statsShape = ArCoreCube(
//       materials: [statsMaterial],
//       size: vector.Vector3(0.5, 0.3, 0.01),
//     );

//     final statsNode = ArCoreNode(
//       shape: statsShape,
//       position: position,
//       rotation: vector.Vector4(0, 0, 0, 0),
//       name: 'energy_stats_${DateTime.now().millisecondsSinceEpoch}',
//     );

//     arCoreController?.addArCoreNode(statsNode);
//   }

//   void _onNodeTapped(String name) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Energy Information'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (name.contains('solar_panel')) ...[
//               const Text('Solar Panel Installation'),
//               const Text('Current Output: 350W'),
//               const Text('Daily CO₂ Savings: 15kg'),
//               const Text('Efficiency: 21%'),
//             ] else if (name.contains('wind_turbine')) ...[
//               const Text('Wind Turbine Installation'),
//               const Text('Current Output: 2.5MW'),
//               const Text('Daily CO₂ Savings: 2500kg'),
//               const Text('Wind Speed: 15 mph'),
//             ],
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//           TextButton(
//             onPressed: () {
//               arCoreController?.removeNode(nodeName: name);
//               Navigator.pop(context);
//             },
//             child: const Text('Remove', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }
// }