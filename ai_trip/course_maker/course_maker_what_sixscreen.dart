import 'package:ai_trip/course_maker/course_maker_where_sevscreen.dart';
import 'package:flutter/material.dart';

class TravelWhatScreen extends StatefulWidget {
  final Map<String, dynamic> userConditions;

  const TravelWhatScreen({super.key, required this.userConditions});

  @override
  _TravelWhatScreenState createState() => _TravelWhatScreenState();
}
class _TravelWhatScreenState extends State<TravelWhatScreen> {
  List<String> selectedActivities = [];

  final List<Map<String, dynamic>> activityOptions = [
    {'label': '레저 스포츠 🏍️'},
    {'label': '문화시설 🎬'},
    {'label': '사진 명소 📷'},
    {'label': '이색체험 🏄'},
    {'label': '유적지 🧵'},
    {'label': '박물관 🏛️'},
    {'label': '공원 🌳'},
    {'label': '사찰 🛕'},
    {'label': '성지 ⛪'},
  ];

  void toggleActivity(String activity) {
    setState(() {
      if (selectedActivities.contains(activity)) {
        selectedActivities.remove(activity);
      } else {
        selectedActivities.add(activity);
      }
    });
  }

  Widget _buildActivityButton(String label) {
    final isSelected = selectedActivities.contains(label);

    return GestureDetector(
      onTap: () => toggleActivity(label),
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
            // 🔒 고정된 LinearProgressIndicator
            LinearProgressIndicator(
              value: 0.75,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),

            // ✅ 고정된 안내 텍스트 영역
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
                    '무엇을 하고 싶으신가요?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('* 중복 선택 가능', style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 16),
                ],
              ),
            ),

            // ⬇️ 스크롤 가능한 버튼 리스트
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...activityOptions.map((activity) =>
                        _buildActivityButton(activity['label'])),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TravelWhereScreen(
                           userConditions: {
                            ...widget.userConditions,
                            "activities": selectedActivities.map((e) => e.split(" ")[0]).toList(),
                           }
                        )),
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