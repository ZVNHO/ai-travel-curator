import 'package:flutter/material.dart';
import 'package:ai_trip/travel_results_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';

class TravelMapScreen extends StatefulWidget {
  final Map<String, dynamic> userConditions;

  const TravelMapScreen({super.key, required this.userConditions});

  @override
  _TravelMapScreenState createState() => _TravelMapScreenState();
}

class _TravelMapScreenState extends State<TravelMapScreen> {
  final MapController _mapController = MapController();
  LatLng currentCenter = LatLng(36.3504, 127.3845); // 대전 중심
  double currentZoom = 13;
  static const double visualCircleSizePx = 160;

  double metersPerPixel(double zoom, double latitude) {
    return 156543.03392 * cos(latitude * pi / 180) / pow(2, zoom);
  }

  double getActualRadiusKm({
    required double zoom,
    required double latitude,
    required double circleVisualDiameterPx,
  }) {
    final meterPerPixel = metersPerPixel(zoom, latitude);
    final radiusInMeters = (circleVisualDiameterPx / 2) * meterPerPixel;
    return radiusInMeters / 1000;
  }

  Widget _buildBottomButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.green,
        padding: EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double actualRadiusKm = getActualRadiusKm(
      zoom: currentZoom,
      latitude: currentCenter.latitude,
      circleVisualDiameterPx: visualCircleSizePx,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('여행 코스 추천'),
        leading: BackButton(),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: 1,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('3. 여행 범위를 알아볼게요.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  SizedBox(height: 8),
                  Text('얼만큼 여행하고 싶으신가요?',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('지도를 직접 움직여 범위를 설정해 주세요.',
                      style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: currentCenter,
                      initialZoom: currentZoom,
                      onPositionChanged: (position, hasGesture) {
                        setState(() {
                          currentCenter = position.center!;
                          currentZoom = position.zoom!;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.travelapp',
                      ),
                    ],
                  ),
                  // 고정된 크기의 파란 원
                  Container(
                    width: visualCircleSizePx,
                    height: visualCircleSizePx,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildBottomButton('이전', () {
                  Navigator.pop(context);
                }),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildBottomButton('다음', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TravelResultsScreen(
                        userConditions: {
                          ...widget.userConditions,
                          "location": {
                            "lat": currentCenter.latitude,
                            "lng": currentCenter.longitude,
                            "radius_km": actualRadiusKm,
                          }
                        },
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
