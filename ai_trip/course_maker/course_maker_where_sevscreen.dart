import 'package:flutter/material.dart';
import 'package:ai_trip/course_maker/course_maker_map_eightscreen.dart';

class TravelWhereScreen extends StatefulWidget {
  final Map<String, dynamic> userConditions;

  const TravelWhereScreen({super.key, required this.userConditions});

  @override
  _TravelWhereScreenState createState() => _TravelWhereScreenState();
}
class _TravelWhereScreenState extends State<TravelWhereScreen> {
  List<String> selectedPlaces = [];

  final List<Map<String, dynamic>> placeOptions = [
    {'label': '바다 🌊'},
    {'label': '산 🏔️'},
    {'label': '드라이브 🚗'},
    {'label': '산책 🚶'},
    {'label': '쇼핑 🛍️'},
    {'label': '실내여행지 🏛️'},
    {'label': '시티투어 🏙️'},
    {'label': '전통 🏯'},
  ];

  void togglePlace(String place) {
    setState(() {
      if (selectedPlaces.contains(place)) {
        selectedPlaces.remove(place);
      } else {
        selectedPlaces.add(place);
      }
    });
  }

  Widget _buildPlaceButton(String label) {
    final isSelected = selectedPlaces.contains(label);

    return GestureDetector(
      onTap: () => togglePlace(label),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontSize: 17),
          ),
        ),
      ),
    );
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
            // 🔒 고정된 상단 프로그레스 바
            LinearProgressIndicator(
              value: 0.875,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),

            // ✅ 고정된 텍스트 안내 부분
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2. 여행 스타일을 알아볼게요.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '어디를 가고 싶으신가요?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('* 중복 선택 가능',
                      style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 16),
                ],
              ),
            ),

            // ⬇️ 스크롤 가능한 선택 버튼 영역
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...placeOptions.map((place) => _buildPlaceButton(place['label'])),
                    SizedBox(height: 24),
                  ],
                ),
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
                  // 다음 페이지로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TravelMapScreen(
                         userConditions: {
                           ...widget.userConditions,
                            "places": selectedPlaces.map((e) => e.split(" ")[0]).toList(),
                         }
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