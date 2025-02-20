import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // 路线数据
  final List<LatLng> routeCoordinates = [
    LatLng(53.344075, -6.257303),
    LatLng(53.34404, -6.25638),
    LatLng(53.34402, -6.2561),
    LatLng(53.34468, -6.25603),
    LatLng(53.34463, -6.25581),
    LatLng(53.34457, -6.25455),
    LatLng(53.34466, -6.25452),
    LatLng(53.34463, -6.25434),
    LatLng(53.34456, -6.25418),
    LatLng(53.34415, -6.25237),
    LatLng(53.34352, -6.25252),
    LatLng(53.34316, -6.25263),
    LatLng(53.34265, -6.25275),
    LatLng(53.34262, -6.2525),
    LatLng(53.34248, -6.25138),
    LatLng(53.34235, -6.2515),
    LatLng(53.34227, -6.25155),
    LatLng(53.34214, -6.2516),
    LatLng(53.34214, -6.25142),
    LatLng(53.34213, -6.25131),
    LatLng(53.34208, -6.2511),
    LatLng(53.34204, -6.25097),
    LatLng(53.342, -6.25077),
    LatLng(53.34196, -6.25061),
    LatLng(53.34192, -6.25046),
    LatLng(53.34188, -6.25036),
    LatLng(53.34179, -6.25032),
    LatLng(53.34171, -6.25032),
    LatLng(53.34159, -6.2504),
    LatLng(53.34135, -6.25056),
    LatLng(53.34116, -6.2507),
    LatLng(53.34107, -6.25079),
    LatLng(53.34086, -6.25102),
    LatLng(53.3407, -6.25118),
    LatLng(53.34045, -6.25141),
    LatLng(53.3401, -6.25175),
    LatLng(53.33978, -6.25204),
    LatLng(53.33958, -6.25223),
    LatLng(53.33945, -6.25235),
    LatLng(53.3393, -6.25249),
    LatLng(53.33927, -6.25252),
    LatLng(53.33892, -6.25285),
    LatLng(53.33848, -6.25325),
    LatLng(53.33812, -6.25358),
    LatLng(53.33798, -6.25294),
    LatLng(53.33797, -6.2529),
    LatLng(53.33792, -6.2527),
    LatLng(53.33788, -6.25251),
    LatLng(53.33787, -6.25247),
    LatLng(53.33778, -6.25205),
    LatLng(53.33774, -6.25182),
    LatLng(53.33769, -6.25162),
    LatLng(53.3376, -6.25154),
    LatLng(53.33755, -6.25152),
    LatLng(53.3375, -6.25151),
    LatLng(53.3368, -6.25214),
    LatLng(53.33674, -6.25219),
    LatLng(53.33666, -6.25227),
    LatLng(53.33645, -6.25246),
    LatLng(53.33617, -6.25271),
    LatLng(53.33602, -6.25286),
    LatLng(53.3355, -6.25334),
    LatLng(53.33535, -6.25348),
    LatLng(53.33521, -6.2536),
    LatLng(53.33513, -6.25368),
    LatLng(53.33505, -6.25377),
    LatLng(53.33498, -6.25386),
    LatLng(53.33492, -6.25396),
    LatLng(53.33488, -6.25404),
    LatLng(53.33467, -6.25454),
    LatLng(53.33466, -6.25457),
    LatLng(53.33457, -6.25481),
    LatLng(53.3344, -6.25524),
    LatLng(53.3345, -6.25537),
    LatLng(53.3347, -6.2556),
    LatLng(53.33475, -6.25565),
    LatLng(53.33488, -6.25579),
    LatLng(53.33494, -6.25585),
    LatLng(53.33511, -6.25602),
    LatLng(53.33516, -6.25607),
    LatLng(53.33519, -6.2561),
    LatLng(53.33553, -6.25643),
    LatLng(53.33563, -6.25653),
    LatLng(53.33573, -6.25664),
    LatLng(53.33582, -6.25674),
    LatLng(53.33592, -6.25686),
    LatLng(53.33598, -6.25694),
    LatLng(53.33603, -6.25701),
    LatLng(53.33607, -6.25708),
    LatLng(53.33611, -6.25716),
    LatLng(53.33615, -6.25725),
    LatLng(53.33619, -6.25736),
    LatLng(53.33623, -6.25748),
    LatLng(53.33627, -6.25762),
    LatLng(53.33631, -6.25777),
    LatLng(53.33635, -6.25793),
    LatLng(53.33639, -6.25809),
    LatLng(53.33647, -6.2584),
    LatLng(53.33673, -6.25937),
    LatLng(53.3368, -6.25962),
    LatLng(53.33686, -6.25985),
    LatLng(53.33688, -6.26),
    LatLng(53.33691, -6.26016),
    LatLng(53.33696, -6.26034),
    LatLng(53.33707, -6.26075),
    LatLng(53.33728, -6.26148),
    LatLng(53.33739, -6.26192),
    LatLng(53.33744, -6.26213),
    LatLng(53.33747, -6.26227),
    LatLng(53.33751, -6.26246),
    LatLng(53.33754, -6.26265),
    LatLng(53.33756, -6.26279),
    LatLng(53.33757, -6.26298),
    LatLng(53.33757, -6.26319),
    LatLng(53.33757, -6.26371),
    LatLng(53.33756, -6.2646),
    LatLng(53.33756, -6.26477),
    LatLng(53.33757, -6.26523),
    LatLng(53.33757, -6.26534),
    LatLng(53.33758, -6.26583),
    LatLng(53.33764, -6.26585),
    LatLng(53.33782, -6.2659),
    LatLng(53.33798, -6.26594),
    LatLng(53.33815, -6.266),
    LatLng(53.33838, -6.26609),
    LatLng(53.33846, -6.26611),
    LatLng(53.33853, -6.26611),
    LatLng(53.33869, -6.26607),
    LatLng(53.33919, -6.26596),
    LatLng(53.3396, -6.26588),
    LatLng(53.33979, -6.26584),
    LatLng(53.34008, -6.26578),
    LatLng(53.34047, -6.26569),
    LatLng(53.3407, -6.26563),
    LatLng(53.34073, -6.26608),
    LatLng(53.34075, -6.26642),
    LatLng(53.34078, -6.26701),
    LatLng(53.34088, -6.26717),
    LatLng(53.34094, -6.26718),
    LatLng(53.34107, -6.26696),
    LatLng(53.34118, -6.2671),
    LatLng(53.34189, -6.26802),
    LatLng(53.3422, -6.26836),
    LatLng(53.34235, -6.26847),
    LatLng(53.34243, -6.26852),
    LatLng(53.34251, -6.26818),
    LatLng(53.34277, -6.26704),
  ];

  // 禁止进入区域（bbox）
  final List<LatLng> restrictedArea = [
    LatLng(53.3460, -6.2700), // 左上角
    LatLng(53.3460, -6.2500), // 右上角
    LatLng(53.3420, -6.2500), // 右下角
    LatLng(53.3420, -6.2700), // 左下角
    LatLng(53.3460, -6.2700), // 回到起点
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Route and Restricted Area'),
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(53.344075, -6.257303), // 设置地图中心
          zoom: 14.0, // 缩放级别
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          // 绘制禁止进入区域
          PolygonLayer(
            polygons: [
            Polygon(
              points: restrictedArea,
              color: Colors.red.withOpacity(0.5),
              borderColor: Colors.red, // 边界颜色
              borderStrokeWidth: 10.0, // 边界宽度
            ),

            ],
          ),
          // 绘制路线
          PolylineLayer(
            polylines: [
              Polyline(
                points: routeCoordinates,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

