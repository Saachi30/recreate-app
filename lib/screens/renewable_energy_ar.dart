import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class RenewableEnergyAR extends StatefulWidget {
  const RenewableEnergyAR({Key? key}) : super(key: key);

  @override
  _RenewableEnergyARState createState() => _RenewableEnergyARState();
}

class _RenewableEnergyARState extends State<RenewableEnergyAR> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  ARLocationManager? arLocationManager;

  List<ARNode> nodes = [];
  bool showFeaturePoints = false;
  bool showPlanes = true;
  bool showWorldOrigin = true;
  String? selectedObject;
  String? _errorMessage;

  // Simple SVG icons as strings
  final String solarPanelIcon = '''
    <svg viewBox="0 0 100 100">
      <rect x="10" y="10" width="80" height="80" fill="#4CAF50"/>
      <rect x="20" y="20" width="25" height="25" fill="#2196F3"/>
      <rect x="55" y="20" width="25" height="25" fill="#2196F3"/>
      <rect x="20" y="55" width="25" height="25" fill="#2196F3"/>
      <rect x="55" y="55" width="25" height="25" fill="#2196F3"/>
    </svg>
  ''';

  final String windTurbineIcon = '''
    <svg viewBox="0 0 100 100">
      <rect x="45" y="40" width="10" height="50" fill="#616161"/>
      <circle cx="50" cy="40" r="30" fill="#90CAF9" stroke="#616161" stroke-width="2"/>
      <path d="M50 40 L80 40 L50 30 Z" fill="#90CAF9"/>
      <path d="M50 40 L35 70 L45 35 Z" fill="#90CAF9"/>
      <path d="M50 40 L35 10 L45 45 Z" fill="#90CAF9"/>
    </svg>
  ''';
  
  @override
  void initState() {
    super.initState();
    _copyAssets();
  }

  Future<void> _copyAssets() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDir.path}/models');
      await modelsDir.create(recursive: true);

      // Copy GLB files from assets to app directory
      final models = ['solar_panel.glb', 'wind_turbine.glb'];
      for (final model in models) {
        final assetFile = File('${modelsDir.path}/$model');
        if (!await assetFile.exists()) {
          final byteData = await DefaultAssetBundle.of(context).load('assets/models/$model');
          await assetFile.writeAsBytes(byteData.buffer.asUint8List());
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error loading models: $e');
      print('Error copying assets: $e');
    }
  }

  Future<String> _getModelPath(String modelName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/models/$modelName';
  }
Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
  if (hitTestResults.isEmpty || selectedObject == null) return;

  final hit = hitTestResults.first;
  
  // Create a basic geometry node instead of using SVG
  final node = ARNode(
    type: NodeType.localGLTF2, // Using local geometry type
    uri: selectedObject == 'solar_panel' ? 
         'https://github.com/Ritika-Das/3D_Hyperloop/blob/master/Solar%20panel.glb' : // Temporary box for solar panel
         'https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Cylinder/glTF-Binary/Cylinder.glb', // Temporary cylinder for turbine
    scale: Vector3(0.2, 0.2, 0.2),
    position: Vector3(
      hit.worldTransform.getColumn(3).x,
      hit.worldTransform.getColumn(3).y,
      hit.worldTransform.getColumn(3).z,
    ),
    rotation: Vector4(1.0, 0.0, 0.0, 0.0),
  );

  try {
    bool? didAddNode = await arObjectManager?.addNode(node);
    if (didAddNode ?? false) {
      nodes.add(node);
      setState(() {
        selectedObject = null;
      });
    }
  } catch (e) {
    print('Error adding node: $e');
    setState(() => _errorMessage = 'Error placing object: $e');
  }
}
  
  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renewable Energy AR View'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA726),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => _selectObject('solar_panel'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            // Icon(Icons.wb_sunny, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Solar Panel', 
                              // style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => _selectObject('wind_turbine'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            // Icon(Icons.air, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Wind Turbine',
                              // style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selectedObject != null)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  // color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Tap on a surface to place ${selectedObject == 'solar_panel' ? 'Solar Panel' : 'Wind Turbine'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    // color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildARButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: const Color(0xFFFFFFFF)),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildDebugButton() {
    return ElevatedButton.icon(
      onPressed: _toggleDebugOptions,
      icon: const Icon(Icons.bug_report, color: Color(0xFFFFFFFF)),
      label: const Text('Debug'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9E9E9E),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;
    arLocationManager = locationManager;

    arSessionManager!.onInitialize(
      showFeaturePoints: showFeaturePoints,
      showPlanes: showPlanes,
      customPlaneTexturePath: "assets/triangle.png",
      showWorldOrigin: showWorldOrigin,
      handleTaps: true,
    );

    arObjectManager!.onInitialize();

    arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
    arObjectManager!.onNodeTap = onNodeTapped;
  }

  void _selectObject(String type) {
    setState(() {
      selectedObject = type;
    });
  }

  // Future<void> onPlaneOrPointTapped(
  //     List<ARHitTestResult> hitTestResults) async {
  //   if (hitTestResults.isEmpty || selectedObject == null) return;

  //   final hit = hitTestResults.first;

  //   // Remove file extension as the plugin adds "renderable" + extension internally
  //   final modelPath = selectedObject == 'solar_panel'
  //       ? 'assets/models/solar_panel.glb' // Removed .glb
  //       : 'assets/models/wind_turbine.glb'; // Removed .glb

  //   final node = ARNode(
  //     type: NodeType.fileSystemAppFolderGLB,
  //     uri: modelPath,
  //     scale: Vector3(0.2, 0.2, 0.2),
  //     position: Vector3(
  //       hit.worldTransform.getColumn(3).x,
  //       hit.worldTransform.getColumn(3).y,
  //       hit.worldTransform.getColumn(3).z,
  //     ),
  //     rotation: Vector4(1, 0, 0, 0),
  //   );

  //   try {
  //     bool? didAddNode = await arObjectManager?.addNode(node);
  //     if (didAddNode ?? false) {
  //       nodes.add(node);
  //       setState(() {
  //         selectedObject = null;
  //       });
  //     }
  //   } catch (e) {
  //     print('Error loading model: $e');
  //   }
  // }

  void onNodeTapped(List<String> nodeNames) {
    final nodeName = nodeNames.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Energy Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (nodeName.contains('solar_panel')) ...[
              const Text('Solar Panel Stats:'),
              const Text('• Current Output: 350W'),
              const Text('• Daily Generation: 2.8kWh'),
              const Text('• CO₂ Savings: 15kg/day'),
            ] else if (nodeName.contains('wind_turbine')) ...[
              const Text('Wind Turbine Stats:'),
              const Text('• Current Output: 2.5MW'),
              const Text('• Wind Speed: 15 mph'),
              const Text('• CO₂ Savings: 2500kg/day'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              final nodeToRemove = nodes.firstWhere(
                (node) => node.name == nodeName,
                orElse: () => nodes.first,
              );
              await arObjectManager?.removeNode(nodeToRemove);
              nodes.remove(nodeToRemove);
              Navigator.pop(context);
            },
            child: const Text('Remove',
                style: TextStyle(color: Color(0xFFFF0000))),
          ),
        ],
      ),
    );
  }

  void _toggleDebugOptions() {
    setState(() {
      showFeaturePoints = !showFeaturePoints;
      showPlanes = !showPlanes;
      showWorldOrigin = !showWorldOrigin;
    });

    arSessionManager?.onInitialize(
      showFeaturePoints: showFeaturePoints,
      showPlanes: showPlanes,
      customPlaneTexturePath: "assets/triangle.png",
      showWorldOrigin: showWorldOrigin,
      handleTaps: true,
    );
  }
}
